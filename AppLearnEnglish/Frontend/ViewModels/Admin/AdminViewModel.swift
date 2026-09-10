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

@MainActor
class AdminViewModel: ObservableObject {
    private let repository: AdminRepositoryProtocol
    
    @Published var users: [UserModel] = []
    @Published var topics: [Topic] = []
    @Published var words: [VocabularyWord] = []
    @Published var quizzes: [Quiz] = []
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
            case "Name Z-A":
                return u1.name.localizedCompare(u2.name) == .orderedDescending
            case "Most XP":
                return u1.xp > u2.xp
            case "Least XP":
                return u1.xp < u2.xp
            case "Newest":
                return u1.createdAt > u2.createdAt
            default: // "Name A-Z"
                return u1.name.localizedCompare(u2.name) == .orderedAscending
            }
        }
        
        return result
    }
    
    // MARK: - Load All Admin Data
    func loadAllData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        // 1. Load Topics (Critical)
        do {
            self.topics = try await FirestoreService.shared.fetchTopics()
        } catch {
            print("Admin: Failed to load topics: \(error.localizedDescription)")
            self.errorMessage = "Không thể tải danh sách chủ đề: \(error.localizedDescription)"
        }
        
        // 2. Load Words
        do {
            self.words = try await repository.getAllVocabulary()
        } catch {
            print("Admin: Failed to load vocabulary: \(error.localizedDescription)")
        }
        
        // 3. Load Quizzes
        do {
            self.quizzes = try await repository.getAllQuizzes()
        } catch {
            print("Admin: Failed to load quizzes: \(error.localizedDescription)")
        }
        
        // 4. Load Listening Exercises
        do {
            self.listeningExercises = try await repository.getAllListeningExercises()
        } catch {
            print("Admin: Failed to load listening exercises: \(error.localizedDescription)")
        }
        
        // 5. Load Users (Requires Admin permissions on collection users)
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
    
    func parseImportData(text: String, isJSON: Bool, currentTopicId: String) {
        var records: [ImportRecord] = []
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            self.parsedImportRecords = []
            self.importStats = (validCount: 0, duplicateCount: 0, invalidCount: 0)
            return
        }
        
        if isJSON {
            guard let data = trimmedText.data(using: .utf8) else {
                self.errorMessage = "Dữ liệu JSON không hợp lệ."
                return
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
            
            do {
                let decoded = try JSONDecoder().decode([LooseWord].self, from: data)
                for item in decoded {
                    let wordVal = item.word?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let meaningVal = item.meaning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let phoneticVal = item.phonetic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let exampleVal = item.example?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let imageVal = item.image?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let audioVal = item.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let topicVal = item.topicId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentTopicId
                    let levelVal = item.level?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Beginner"
                    
                    let status: ImportStatus
                    let reason: String
                    
                    if wordVal.isEmpty || meaningVal.isEmpty || topicVal.isEmpty {
                        status = .invalid
                        reason = "Thiếu trường bắt buộc (word, meaning hoặc topicId)"
                    } else if words.contains(where: { $0.word.lowercased() == wordVal.lowercased() && $0.topicId == topicVal }) {
                        status = .duplicate
                        reason = "Từ vựng này đã tồn tại trong chủ đề"
                    } else {
                        status = .valid
                        reason = "Hợp lệ"
                    }
                    
                    records.append(ImportRecord(
                        word: wordVal,
                        phonetic: phoneticVal,
                        meaning: meaningVal,
                        example: exampleVal,
                        image: imageVal,
                        audio: audioVal,
                        topicId: topicVal,
                        level: levelVal,
                        status: status,
                        statusReason: reason
                    ))
                }
            } catch {
                self.errorMessage = "Không thể parse cấu trúc JSON: \(error.localizedDescription)"
                return
            }
        } else {
            // Parse CSV lines
            let lines = trimmedText.components(separatedBy: .newlines)
            guard lines.count > 0 else { return }
            
            var startIndex = 0
            let firstLineFields = lines[0].lowercased()
            // Detect CSV Header
            if firstLineFields.contains("word") || firstLineFields.contains("meaning") {
                startIndex = 1
            }
            
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
                let topicVal = (fields.indices.contains(6) && !fields[6].isEmpty) ? fields[6] : currentTopicId
                let levelVal = (fields.indices.contains(7) && !fields[7].isEmpty) ? fields[7] : "Beginner"
                
                let status: ImportStatus
                let reason: String
                
                if wordVal.isEmpty || meaningVal.isEmpty || topicVal.isEmpty {
                    status = .invalid
                    reason = "Thiếu trường bắt buộc"
                } else if words.contains(where: { $0.word.lowercased() == wordVal.lowercased() && $0.topicId == topicVal }) {
                    status = .duplicate
                    reason = "Từ vựng này đã tồn tại trong chủ đề"
                } else {
                    status = .valid
                    reason = "Hợp lệ"
                }
                
                records.append(ImportRecord(
                    word: wordVal,
                    phonetic: phoneticVal,
                    meaning: meaningVal,
                    example: exampleVal,
                    image: imageVal,
                    audio: audioVal,
                    topicId: topicVal,
                    level: levelVal,
                    status: status,
                    statusReason: reason
                ))
            }
        }
        
        self.parsedImportRecords = records
        
        // Update stats
        let valid = records.filter { $0.status == .valid }.count
        let duplicate = records.filter { $0.status == .duplicate }.count
        let invalid = records.filter { $0.status == .invalid }.count
        self.importStats = (validCount: valid, duplicateCount: duplicate, invalidCount: invalid)
    }
    
    func commitImportedRecords() async {
        self.isLoading = true
        let validRecords = parsedImportRecords.filter { $0.status == .valid }
        var affectedTopicIds: Set<String> = []
        
        for record in validRecords {
            let wordId = "word_\(UUID().uuidString.prefix(8).lowercased())"
            let newWord = VocabularyWord(
                id: wordId,
                word: record.word,
                phonetic: record.phonetic,
                meaning: record.meaning,
                example: record.example,
                image: record.image,
                audio: record.audio,
                topicId: record.topicId,
                level: record.level
            )
            
            do {
                try await repository.saveWord(word: newWord)
                words.append(newWord)
                affectedTopicIds.insert(record.topicId)
            } catch {
                print("Import failure for word \(record.word): \(error.localizedDescription)")
            }
        }
        
        // Update local cached topics totalWords counts
        for topicId in affectedTopicIds {
            if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[tIdx].totalWords = words.filter { $0.topicId == topicId }.count
            }
        }
        
        // Reset states
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func deleteQuiz(quizId: String, topicId: String? = nil) async {
        do {
            try await repository.deleteQuiz(quizId: quizId, topicId: topicId)
            quizzes.removeAll(where: { $0.id == quizId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    func deleteListeningExercise(exerciseId: String, topicId: String? = nil) async {
        do {
            try await repository.deleteListeningExercise(exerciseId: exerciseId, topicId: topicId)
            listeningExercises.removeAll(where: { $0.id == exerciseId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
