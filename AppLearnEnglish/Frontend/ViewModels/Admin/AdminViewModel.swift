//
//  AdminViewModel.swift
//  AppLearnEnglish
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AdminViewModel: ObservableObject {
    private let repository: AdminRepositoryProtocol
    
    @Published var users: [UserModel] = []
    @Published var topics: [Topic] = []
    @Published var words: [VocabularyWord] = []
    @Published var quizzes: [Quiz] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    init(repository: AdminRepositoryProtocol? = nil) {
        self.repository = repository ?? AdminRepository()
    }
    
    // MARK: - Load All Admin Data
    func loadAllData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Load in parallel
            async let loadedUsers = repository.getAllUsers()
            async let loadedTopics = FirestoreService.shared.fetchTopics() // Reuse User read service
            async let loadedWords = repository.getAllVocabulary()
            async let loadedQuizzes = repository.getAllQuizzes()
            
            self.users = try await loadedUsers
            self.topics = try await loadedTopics
            self.words = try await loadedWords
            self.quizzes = try await loadedQuizzes
            
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // MARK: - User Operations
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
        let topicId = id ?? "custom_topic_\(UUID().uuidString.prefix(8).lowercased())"
        
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
        do {
            try await repository.deleteTopic(topicId: topicId)
            topics.removeAll(where: { $0.id == topicId })
            // Clean up cached words belonging to deleted topic
            words.removeAll(where: { $0.topicId == topicId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Vocabulary Operations
    func saveWord(id: String?, word: String, phonetic: String, meaning: String, example: String, topicId: String, level: String) async {
        let wordId = id ?? "word_\(UUID().uuidString.prefix(8).lowercased())"
        let newWord = VocabularyWord(
            id: wordId,
            word: word,
            phonetic: phonetic,
            meaning: meaning,
            example: example,
            image: "",
            audio: "",
            topicId: topicId,
            level: level
        )
        
        do {
            try await repository.saveWord(word: newWord)
            if let idx = words.firstIndex(where: { $0.id == wordId }) {
                words[idx] = newWord
            } else {
                words.append(newWord)
            }
            
            // Re-sync topic counts locally
            if let tIdx = topics.firstIndex(where: { $0.id == topicId }) {
                topics[tIdx].totalWords = words.filter { $0.topicId == topicId }.count
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
    
    // MARK: - Quiz Operations
    func saveQuiz(id: String?, question: String, answers: [String], correctAnswer: String, topicId: String, type: String) async {
        let quizId = id ?? "quiz_\(UUID().uuidString.prefix(8).lowercased())"
        let newQuiz = Quiz(
            id: quizId,
            topicId: topicId,
            question: question,
            answers: answers,
            correctAnswer: correctAnswer,
            type: type,
            audioUrl: nil
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
    
    func deleteQuiz(quizId: String) async {
        do {
            try await repository.deleteQuiz(quizId: quizId)
            quizzes.removeAll(where: { $0.id == quizId })
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
