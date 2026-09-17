//
//  AdminViewModel.swift
//  AppLearnEnglish
//

import Foundation
import SwiftUI
import Combine

enum ImportStatus: String, Codable {
    case valid = "Valid"
    case duplicate = "Duplicate"
    case invalid = "Invalid"
}

struct ImportRecord: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let phonetic: String
    let meaning: String
    let example: String
    let image: String
    let audio: String
    let topicId: String
    let level: String
    let status: ImportStatus
    let statusReason: String
}

struct ParsedTopicSet: Identifiable, Hashable {
    let id: String // topicId slug
    var name: String
    var description: String
    var image: String
    var isNewTopic: Bool
    var words: [ImportRecord]
}

@MainActor
class AdminViewModel: ObservableObject {
    private let repository: AdminRepositoryProtocol
    
    @Published var users: [UserModel] = []
    @Published var topics: [Topic] = []
    @Published var words: [VocabularyWord] = []
    @Published var quizTopics: [Topic] = []
    @Published var quizzes: [Quiz] = []
    @Published var listeningTopics: [Topic] = []
    @Published var listeningExercises: [ListeningExercise] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Search, Filter & Sort States
    @Published var topicSearchText = ""
    @Published var selectedTopicSort = "A-Z" // "A-Z", "Z-A", "Most Words", "Least Words"
    
    @Published var wordSearchText = ""
    @Published var selectedLevelFilter = "All" // "All", "Beginner", "Intermediate", "Advanced"
    @Published var selectedWordSort = "A-Z" // "A-Z", "Z-A", "Newest", "Oldest"
    
    // Quizzes filter states
    @Published var quizSearchText = ""
    @Published var selectedQuizTopicFilter = "All"
    
    // Listening filter states
    @Published var listeningSearchText = ""
    @Published var selectedListeningTopicFilter = "All"
    @Published var selectedListeningLevelFilter = "All"
    
    // Users filter states
    @Published var userSearchText = ""
    @Published var selectedUserRoleFilter = "All" // "All", "user", "admin"
    @Published var selectedUserStatusFilter = "All" // "All", "Active", "Suspended"
    @Published var selectedUserSort = "Name A-Z" // "Name A-Z", "Name Z-A", "Most XP", "Least XP", "Newest"
    
    // Import wizard states
    @Published var parsedTopicSets: [ParsedTopicSet] = []
    @Published var parsedImportRecords: [ImportRecord] = []
    @Published var importStats = (validCount: 0, duplicateCount: 0, invalidCount: 0)
    
    init(repository: AdminRepositoryProtocol? = nil) {
        self.repository = repository ?? AdminRepository()
    }
    
    // MARK: - Computed Properties for Filters & Searching
    
    var filteredTopics: [Topic] {
        var result = topics
        
        let searchTrimmed = topicSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchTrimmed.isEmpty {
            let searchLower = searchTrimmed.lowercased()
            result = result.filter { $0.name.lowercased().contains(searchLower) }
        }
        
        result.sort { (t1, t2) -> Bool in
            switch selectedTopicSort {
            case "Z-A":
                return t1.name > t2.name
            case "Most Words":
                return t1.totalWords > t2.totalWords
            case "Least Words":
                return t1.totalWords < t2.totalWords
            default: // "A-Z"
                return t1.name < t2.name
            }
        }
        
        return result
    }
    
    func filteredWords(for topicId: String) -> [VocabularyWord] {
        var result = words.filter { $0.topicId == topicId }
        
        let searchTrimmed = wordSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchTrimmed.isEmpty {
            let searchLower = searchTrimmed.lowercased()
            result = result.filter {
                $0.word.lowercased().contains(searchLower) ||
                $0.meaning.lowercased().contains(searchLower)
            }
        }
        
        if selectedLevelFilter != "All" {
            result = result.filter { $0.level.lowercased() == selectedLevelFilter.lowercased() }
        }
        
        result.sort { (w1, w2) -> Bool in
            switch selectedWordSort {
            case "Z-A":
                return w1.word > w2.word
            case "Newest":
                return w1.id > w2.id
            case "Oldest":
                return w1.id < w2.id
            default: // "A-Z"
                return w1.word < w2.word
            }
        }
        
        return result
    }
    
    var filteredQuizzes: [Quiz] {
        var result = quizzes
        let searchTrimmed = quizSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchTrimmed.isEmpty {
            let searchLower = searchTrimmed.lowercased()
            result = result.filter {
                $0.question.lowercased().contains(searchLower) ||
                $0.correctAnswer.lowercased().contains(searchLower)
            }
        }
        if selectedQuizTopicFilter != "All" {
            result = result.filter { $0.topicId == selectedQuizTopicFilter }
        }
        return result
    }
    
    var filteredListeningExercises: [ListeningExercise] {
        var result = listeningExercises
        let searchTrimmed = listeningSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchTrimmed.isEmpty {
            let searchLower = searchTrimmed.lowercased()
            result = result.filter {
                $0.sentence.lowercased().contains(searchLower) ||
                $0.translation.lowercased().contains(searchLower)
            }
        }
        if selectedListeningTopicFilter != "All" {
            result = result.filter { $0.topicId == selectedListeningTopicFilter }
        }
        if selectedListeningLevelFilter != "All" {
            result = result.filter { $0.level.lowercased() == selectedListeningLevelFilter.lowercased() }
        }
        return result
    }
    
    var filteredUsers: [UserModel] {
        var result = users
        
        let searchTrimmed = userSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchTrimmed.isEmpty {
            let searchLower = searchTrimmed.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(searchLower) ||
                $0.email.lowercased().contains(searchLower) ||
                $0.uid.lowercased().contains(searchLower)
            }
        }
        
        if selectedUserRoleFilter != "All" {
            result = result.filter { $0.role.lowercased() == selectedUserRoleFilter.lowercased() }
        }
        
        if selectedUserStatusFilter != "All" {
            if selectedUserStatusFilter == "Active" {
                result = result.filter { $0.isAccountActive }
            } else if selectedUserStatusFilter == "Suspended" {
                result = result.filter { !$0.isAccountActive }
            }
        }
        
        result.sort { (u1, u2) -> Bool in
            switch selectedUserSort {
            case "Name Z–A", "Name Z-A":
                return u1.name.localizedCompare(u2.name) == .orderedDescending
            case "Highest XP", "Most XP":
                return u1.xp > u2.xp
            case "Lowest XP", "Least XP":
                return u1.xp < u2.xp
            case "Newest":
                return u1.createdAt > u2.createdAt
            case "Oldest":
                return u1.createdAt < u2.createdAt
            default: // "Name A–Z", "Name A-Z"
                return u1.name.localizedCompare(u2.name) == .orderedAscending
            }
        }
        
        return result
    }
    
    // MARK: - Load All Admin Data
    func loadAllData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        // 1. Load Vocabulary Topics (from /topics)
        do {
            self.topics = try await repository.getAllTopics()
        } catch {
            print("Admin: Failed to load vocabulary topics: \(error.localizedDescription)")
            self.errorMessage = "Không thể tải danh sách chủ đề từ vựng: \(error.localizedDescription)"
        }
        
        // 2. Load Words (from /vocabulary)
        do {
            self.words = try await repository.getAllVocabulary()
        } catch {
            print("Admin: Failed to load vocabulary: \(error.localizedDescription)")
        }
        
        // 3. Load Quiz Topics (from /quizzes)
        do {
            self.quizTopics = try await repository.getAllQuizTopics()
        } catch {
            print("Admin: Failed to load quiz topics: \(error.localizedDescription)")
        }
        
        // 4. Load Quizzes
        do {
            self.quizzes = try await repository.getAllQuizzes()
        } catch {
            print("Admin: Failed to load quizzes: \(error.localizedDescription)")
        }
        
        // 5. Load Listening Topics (from /listening_exercises)
        do {
            self.listeningTopics = try await repository.getAllListeningTopics()
        } catch {
            print("Admin: Failed to load listening topics: \(error.localizedDescription)")
        }
        
        // 6. Load Listening Exercises
        do {
            self.listeningExercises = try await repository.getAllListeningExercises()
        } catch {
            print("Admin: Failed to load listening exercises: \(error.localizedDescription)")
        }
        
        // 7. Load Users (Requires Admin permissions on collection users)
        do {
            self.users = try await repository.getAllUsers()
        } catch {
            print("Admin: Failed to load users list: \(error.localizedDescription)")
            // If this fails (e.g. Permission Denied), show a soft warning but let the admin view topics
            if self.errorMessage == nil {
                self.errorMessage = "Cảnh báo: Không có quyền truy cập danh sách học viên (Kiểm tra lại Security Rules của bảng users)."
            }
        }
        
        self.isLoading = false
    }
    
    // MARK: - User Operations
    func saveUser(user: UserModel) async {
        do {
            try await repository.saveUser(user: user)
            if let idx = users.firstIndex(where: { $0.uid == user.uid }) {
                users[idx] = user
            } else {
                users.append(user)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createUser(name: String, email: String, role: String, level: String, xp: Int, streak: Int, dailyGoal: Int, avatar: String?, isActive: Bool) async {
        let newUid = "user_\(UUID().uuidString.prefix(12).lowercased())"
        let newUser = UserModel(
            uid: newUid,
            name: name,
            email: email,
            role: role,
            streak: streak,
            level: level,
            xp: xp,
            dailyXP: 0,
            dailyGoal: dailyGoal,
            createdAt: Date(),
            avatar: avatar,
            isActive: isActive
        )
        
        do {
            try await repository.createUser(user: newUser)
            users.insert(newUser, at: 0)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteUser(uid: String) async {
        do {
            try await repository.deleteUser(uid: uid)
            users.removeAll(where: { $0.uid == uid })
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func toggleUserActiveStatus(user: UserModel) async {
        let currentStatus = user.isAccountActive
        let newStatus = !currentStatus
        do {
            try await repository.toggleUserActiveStatus(uid: user.uid, isActive: newStatus)
            if let idx = users.firstIndex(where: { $0.uid == user.uid }) {
                users[idx].isActive = newStatus
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateUserXPAndLevel(uid: String, xp: Int, level: String) async {
        do {
            try await repository.updateUserXPAndLevel(uid: uid, xp: xp, level: level)
            if let idx = users.firstIndex(where: { $0.uid == uid }) {
                users[idx].xp = xp
                users[idx].level = level
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Topic Operations
    func saveTopic(id: String?, name: String, description: String, image: String) async {
        let topicId = id ?? name.lowercased().replacingOccurrences(of: " ", with: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Count how many words are currently in this topic
        let wordCount = words.filter { $0.topicId == topicId }.count
        
        let newTopic = Topic(
            id: topicId,
            name: name,
            description: description,
            image: image.isEmpty ? "folder.fill" : image,
            totalWords: wordCount
        )
        
        do {
            try await repository.saveTopic(topic: newTopic)
            if let idx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[idx] = newTopic
            } else {
                topics.append(newTopic)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteTopic(topicId: String) async {
        // Safety check: Cannot delete a topic containing vocabulary words
        let wordCount = words.filter { $0.topicId == topicId }.count
        guard wordCount == 0 else {
            self.errorMessage = "Không thể xoá. Chủ đề này hiện đang có \(wordCount) từ vựng."
            return
        }
        
        do {
            try await repository.deleteTopic(topicId: topicId)
            topics.removeAll(where: { $0.id == topicId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Vocabulary Operations
    func saveWord(id: String?, word: String, phonetic: String, meaning: String, example: String, image: String, audio: String, topicId: String, level: String) async {
        let wordId = id ?? "word_\(UUID().uuidString.prefix(8).lowercased())"
        
        // Find existing word to check if topicId changed
        var previousTopicId: String? = nil
        if let existing = words.first(where: { $0.id == wordId }) {
            previousTopicId = existing.topicId
        }
        
        let newWord = VocabularyWord(
            id: wordId,
            word: word,
            phonetic: phonetic,
            meaning: meaning,
            example: example,
            image: image,
            audio: audio,
            topicId: topicId,
            level: level
        )
        
        do {
            try await repository.saveWord(word: newWord)
            
            // Sync local cache list
            if let idx = words.firstIndex(where: { $0.id == wordId }) {
                words[idx] = newWord
            } else {
                words.append(newWord)
            }
            
            // Re-sync new topic count locally
            if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[tIdx].totalWords = words.filter { $0.topicId == topicId }.count
            }
            
            // Re-sync old topic count locally if changed
            if let oldId = previousTopicId, oldId != topicId {
                if let tIdx = topics.firstIndex(where: { $0.id == oldId }) {
                    topics[tIdx].totalWords = words.filter { $0.topicId == oldId }.count
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func saveWordsBatch(words newWords: [VocabularyWord], topicId: String) async {
        isLoading = true
        do {
            try await repository.saveWordsBatch(words: newWords, topicId: topicId)
            let newIds = Set(newWords.map(\.id))
            words.removeAll { newIds.contains($0.id) }
            words.append(contentsOf: newWords)
            
            let count = words.filter { $0.topicId == topicId }.count
            if let idx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[idx].totalWords = count
            }
        } catch {
            self.errorMessage = "Error saving vocabulary words batch: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func deleteWord(wordId: String, topicId: String) async {
        do {
            try await repository.deleteWord(wordId: wordId, topicId: topicId)
            words.removeAll(where: { $0.id == wordId })
            
            // Re-sync topic counts locally
            if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[tIdx].totalWords = words.filter { $0.topicId == topicId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - CSV & JSON Parsing
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(row)
        var i = 0
        while i < chars.count {
            let char = chars[i]
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
            i += 1
        }
        result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    func createTopicSlug(from text: String) -> String {
        let latin = text.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
        let lower = latin.lowercased()
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_- "))
        let filtered = lower.unicodeScalars.filter { allowedChars.contains($0) }
        let cleaned = String(String.UnicodeScalarView(filtered))
        let slug = cleaned.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
        let finalSlug = slug.components(separatedBy: "_").filter { !$0.isEmpty }.joined(separator: "_")
        return finalSlug.isEmpty ? "topic_\(UUID().uuidString.prefix(6).lowercased())" : finalSlug
    }
    
    private func addWordToTopic(word: LooseWord, defaultTopicId: String, topicSetsDict: inout [String: ParsedTopicSet]) {
        let wordVal = word.word?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let meaningVal = word.meaning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phoneticVal = word.phonetic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let exampleVal = word.example?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let imageVal = word.image?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let audioVal = word.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let topicVal = word.topicId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? defaultTopicId
        let levelVal = word.level?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Beginner"
        
        let targetId = topicVal.isEmpty ? defaultTopicId : topicVal
        
        var status: ImportStatus = .valid
        var reason = "Hợp lệ"
        
        if wordVal.isEmpty || meaningVal.isEmpty {
            status = .invalid
            reason = "Thiếu từ hoặc nghĩa"
        } else if words.contains(where: { $0.word.lowercased() == wordVal.lowercased() && $0.topicId == targetId }) ||
                    (topicSetsDict[targetId]?.words.contains(where: { $0.word.lowercased() == wordVal.lowercased() }) == true) {
            status = .duplicate
            reason = "Từ vựng này đã tồn tại trong chủ đề"
        }
        
        let record = ImportRecord(
            word: wordVal,
            phonetic: phoneticVal,
            meaning: meaningVal,
            example: exampleVal,
            image: imageVal,
            audio: audioVal,
            topicId: targetId,
            level: levelVal,
            status: status,
            statusReason: reason
        )
        
        topicSetsDict[targetId]?.words.append(record)
    }
    
    struct LooseTopicMeta: Decodable {
        let id: String?
        let name: String?
        let description: String?
        let image: String?
        let coverImage: String?
        let topicId: String?
    }
    
    struct LooseDatasetItem: Decodable {
        let topic: LooseTopicMeta?
        let id: String?
        let name: String?
        let description: String?
        let image: String?
        let coverImage: String?
        let topicId: String?
        let words: [LooseWord]?
    }
    
    struct LooseWord: Decodable {
        let word: String?
        let phonetic: String?
        let meaning: String?
        let example: String?
        let image: String?
        let audio: String?
        let topicId: String?
        let level: String?
    }
    
    func parseImportData(text: String, isJSON: Bool, currentTopicId: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            self.parsedTopicSets = []
            self.parsedImportRecords = []
            self.importStats = (validCount: 0, duplicateCount: 0, invalidCount: 0)
            return
        }
        
        var topicSetsDict: [String: ParsedTopicSet] = [:]
        var topicSetsOrder: [String] = []
        
        func getOrCreateTopicSet(id: String, name: String, desc: String, image: String) -> String {
            let finalId = id.isEmpty ? createTopicSlug(from: name.isEmpty ? currentTopicId : name) : id
            if topicSetsDict[finalId] == nil {
                let existingTopic = topics.first(where: { $0.id == finalId })
                let finalName = name.isEmpty ? (existingTopic?.name ?? finalId.replacingOccurrences(of: "_", with: " ").capitalized) : name
                let finalDesc = desc.isEmpty ? (existingTopic?.description ?? "") : desc
                let finalImg = image.isEmpty ? (existingTopic?.image ?? "folder") : image
                let isNew = (existingTopic == nil)
                
                topicSetsDict[finalId] = ParsedTopicSet(
                    id: finalId,
                    name: finalName,
                    description: finalDesc,
                    image: finalImg,
                    isNewTopic: isNew,
                    words: []
                )
                topicSetsOrder.append(finalId)
            } else {
                if !name.isEmpty { topicSetsDict[finalId]?.name = name }
                if !desc.isEmpty { topicSetsDict[finalId]?.description = desc }
                if !image.isEmpty { topicSetsDict[finalId]?.image = image }
            }
            return finalId
        }
        
        if isJSON {
            guard let data = trimmedText.data(using: .utf8) else {
                self.errorMessage = "Dữ liệu JSON không hợp lệ."
                return
            }
            
            var parsedSuccessfully = false
            
            // 1. Try decoding array of datasets: [{ topic: {...}, words: [...] }] or [{ name: "...", words: [...] }]
            if let datasets = try? JSONDecoder().decode([LooseDatasetItem].self, from: data),
               datasets.contains(where: { $0.words != nil }) {
                parsedSuccessfully = true
                for item in datasets {
                    let tId = item.topic?.id ?? item.topic?.topicId ?? item.id ?? item.topicId ?? ""
                    let tName = item.topic?.name ?? item.name ?? ""
                    let tDesc = item.topic?.description ?? item.description ?? ""
                    let tImg = item.topic?.image ?? item.topic?.coverImage ?? item.image ?? item.coverImage ?? ""
                    
                    let targetTopicId = getOrCreateTopicSet(id: tId, name: tName, desc: tDesc, image: tImg)
                    
                    if let rawWords = item.words {
                        for w in rawWords {
                            addWordToTopic(word: w, defaultTopicId: targetTopicId, topicSetsDict: &topicSetsDict)
                        }
                    }
                }
            }
            // 2. Try decoding single dataset: { topic: {...}, words: [...] } or { name: "...", words: [...] }
            else if let singleDataset = try? JSONDecoder().decode(LooseDatasetItem.self, from: data),
                    singleDataset.words != nil {
                parsedSuccessfully = true
                let tId = singleDataset.topic?.id ?? singleDataset.topic?.topicId ?? singleDataset.id ?? singleDataset.topicId ?? ""
                let tName = singleDataset.topic?.name ?? singleDataset.name ?? ""
                let tDesc = singleDataset.topic?.description ?? singleDataset.description ?? ""
                let tImg = singleDataset.topic?.image ?? singleDataset.topic?.coverImage ?? singleDataset.image ?? singleDataset.coverImage ?? ""
                
                let targetTopicId = getOrCreateTopicSet(id: tId, name: tName, desc: tDesc, image: tImg)
                
                if let rawWords = singleDataset.words {
                    for w in rawWords {
                        addWordToTopic(word: w, defaultTopicId: targetTopicId, topicSetsDict: &topicSetsDict)
                    }
                }
            }
            // 3. Try decoding plain list of words: [{ word: "...", meaning: "..." }]
            else if let rawWords = try? JSONDecoder().decode([LooseWord].self, from: data) {
                parsedSuccessfully = true
                let targetTopicId = getOrCreateTopicSet(id: currentTopicId, name: "", desc: "", image: "")
                for w in rawWords {
                    let wordTopicId = w.topicId?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let effectiveTopicId = (wordTopicId?.isEmpty == false) ? wordTopicId! : targetTopicId
                    _ = getOrCreateTopicSet(id: effectiveTopicId, name: "", desc: "", image: "")
                    addWordToTopic(word: w, defaultTopicId: effectiveTopicId, topicSetsDict: &topicSetsDict)
                }
            }
            
            if !parsedSuccessfully {
                self.errorMessage = "Không thể đọc cấu trúc JSON. Vui lòng kiểm tra định dạng hoặc bấm Load Mẫu."
                return
            }
        } else {
            // Parse CSV lines
            let lines = trimmedText.components(separatedBy: .newlines)
            guard lines.count > 0 else { return }
            
            var startIndex = 0
            let firstLineFields = lines[0].lowercased()
            if firstLineFields.contains("word") || firstLineFields.contains("meaning") {
                startIndex = 1
            }
            
            let defaultSetId = getOrCreateTopicSet(id: currentTopicId, name: "", desc: "", image: "")
            
            for index in startIndex..<lines.count {
                let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty { continue }
                
                let fields = parseCSVRow(line)
                let wordVal = fields.indices.contains(0) ? fields[0] : ""
                let phoneticVal = fields.indices.contains(1) ? fields[1] : ""
                let meaningVal = fields.indices.contains(2) ? fields[2] : ""
                let exampleVal = fields.indices.contains(3) ? fields[3] : ""
                let imageVal = fields.indices.contains(4) ? fields[4] : ""
                let audioVal = fields.indices.contains(5) ? fields[5] : ""
                let topicVal = (fields.indices.contains(6) && !fields[6].isEmpty) ? fields[6] : defaultSetId
                let levelVal = (fields.indices.contains(7) && !fields[7].isEmpty) ? fields[7] : "Beginner"
                
                let targetSetId = getOrCreateTopicSet(id: topicVal, name: "", desc: "", image: "")
                
                var status: ImportStatus = .valid
                var reason = "Hợp lệ"
                
                if wordVal.isEmpty || meaningVal.isEmpty {
                    status = .invalid
                    reason = "Thiếu từ hoặc nghĩa"
                } else if words.contains(where: { $0.word.lowercased() == wordVal.lowercased() && $0.topicId == targetSetId }) ||
                            (topicSetsDict[targetSetId]?.words.contains(where: { $0.word.lowercased() == wordVal.lowercased() }) == true) {
                    status = .duplicate
                    reason = "Từ vựng này đã tồn tại trong chủ đề"
                }
                
                let record = ImportRecord(
                    word: wordVal,
                    phonetic: phoneticVal,
                    meaning: meaningVal,
                    example: exampleVal,
                    image: imageVal,
                    audio: audioVal,
                    topicId: targetSetId,
                    level: levelVal,
                    status: status,
                    statusReason: reason
                )
                topicSetsDict[targetSetId]?.words.append(record)
            }
        }
        
        // Assemble final ordered topic sets
        var finalSets: [ParsedTopicSet] = []
        var allRecords: [ImportRecord] = []
        
        for id in topicSetsOrder {
            if let set = topicSetsDict[id] {
                finalSets.append(set)
                allRecords.append(contentsOf: set.words)
            }
        }
        
        self.parsedTopicSets = finalSets
        self.parsedImportRecords = allRecords
        
        let valid = allRecords.filter { $0.status == .valid }.count
        let duplicate = allRecords.filter { $0.status == .duplicate }.count
        let invalid = allRecords.filter { $0.status == .invalid }.count
        self.importStats = (validCount: valid, duplicateCount: duplicate, invalidCount: invalid)
    }
    
    func commitImportedRecords() async {
        self.isLoading = true
        var affectedTopicIds: Set<String> = []
        
        for topicSet in parsedTopicSets {
            let topicId = topicSet.id
            
            // 1. Create or update Topic metadata
            let existingTopic = topics.first(where: { $0.id == topicId })
            let topicName = topicSet.name.isEmpty ? (existingTopic?.name ?? topicId.capitalized) : topicSet.name
            let topicDesc = topicSet.description.isEmpty ? (existingTopic?.description ?? "") : topicSet.description
            let topicImg = topicSet.image.isEmpty ? (existingTopic?.image ?? "folder") : topicSet.image
            
            let topicToSave = Topic(
                id: topicId,
                name: topicName,
                description: topicDesc,
                image: topicImg,
                totalWords: (existingTopic?.totalWords ?? 0)
            )
            
            do {
                try await repository.saveTopic(topic: topicToSave)
                if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                    topics[tIdx] = topicToSave
                } else {
                    topics.append(topicToSave)
                }
                affectedTopicIds.insert(topicId)
            } catch {
                print("Lỗi lưu topic \(topicId): \(error.localizedDescription)")
            }
            
            // 2. Save valid words in this topic
            let validWords = topicSet.words.filter { $0.status == .valid }
            for record in validWords {
                let wordId = "word_\(UUID().uuidString.prefix(8).lowercased())"
                let newWord = VocabularyWord(
                    id: wordId,
                    word: record.word,
                    phonetic: record.phonetic,
                    meaning: record.meaning,
                    example: record.example,
                    image: record.image,
                    audio: record.audio,
                    topicId: topicId,
                    level: record.level
                )
                
                do {
                    try await repository.saveWord(word: newWord)
                    words.append(newWord)
                    affectedTopicIds.insert(topicId)
                } catch {
                    print("Import failure for word \(record.word): \(error.localizedDescription)")
                }
            }
        }
        
        // 3. Update totalWords on topic models
        for topicId in affectedTopicIds {
            let count = words.filter { $0.topicId == topicId }.count
            if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[tIdx].totalWords = count
            }
        }
        
        // Reset states
        self.parsedTopicSets = []
        self.parsedImportRecords = []
        self.importStats = (validCount: 0, duplicateCount: 0, invalidCount: 0)
        self.isLoading = false
    }
    
    // MARK: - Quiz Operations
    func saveQuiz(id: String?, question: String, answers: [String], correctAnswer: String, topicId: String, type: String = "multiple_choice", level: String = "Beginner", audioUrl: String? = nil, imageUrl: String? = nil) async {
        let quizId = id ?? "quiz_\(UUID().uuidString.prefix(8).lowercased())"
        let newQuiz = Quiz(
            id: quizId,
            topicId: topicId,
            question: question,
            answers: answers,
            correctAnswer: correctAnswer,
            type: type,
            level: level,
            audioUrl: audioUrl,
            imageUrl: imageUrl
        )
        
        do {
            try await repository.saveQuiz(quiz: newQuiz)
            if let idx = quizzes.firstIndex(where: { $0.id == quizId }) {
                quizzes[idx] = newQuiz
            } else {
                quizzes.append(newQuiz)
            }
            
            // Re-sync quiz topic count locally
            if let tIdx = quizTopics.firstIndex(where: { $0.id == topicId }) {
                quizTopics[tIdx].totalWords = quizzes.filter { $0.topicId == topicId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func saveQuizzesBatch(quizzes newQuizzes: [Quiz], topicId: String) async {
        guard !newQuizzes.isEmpty else { return }
        self.isLoading = true
        do {
            try await repository.saveQuizzesBatch(quizzes: newQuizzes, topicId: topicId)
            for q in newQuizzes {
                if let idx = quizzes.firstIndex(where: { $0.id == q.id }) {
                    quizzes[idx] = q
                } else {
                    quizzes.append(q)
                }
            }
            
            // Re-sync quiz topic count locally
            if let tIdx = quizTopics.firstIndex(where: { $0.id == topicId }) {
                quizTopics[tIdx].totalWords = quizzes.filter { $0.topicId == topicId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func deleteQuiz(quizId: String, topicId: String? = nil) async {
        do {
            try await repository.deleteQuiz(quizId: quizId, topicId: topicId)
            let removedTopicId = topicId ?? quizzes.first(where: { $0.id == quizId })?.topicId
            quizzes.removeAll(where: { $0.id == quizId })
            
            if let tId = removedTopicId, let tIdx = quizTopics.firstIndex(where: { $0.id == tId }) {
                quizTopics[tIdx].totalWords = quizzes.filter { $0.topicId == tId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func saveQuizTopic(id: String?, name: String, description: String, image: String) async {
        let topicId = (id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ?
            id!.trimmingCharacters(in: .whitespacesAndNewlines) :
            name.lowercased().replacingOccurrences(of: " ", with: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        
        let questionCount = quizzes.filter { $0.topicId == topicId }.count
        let topic = Topic(
            id: topicId,
            name: name,
            description: description,
            image: image.isEmpty ? "questionmark.folder.fill" : image,
            totalWords: questionCount
        )
        
        do {
            try await repository.saveQuizTopic(topic: topic)
            if let idx = quizTopics.firstIndex(where: { $0.id == topicId }) {
                quizTopics[idx] = topic
            } else {
                quizTopics.append(topic)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteQuizTopic(topicId: String) async {
        self.isLoading = true
        do {
            try await repository.deleteQuizTopic(topicId: topicId)
            quizzes.removeAll(where: { $0.topicId == topicId })
            quizTopics.removeAll(where: { $0.id == topicId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    // MARK: - Listening Exercises Operations
    func saveListeningExercise(id: String?, sentence: String, translation: String, topicId: String, level: String = "Beginner", audioUrl: String? = nil, hint: String? = nil) async {
        let exerciseId = id ?? "listen_\(UUID().uuidString.prefix(8).lowercased())"
        let newExercise = ListeningExercise(
            id: exerciseId,
            sentence: sentence,
            translation: translation,
            topicId: topicId,
            level: level,
            audioUrl: audioUrl,
            hint: hint
        )
        
        do {
            try await repository.saveListeningExercise(exercise: newExercise)
            if let idx = listeningExercises.firstIndex(where: { $0.id == exerciseId }) {
                listeningExercises[idx] = newExercise
            } else {
                listeningExercises.append(newExercise)
            }
            
            // Re-sync listening topic count locally
            if let tIdx = listeningTopics.firstIndex(where: { $0.id == topicId }) {
                listeningTopics[tIdx].totalWords = listeningExercises.filter { $0.topicId == topicId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func saveListeningExercisesBatch(exercises newExercises: [ListeningExercise], topicId: String) async {
        guard !newExercises.isEmpty else { return }
        self.isLoading = true
        do {
            try await repository.saveListeningExercisesBatch(exercises: newExercises, topicId: topicId)
            for ex in newExercises {
                if let idx = listeningExercises.firstIndex(where: { $0.id == ex.id }) {
                    listeningExercises[idx] = ex
                } else {
                    listeningExercises.append(ex)
                }
            }
            
            // Re-sync listening topic count locally
            if let tIdx = listeningTopics.firstIndex(where: { $0.id == topicId }) {
                listeningTopics[tIdx].totalWords = listeningExercises.filter { $0.topicId == topicId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func deleteListeningExercise(exerciseId: String, topicId: String? = nil) async {
        do {
            try await repository.deleteListeningExercise(exerciseId: exerciseId, topicId: topicId)
            let removedTopicId = topicId ?? listeningExercises.first(where: { $0.id == exerciseId })?.topicId
            listeningExercises.removeAll(where: { $0.id == exerciseId })
            
            if let tId = removedTopicId, let tIdx = listeningTopics.firstIndex(where: { $0.id == tId }) {
                listeningTopics[tIdx].totalWords = listeningExercises.filter { $0.topicId == tId }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func saveListeningTopic(id: String?, name: String, description: String, image: String) async {
        let topicId = (id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ?
            id!.trimmingCharacters(in: .whitespacesAndNewlines) :
            name.lowercased().replacingOccurrences(of: " ", with: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        
        let sentenceCount = listeningExercises.filter { $0.topicId == topicId }.count
        let topic = Topic(
            id: topicId,
            name: name,
            description: description,
            image: image.isEmpty ? "headphones" : image,
            totalWords: sentenceCount
        )
        
        do {
            try await repository.saveListeningTopic(topic: topic)
            if let idx = listeningTopics.firstIndex(where: { $0.id == topicId }) {
                listeningTopics[idx] = topic
            } else {
                listeningTopics.append(topic)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteListeningTopic(topicId: String) async {
        self.isLoading = true
        do {
            try await repository.deleteListeningTopic(topicId: topicId)
            listeningExercises.removeAll(where: { $0.topicId == topicId })
            listeningTopics.removeAll(where: { $0.id == topicId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
