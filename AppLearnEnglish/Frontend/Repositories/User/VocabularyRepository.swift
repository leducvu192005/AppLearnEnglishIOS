//
//  VocabularyRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol VocabularyRepositoryProtocol {
    func fetchTopics() async throws -> [Topic]
    func fetchWords(for topicId: String) async throws -> [VocabularyWord]
    func markWordAsLearned(userId: String, wordId: String) async throws
    func toggleFavoriteWord(userId: String, wordId: String, isFavorite: Bool) async throws
    func fetchAllVocabulary() async throws -> [VocabularyWord]
    func fetchLearnedWordIds(userId: String) async throws -> Set<String>
    func fetchFavoriteWordIds(userId: String) async throws -> Set<String>
}

final class VocabularyRepository: VocabularyRepositoryProtocol {
    private let firestoreService: FirestoreService
    
    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }
    
    func fetchTopics() async throws -> [Topic] {
        try await firestoreService.fetchTopics()
    }
    
    func fetchWords(for topicId: String) async throws -> [VocabularyWord] {
        try await firestoreService.fetchWords(for: topicId)
    }
    
    func markWordAsLearned(userId: String, wordId: String) async throws {
        try await firestoreService.markWordAsLearned(userId: userId, wordId: wordId)
    }
    
    func toggleFavoriteWord(userId: String, wordId: String, isFavorite: Bool) async throws {
        try await firestoreService.toggleFavoriteWord(userId: userId, wordId: wordId, isFavorite: isFavorite)
    }
    
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        try await firestoreService.fetchAllVocabulary()
    }
    
    func fetchLearnedWordIds(userId: String) async throws -> Set<String> {
        try await firestoreService.fetchLearnedWordIds(userId: userId)
    }
    
    func fetchFavoriteWordIds(userId: String) async throws -> Set<String> {
        try await firestoreService.fetchFavoriteWordIds(userId: userId)
    }
}
