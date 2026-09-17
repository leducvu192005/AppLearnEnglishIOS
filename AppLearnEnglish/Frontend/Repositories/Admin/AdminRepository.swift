//
//  AdminRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol AdminRepositoryProtocol {
    func getAllUsers() async throws -> [UserModel]
    func saveUser(user: UserModel) async throws
    func createUser(user: UserModel) async throws
    func deleteUser(uid: String) async throws
    func toggleUserActiveStatus(uid: String, isActive: Bool) async throws
    func updateUserXPAndLevel(uid: String, xp: Int, level: String) async throws
    
    // Vocabulary Domain (/topics & /vocabulary)
    func getAllTopics() async throws -> [Topic]
    func saveTopic(topic: Topic) async throws
    func deleteTopic(topicId: String) async throws
    func getAllVocabulary() async throws -> [VocabularyWord]
    func saveWord(word: VocabularyWord) async throws
    func saveWordsBatch(words: [VocabularyWord], topicId: String) async throws
    func deleteWord(wordId: String, topicId: String) async throws
    
    // Quiz Domain (/quizzes)
    func getAllQuizTopics() async throws -> [Topic]
    func getAllQuizzes() async throws -> [Quiz]
    func saveQuiz(quiz: Quiz) async throws
    func saveQuizTopic(topic: Topic) async throws
    func deleteQuizTopic(topicId: String) async throws
    func saveQuizzesBatch(quizzes: [Quiz], topicId: String) async throws
    func deleteQuiz(quizId: String, topicId: String?) async throws
    
    // Listening Domain (/listening_exercises)
    func getAllListeningTopics() async throws -> [Topic]
    func getAllListeningExercises() async throws -> [ListeningExercise]
    func saveListeningExercise(exercise: ListeningExercise) async throws
    func saveListeningTopic(topic: Topic) async throws
    func deleteListeningTopic(topicId: String) async throws
    func saveListeningExercisesBatch(exercises: [ListeningExercise], topicId: String) async throws
    func deleteListeningExercise(exerciseId: String, topicId: String?) async throws
}

class AdminRepository: AdminRepositoryProtocol {
    private let adminFirestore = AdminFirestoreService.shared
    
    func getAllUsers() async throws -> [UserModel] {
        try await adminFirestore.fetchAllUsers()
    }
    
    func saveUser(user: UserModel) async throws {
        try await adminFirestore.saveUser(user: user)
    }
    
    func createUser(user: UserModel) async throws {
        try await adminFirestore.createUser(user: user)
    }
    
    func deleteUser(uid: String) async throws {
        try await adminFirestore.deleteUser(uid: uid)
    }
    
    func toggleUserActiveStatus(uid: String, isActive: Bool) async throws {
        try await adminFirestore.toggleUserActiveStatus(uid: uid, isActive: isActive)
    }
    
    func updateUserXPAndLevel(uid: String, xp: Int, level: String) async throws {
        try await adminFirestore.updateUserXPAndLevel(uid: uid, xp: xp, level: level)
    }
    
    // Vocabulary Domain
    func getAllTopics() async throws -> [Topic] {
        try await adminFirestore.fetchAllTopics()
    }
    
    func saveTopic(topic: Topic) async throws {
        try await adminFirestore.saveTopic(topic: topic)
    }
    
    func deleteTopic(topicId: String) async throws {
        try await adminFirestore.deleteTopic(topicId: topicId)
    }
    
    func getAllVocabulary() async throws -> [VocabularyWord] {
        try await adminFirestore.fetchAllVocabulary()
    }
    
    func saveWord(word: VocabularyWord) async throws {
        try await adminFirestore.saveWord(word: word)
    }
    
    func saveWordsBatch(words: [VocabularyWord], topicId: String) async throws {
        try await adminFirestore.saveWordsBatch(words: words, topicId: topicId)
    }
    
    func deleteWord(wordId: String, topicId: String) async throws {
        try await adminFirestore.deleteWord(wordId: wordId, topicId: topicId)
    }
    
    // Quiz Domain
    func getAllQuizTopics() async throws -> [Topic] {
        try await adminFirestore.fetchQuizTopics()
    }
    
    func getAllQuizzes() async throws -> [Quiz] {
        try await adminFirestore.fetchAllQuizzes()
    }
    
    func saveQuiz(quiz: Quiz) async throws {
        try await adminFirestore.saveQuiz(quiz: quiz)
    }
    
    func saveQuizTopic(topic: Topic) async throws {
        try await adminFirestore.saveQuizTopic(topic: topic)
    }
    
    func deleteQuizTopic(topicId: String) async throws {
        try await adminFirestore.deleteQuizTopic(topicId: topicId)
    }
    
    func saveQuizzesBatch(quizzes: [Quiz], topicId: String) async throws {
        try await adminFirestore.saveQuizzesBatch(quizzes: quizzes, topicId: topicId)
    }
    
    func deleteQuiz(quizId: String, topicId: String? = nil) async throws {
        try await adminFirestore.deleteQuiz(quizId: quizId, topicId: topicId)
    }
    
    // Listening Domain
    func getAllListeningTopics() async throws -> [Topic] {
        try await adminFirestore.fetchListeningTopics()
    }
    
    func getAllListeningExercises() async throws -> [ListeningExercise] {
        try await adminFirestore.fetchAllListeningExercises()
    }
    
    func saveListeningExercise(exercise: ListeningExercise) async throws {
        try await adminFirestore.saveListeningExercise(exercise: exercise)
    }
    
    func saveListeningTopic(topic: Topic) async throws {
        try await adminFirestore.saveListeningTopic(topic: topic)
    }
    
    func deleteListeningTopic(topicId: String) async throws {
        try await adminFirestore.deleteListeningTopic(topicId: topicId)
    }
    
    func saveListeningExercisesBatch(exercises: [ListeningExercise], topicId: String) async throws {
        try await adminFirestore.saveListeningExercisesBatch(exercises: exercises, topicId: topicId)
    }
    
    func deleteListeningExercise(exerciseId: String, topicId: String? = nil) async throws {
        try await adminFirestore.deleteListeningExercise(exerciseId: exerciseId, topicId: topicId)
    }
}
