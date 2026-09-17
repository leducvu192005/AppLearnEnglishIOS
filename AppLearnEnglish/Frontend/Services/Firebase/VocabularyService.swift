//
//  VocabularyService.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

class VocabularyService {
    static let shared = VocabularyService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch Topics (Firestore)
    func fetchTopics() async throws -> [Topic] {
        do {
            let snapshot = try await db.collection("topics").getDocuments()
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Topic.self)
            }
        } catch {
            print("Firestore fetch topics failed: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Fetch Words for Topic (Firestore)
    func fetchWords(for topicId: String) async throws -> [VocabularyWord] {
        do {
            let snapshot = try await db.collection("vocabulary")
                .whereField("topicId", isEqualTo: topicId)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: VocabularyWord.self)
            }
        } catch {
            print("Firestore fetch words failed: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Mark Word as Learned
    func markWordAsLearned(userId: String, wordId: String) async throws {
        let learnedDocRef = db.collection("users")
            .document(userId)
            .collection("learned_words")
            .document(wordId)
        
        // Write to learned_words subcollection
        try await learnedDocRef.setData([
            "wordId": wordId,
            "status": "learned",
            "learnedAt": FieldValue.serverTimestamp()
        ])
        
        // Dynamically update user's XP (+10) and streak in their profile
        try await UserService.shared.updateProgressAndStreak(uid: userId, xp: 10)
    }
    
    // MARK: - Toggle Favorite status
    func toggleFavoriteWord(userId: String, wordId: String, isFavorite: Bool) async throws {
        let favDocRef = db.collection("users")
            .document(userId)
            .collection("favorite_words")
            .document(wordId)
        
        if isFavorite {
            try await favDocRef.setData([
                "wordId": wordId,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await favDocRef.delete()
        }
    }
    
    // MARK: - Fetch All Vocabulary Words (Firestore)
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        do {
            let snapshot = try await db.collection("vocabulary").getDocuments()
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: VocabularyWord.self)
            }
        } catch {
            print("Error fetching all vocabulary words: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Fetch user specific learned word IDs
    func fetchLearnedWordIds(userId: String) async throws -> Set<String> {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("learned_words")
                .getDocuments()
            
            let ids = snapshot.documents.compactMap { doc -> String? in
                doc.documentID
            }
            return Set(ids)
        } catch {
            print("Error fetching learned words: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch user specific favorite word IDs
    func fetchFavoriteWordIds(userId: String) async throws -> Set<String> {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorite_words")
                .getDocuments()
            
            let ids = snapshot.documents.compactMap { doc -> String? in
                doc.documentID
            }
            return Set(ids)
        } catch {
            print("Error fetching favorite words: \(error)")
            return []
        }
    }
}
