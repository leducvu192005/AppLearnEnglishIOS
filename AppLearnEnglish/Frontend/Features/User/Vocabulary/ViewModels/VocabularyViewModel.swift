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
    
    private let customTopicsKey = "AppLearnEnglish_CustomTopics"
    private let customWordsKey = "AppLearnEnglish_CustomWords"
    
    private let vocabularyService = VocabularyService.shared
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Initializer
    init() {
        loadCustomTopics()
        loadCustomWords()
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
            SessionManager.shared.listenToAuthChanges()
        } catch {
            // Revert on error
            learnedWordIds.remove(wordId)
            self.errorMessage = error.localizedDescription
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
}
