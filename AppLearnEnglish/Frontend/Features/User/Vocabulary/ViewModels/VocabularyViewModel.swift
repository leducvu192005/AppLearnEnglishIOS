//
//  VocabularyViewModel.swift
//  AppLearnEnglish
//

import Foundation
import SwiftUI
import Combine

class VocabularyViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var words: [VocabularyWord] = []
    @Published var learnedWordIds: Set<String> = []
    @Published var favoriteWordIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Search and Filter parameters
    @Published var searchText: String = ""
    @Published var selectedFilter: String = "Tất cả"
    
    // Custom vocabularies keys and collections
    @Published var customTopics: [Topic] = []
    @Published var customWords: [VocabularyWord] = []
    
    // Custom user collections
    @Published var userCollections: [UserCollection] = []
    @Published var allWords: [VocabularyWord] = []
    
    private let customTopicsKey = "AppLearnEnglish_CustomTopics"
    private let customWordsKey = "AppLearnEnglish_CustomWords"
    private let userCollectionsKey = "AppLearnEnglish_UserCollections"
    
    private let vocabularyService = VocabularyService.shared
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Initializer
    init() {
        loadCustomTopics()
        loadCustomWords()
        loadUserCollections()
        Task {
            await loadTopics()
            await loadUserPreferences()
        }
    }
    
    // MARK: - Combined collections
    var allTopics: [Topic] {
        return topics + customTopics
    }
    
    /// Computes filtered topics based on search text and selected filters
    var filteredTopics: [Topic] {
        let list = allTopics
        
        // Filter by Search Query
        let searchedList = list.filter { topic in
            if searchText.isEmpty { return true }
            return topic.name.localizedCaseInsensitiveContains(searchText) ||
                   topic.description.localizedCaseInsensitiveContains(searchText)
        }
        
        // Filter by Subject Category Tab
        switch selectedFilter {
        case "Đời sống":
            return searchedList.filter { $0.id == "dailylife" }
        case "Du lịch":
            return searchedList.filter { $0.id == "travel" }
        case "Công sở":
            return searchedList.filter { $0.id == "business" }
        case "Công nghệ":
            return searchedList.filter { $0.id == "tech" }
        case "Cá nhân":
            return searchedList.filter { $0.id.hasPrefix("custom_") }
        default:
            return searchedList
        }
    }
    
    /// Helper to count words dynamically
    private func wordsCountForTopic(topicId: String, learnedOnly: Bool) -> Int {
        // Since we may not have loaded all words for all topics in self.words yet, 
        // we can count from local caches or fallback.
        // For custom topics, we can count exactly:
        let customCountWords = customWords.filter { $0.topicId == topicId }
        if topicId.hasPrefix("custom_") {
            if learnedOnly {
                return customCountWords.filter { learnedWordIds.contains($0.id) }.count
            }
            return customCountWords.count
        }
        
        // For server topics, we count from loaded words if they belong to this topic, 
        // otherwise we fallback to the totalWords attribute.
        let serverTopicWords = words.filter { $0.topicId == topicId }
        if !serverTopicWords.isEmpty {
            if learnedOnly {
                return serverTopicWords.filter { learnedWordIds.contains($0.id) }.count
            }
            return serverTopicWords.count
        }
        
        // Fallback if not loaded
        if learnedOnly { return 0 }
        if let topic = topics.first(where: { $0.id == topicId }) {
            return topic.totalWords
        }
        return 0
    }
    
    // MARK: - Load list of Topics
    @MainActor
    func loadTopics() async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            self.topics = try await vocabularyService.fetchTopics()
            self.isLoading = false
            
            // Schedule passive learning notifications
            if let allWords = try? await vocabularyService.fetchAllVocabulary() {
                self.allWords = allWords
                NotificationManager.shared.schedulePassiveLearningNotifications(words: allWords)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // MARK: - Load Words for selected Topic
    @MainActor
    func loadWords(for topicId: String) async {
        self.isLoading = true
        self.errorMessage = nil
        
        // 1. Load from custom words if it is a custom topic
        let localCustomWords = customWords.filter { $0.topicId == topicId }
        
        if topicId.hasPrefix("custom_") {
            self.words = localCustomWords
            self.isLoading = false
            return
        }
        
        // 2. Load from server database (with mock fallback)
        do {
            let serverWords = try await vocabularyService.fetchWords(for: topicId)
            self.words = serverWords + localCustomWords
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // MARK: - Load User learned and favorite word IDs
    @MainActor
    func loadUserPreferences() async {
        guard let uid = userId else { return }
        do {
            async let learned = vocabularyService.fetchLearnedWordIds(userId: uid)
            async let favorites = vocabularyService.fetchFavoriteWordIds(userId: uid)
            
            let (learnedIds, favoriteIds) = try await (learned, favorites)
            
            self.learnedWordIds = learnedIds
            self.favoriteWordIds = favoriteIds
        } catch {
            print("Error loading user preferences: \(error)")
        }
    }
    
    // MARK: - Toggle Favorite
    @MainActor
    func toggleFavorite(wordId: String) async {
        guard let uid = userId else { return }
        let isFavorite = favoriteWordIds.contains(wordId)
        
        // Optimistic UI update
        if isFavorite {
            favoriteWordIds.remove(wordId)
        } else {
            favoriteWordIds.insert(wordId)
        }
        
        do {
            try await vocabularyService.toggleFavoriteWord(userId: uid, wordId: wordId, isFavorite: !isFavorite)
        } catch {
            // Revert on error
            if isFavorite {
                favoriteWordIds.insert(wordId)
            } else {
                favoriteWordIds.remove(wordId)
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mark word as Learned
    @MainActor
    func markAsLearned(wordId: String) async {
        guard let uid = userId else { return }
        if learnedWordIds.contains(wordId) { return } // Already learned
        
        // Optimistic UI update
        learnedWordIds.insert(wordId)
        
        do {
            try await vocabularyService.markWordAsLearned(userId: uid, wordId: wordId)
            // Reload user progress stats in the session
            await SessionManager.shared.reloadUserProfile()
        } catch {
            // Revert on error
            learnedWordIds.remove(wordId)
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Save Oxford Word from notification tap
    func addWordFromNotification(word: [String: String]) {
        let id = word["id"] ?? UUID().uuidString
        let text = word["word"] ?? ""
        let phonetic = word["phonetic"] ?? ""
        let meaning = word["meaning"] ?? ""
        let example = word["example"] ?? ""
        let level = word["level"] ?? "Beginner"
        
        let topicId = "custom_oxford_3000"
        
        // Find or create "Oxford 3000" custom topic
        if !customTopics.contains(where: { $0.id == topicId }) {
            let oxfordTopic = Topic(
                id: topicId,
                name: "Oxford 3000 🎧",
                description: "Các từ vựng đã tích lũy từ thông báo thụ động",
                image: "headphones.circle.fill",
                totalWords: 0
            )
            customTopics.append(oxfordTopic)
            saveCustomTopics()
        }
        
        // Check if word is already added
        if customWords.contains(where: { $0.word.lowercased() == text.lowercased() }) {
            return
        }
        
        let newWord = VocabularyWord(
            id: id,
            word: text,
            phonetic: phonetic,
            meaning: meaning,
            example: example,
            image: "",
            audio: "",
            topicId: topicId,
            level: level
        )
        
        customWords.append(newWord)
        saveCustomWords()
        
        // Increment the totalWords count inside the "Oxford 3000 🎧" topic
        if let idx = customTopics.firstIndex(where: { $0.id == topicId }) {
            let topic = customTopics[idx]
            customTopics[idx] = Topic(
                id: topic.id,
                name: topic.name,
                description: topic.description,
                image: topic.image,
                totalWords: topic.totalWords + 1
            )
            saveCustomTopics()
        }
    }
    
    // MARK: - Persistent Custom Vocabulary Set handlers
    
    func loadCustomTopics() {
        if let data = UserDefaults.standard.data(forKey: customTopicsKey),
           let decoded = try? JSONDecoder().decode([Topic].self, from: data) {
            self.customTopics = decoded
        }
    }
    
    func loadCustomWords() {
        if let data = UserDefaults.standard.data(forKey: customWordsKey),
           let decoded = try? JSONDecoder().decode([VocabularyWord].self, from: data) {
            self.customWords = decoded
        }
    }
    
    func addCustomTopic(name: String, description: String, icon: String = "book.closed.circle.fill") {
        let newTopic = Topic(
            id: "custom_\(UUID().uuidString)",
            name: name,
            description: description,
            image: icon,
            totalWords: 0
        )
        customTopics.append(newTopic)
        saveCustomTopics()
    }
    
    func addCustomWord(word: String, phonetic: String, meaning: String, example: String, topicId: String) {
        let newWord = VocabularyWord(
            id: "custom_word_\(UUID().uuidString)",
            word: word,
            phonetic: phonetic,
            meaning: meaning,
            example: example,
            image: "",
            audio: "",
            topicId: topicId,
            level: "Custom"
        )
        customWords.append(newWord)
        saveCustomWords()
        
        // Increment the totalWords count inside the custom topic
        if let idx = customTopics.firstIndex(where: { $0.id == topicId }) {
            let topic = customTopics[idx]
            customTopics[idx] = Topic(
                id: topic.id,
                name: topic.name,
                description: topic.description,
                image: topic.image,
                totalWords: topic.totalWords + 1
            )
            saveCustomTopics()
        }
    }
    
    private func saveCustomTopics() {
        if let encoded = try? JSONEncoder().encode(customTopics) {
            UserDefaults.standard.set(encoded, forKey: customTopicsKey)
        }
    }
    
    private func saveCustomWords() {
        if let encoded = try? JSONEncoder().encode(customWords) {
            UserDefaults.standard.set(encoded, forKey: customWordsKey)
        }
    }
    
    // MARK: - User Custom Collections management
    func loadUserCollections() {
        if let data = UserDefaults.standard.data(forKey: userCollectionsKey),
           let decoded = try? JSONDecoder().decode([UserCollection].self, from: data) {
            self.userCollections = decoded
        } else {
            // Seed defaults
            self.userCollections = [
                UserCollection(id: "fav_words", name: "Bộ từ yêu thích ❤️", description: "Những từ vựng bạn yêu thích học tập", wordIds: [], icon: "heart.circle.fill"),
                UserCollection(id: "travel_words", name: "Từ vựng Du lịch ✈️", description: "Học phục vụ các chuyến đi chơi", wordIds: [], icon: "airplane.circle.fill")
            ]
            saveUserCollections()
        }
    }
    
    func saveUserCollections() {
        if let encoded = try? JSONEncoder().encode(userCollections) {
            UserDefaults.standard.set(encoded, forKey: userCollectionsKey)
        }
    }
    
    func createUserCollection(name: String, description: String, icon: String = "book.closed.circle.fill") {
        let newCol = UserCollection(
            id: "usercol_\(UUID().uuidString)",
            name: name,
            description: description,
            wordIds: [],
            icon: icon
        )
        userCollections.append(newCol)
        saveUserCollections()
    }
    
    func addWordToCollections(wordId: String, collectionIds: [String]) {
        for idx in 0..<userCollections.count {
            let col = userCollections[idx]
            if collectionIds.contains(col.id) {
                if !col.wordIds.contains(wordId) {
                    userCollections[idx].wordIds.append(wordId)
                }
            } else {
                userCollections[idx].wordIds.removeAll(where: { $0 == wordId })
            }
        }
        saveUserCollections()
    }
    
    func getCollectionsContainingWord(wordId: String) -> [String] {
        return userCollections.filter { $0.wordIds.contains(wordId) }.map { $0.id }
    }
    
    func getWordsInCollection(collectionId: String) -> [VocabularyWord] {
        guard let collection = userCollections.first(where: { $0.id == collectionId }) else { return [] }
        return allWords.filter { collection.wordIds.contains($0.id) }
    }
    
    func addCustomWordToCollection(word: String, phonetic: String, meaning: String, example: String, collectionId: String) {
        let newWordId = "custom_word_\(UUID().uuidString)"
        let newWord = VocabularyWord(
            id: newWordId,
            word: word,
            phonetic: phonetic,
            meaning: meaning,
            example: example,
            image: "",
            audio: "",
            topicId: "custom_collection_\(collectionId)",
            level: "Custom"
        )
        customWords.append(newWord)
        allWords.append(newWord)
        saveCustomWords()
        
        if let idx = userCollections.firstIndex(where: { $0.id == collectionId }) {
            userCollections[idx].wordIds.append(newWordId)
            saveUserCollections()
        }
    }
    
    func addExistingWordsToCollection(wordIds: [String], collectionId: String) {
        if let idx = userCollections.firstIndex(where: { $0.id == collectionId }) {
            for wId in wordIds {
                if !userCollections[idx].wordIds.contains(wId) {
                    userCollections[idx].wordIds.append(wId)
                }
            }
            saveUserCollections()
        }
    }
}
