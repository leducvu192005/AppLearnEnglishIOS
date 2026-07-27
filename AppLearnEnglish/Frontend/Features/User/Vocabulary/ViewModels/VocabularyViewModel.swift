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
    
    private let vocabularyService = VocabularyService.shared
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Initializer
    init() {
        Task {
            await loadTopics()
            await loadUserPreferences()
        }
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
        do {
            self.words = try await vocabularyService.fetchWords(for: topicId)
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
}
