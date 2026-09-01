//
//  AdminFirestoreService.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

class AdminFirestoreService {
    static let shared = AdminFirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User Management
    func fetchAllUsers() async throws -> [UserModel] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { doc -> UserModel? in
            let data = doc.data()
            let uid = doc.documentID
            let name = data["name"] as? String ?? "Học viên"
            let email = data["email"] as? String ?? ""
            let role = data["role"] as? String ?? "user"
            let streak = data["streak"] as? Int ?? 0
            let level = data["level"] as? String ?? "Beginner"
            let xp = data["xp"] as? Int ?? 0
            let dailyXP = data["dailyXP"] as? Int ?? 0
            let dailyGoal = data["dailyGoal"] as? Int ?? 20
            let avatar = data["avatar"] as? String
            
            let timestamp = data["createdAt"] as? Timestamp
            let createdAt = timestamp?.dateValue() ?? Date()
            
            return UserModel(
                uid: uid,
                name: name,
                email: email,
                role: role,
                streak: streak,
                level: level,
                xp: xp,
                dailyXP: dailyXP,
                dailyGoal: dailyGoal,
                createdAt: createdAt,
                avatar: avatar
            )
        }
    }
    
    func updateUserXPAndLevel(uid: String, xp: Int, level: String) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData([
            "xp": xp,
            "level": level
        ])
    }
    
    // MARK: - Topic Management
    func saveTopic(topic: Topic) async throws {
        let docRef = db.collection("topics").document(topic.id)
        try docRef.setData(from: topic, merge: true)
    }
    
    func deleteTopic(topicId: String) async throws {
        // Delete the topic document
        try await db.collection("topics").document(topicId).delete()
        
        // Optionally delete all words associated with this topic to keep clean
        let wordsSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: topicId)
            .getDocuments()
        
        let batch = db.batch()
        for doc in wordsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
    
    // MARK: - Vocabulary Management
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        let snapshot = try await db.collection("vocabulary").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: VocabularyWord.self)
        }
    }
    
    func saveWord(word: VocabularyWord) async throws {
        let docRef = db.collection("vocabulary").document(word.id)
        
        // Check if there was an existing word with a different topicId
        var oldTopicId: String? = nil
        if let existingDoc = try? await docRef.getDocument(), existingDoc.exists {
            oldTopicId = existingDoc.data()?["topicId"] as? String
        }
        
        try docRef.setData(from: word, merge: true)
        
        // Update the new topic's totalWords count
        let newTopicId = word.topicId
        let newCountSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: newTopicId)
            .getDocuments()
        try await db.collection("topics").document(newTopicId).updateData([
            "totalWords": newCountSnapshot.documents.count
        ])
        
        // If the topic was changed, update the old topic's totalWords count too
        if let oldId = oldTopicId, oldId != newTopicId {
            let oldCountSnapshot = try await db.collection("vocabulary")
                .whereField("topicId", isEqualTo: oldId)
                .getDocuments()
            try await db.collection("topics").document(oldId).updateData([
                "totalWords": oldCountSnapshot.documents.count
            ])
        }
    }
    
    func deleteWord(wordId: String, topicId: String) async throws {
        try await db.collection("vocabulary").document(wordId).delete()
        
        // Update topic count
        let wordsInTopicSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: topicId)
            .getDocuments()
        
        let totalCount = wordsInTopicSnapshot.documents.count
        
        try await db.collection("topics").document(topicId).updateData([
            "totalWords": totalCount
        ])
    }
    
    // MARK: - Quiz Management
    func fetchAllQuizzes() async throws -> [Quiz] {
        let snapshot = try await db.collection("quizzes").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Quiz.self)
        }
    }
    
    func saveQuiz(quiz: Quiz) async throws {
        let docRef = db.collection("quizzes").document(quiz.id)
        try docRef.setData(from: quiz, merge: true)
    }
    
    func deleteQuiz(quizId: String) async throws {
        try await db.collection("quizzes").document(quizId).delete()
    }
}
