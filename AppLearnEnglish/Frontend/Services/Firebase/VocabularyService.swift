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
    
    // MARK: - Fetch Words (Firestore /vocabulary/{topicId}/words)
    func fetchWords(for topicId: String = "") async throws -> [VocabularyWord] {
        let trimmed = topicId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != "all" {
            let subSnapshot = try await db.collection("vocabulary")
                .document(trimmed)
                .collection("words")
                .getDocuments()
            
            if !subSnapshot.documents.isEmpty {
                return subSnapshot.documents.compactMap { doc -> VocabularyWord? in
                    let data = doc.data()
                    guard let word = data["word"] as? String,
                          let meaning = data["meaning"] as? String else {
                        return try? doc.data(as: VocabularyWord.self)
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let phonetic = data["phonetic"] as? String ?? ""
                    let example = data["example"] as? String ?? ""
                    let image = data["image"] as? String ?? ""
                    let audio = data["audio"] as? String ?? ""
                    let tId = data["topicId"] as? String ?? trimmed
                    let level = data["level"] as? String ?? "Beginner"
                    return VocabularyWord(id: id, word: word, phonetic: phonetic, meaning: meaning, example: example, image: image, audio: audio, topicId: tId, level: level)
                }
            }
        }
        return try await fetchAllVocabulary()
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
    
    // MARK: - Fetch All Vocabulary Words (Firestore /vocabulary/{topicId}/words)
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        var allWords: [VocabularyWord] = []
        var seenWordIds = Set<String>()
        
        do {
            let topicDocs = try await db.collection("vocabulary").getDocuments()
            for tDoc in topicDocs.documents {
                let topicId = tDoc.documentID
                
                // 1. Fetch from subcollection /vocabulary/{topicId}/words
                let wordsSnapshot = try await tDoc.reference.collection("words").getDocuments()
                for doc in wordsSnapshot.documents {
                    let data = doc.data()
                    guard let word = data["word"] as? String,
                          let meaning = data["meaning"] as? String else {
                        if let w = try? doc.data(as: VocabularyWord.self) {
                            if !seenWordIds.contains(w.id) {
                                seenWordIds.insert(w.id)
                                allWords.append(w)
                            }
                        }
                        continue
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let phonetic = data["phonetic"] as? String ?? ""
                    let example = data["example"] as? String ?? ""
                    let image = data["image"] as? String ?? ""
                    let audio = data["audio"] as? String ?? ""
                    let tId = data["topicId"] as? String ?? topicId
                    let level = data["level"] as? String ?? "Beginner"
                    
                    if !seenWordIds.contains(id) {
                        seenWordIds.insert(id)
                        allWords.append(VocabularyWord(
                            id: id,
                            word: word,
                            phonetic: phonetic,
                            meaning: meaning,
                            example: example,
                            image: image,
                            audio: audio,
                            topicId: tId,
                            level: level
                        ))
                    }
                }
                
                // 2. Fallback check for legacy flat word documents in /vocabulary
                let tData = tDoc.data()
                if let wText = tData["word"] as? String,
                   let mText = tData["meaning"] as? String {
                    let id = tDoc.documentID
                    if !seenWordIds.contains(id) {
                        seenWordIds.insert(id)
                        let phonetic = tData["phonetic"] as? String ?? ""
                        let example = tData["example"] as? String ?? ""
                        let image = tData["image"] as? String ?? ""
                        let audio = tData["audio"] as? String ?? ""
                        let tId = tData["topicId"] as? String ?? "general"
                        let level = tData["level"] as? String ?? "Beginner"
                        allWords.append(VocabularyWord(
                            id: id,
                            word: wText,
                            phonetic: phonetic,
                            meaning: mText,
                            example: example,
                            image: image,
                            audio: audio,
                            topicId: tId,
                            level: level
                        ))
                    }
                }
            }
        } catch {
            print("Error fetching all vocabulary words: \(error.localizedDescription)")
        }
        
        return allWords
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
