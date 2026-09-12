//
//  QuizRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol QuizRepositoryProtocol {
    func fetchQuizzes(for topicId: String) async throws -> [Quiz]
    func updateProgressAndStreak(uid: String, xp: Int) async throws
}

final class QuizRepository: QuizRepositoryProtocol {
    private let firestoreService: FirestoreService
    
    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }
    
    func fetchQuizzes(for topicId: String) async throws -> [Quiz] {
        try await firestoreService.fetchQuizzes(for: topicId)
    }
    
    func updateProgressAndStreak(uid: String, xp: Int) async throws {
        try await firestoreService.updateProgressAndStreak(uid: uid, xp: xp)
    }
}
