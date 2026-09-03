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
    
    // MARK: - Quiz Management (/quizzes/{topicId}/questions/{quizId})
    func fetchAllQuizzes() async throws -> [Quiz] {
        var allQuizzes: [Quiz] = []
        
        do {
            let topicDocs = try await db.collection("quizzes").getDocuments()
            for tDoc in topicDocs.documents {
                let questionsSnapshot = try await tDoc.reference.collection("questions").getDocuments()
                for doc in questionsSnapshot.documents {
                    let data = doc.data()
                    guard let question = data["question"] as? String,
                          let answers = data["answers"] as? [String],
                          let correctAnswer = data["correctAnswer"] as? String else {
                        if let q = try? doc.data(as: Quiz.self) {
                            allQuizzes.append(q)
                        }
                        continue
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let topicId = data["topicId"] as? String ?? tDoc.documentID
                    let type = data["type"] as? String ?? "multiple_choice"
                    let level = data["level"] as? String ?? "Beginner"
                    let audioUrl = data["audioUrl"] as? String
                    allQuizzes.append(Quiz(id: id, topicId: topicId, question: question, answers: answers, correctAnswer: correctAnswer, type: type, level: level, audioUrl: audioUrl))
                }
            }
        } catch {
            print("Error fetching hierarchical quizzes: \(error)")
        }
        
        // Fallback: If no hierarchical docs were found, try legacy flat query
        if allQuizzes.isEmpty {
            let snapshot = try await db.collection("quizzes").getDocuments()
            allQuizzes = snapshot.documents.compactMap { doc in
                try? doc.data(as: Quiz.self)
            }
        }
        
        return allQuizzes
    }
    
    func saveQuiz(quiz: Quiz) async throws {
        let topicId = quiz.topicId.isEmpty ? "general" : quiz.topicId
        let topicDocRef = db.collection("quizzes").document(topicId)
        
        // 1. Ensure Topic Document in /quizzes/{topicId} exists
        try await topicDocRef.setData([
            "id": topicId,
            "topicId": topicId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        // 2. Save individual question inside subcollection /quizzes/{topicId}/questions/{quiz.id}
        let questionDocRef = topicDocRef.collection("questions").document(quiz.id)
        var dict: [String: Any] = [
            "id": quiz.id,
            "topicId": topicId,
            "question": quiz.question,
            "answers": quiz.answers,
            "correctAnswer": quiz.correctAnswer,
            "type": quiz.type,
            "level": quiz.level ?? "Beginner"
        ]
        if let audio = quiz.audioUrl, !audio.isEmpty {
            dict["audioUrl"] = audio
        }
        try await questionDocRef.setData(dict, merge: true)
        
        // 3. Update question counter in /quizzes/{topicId}
        let countSnapshot = try await topicDocRef.collection("questions").getDocuments()
        try await topicDocRef.updateData([
            "totalQuestions": countSnapshot.documents.count
        ])
    }
    
    func deleteQuiz(quizId: String, topicId: String? = nil) async throws {
        if let tId = topicId, !tId.isEmpty {
            let topicDocRef = db.collection("quizzes").document(tId)
            try await topicDocRef.collection("questions").document(quizId).delete()
            
            let countSnapshot = try await topicDocRef.collection("questions").getDocuments()
            try await topicDocRef.updateData([
                "totalQuestions": countSnapshot.documents.count
            ])
        } else {
            let topicDocs = try await db.collection("quizzes").getDocuments()
            for tDoc in topicDocs.documents {
                try? await tDoc.reference.collection("questions").document(quizId).delete()
            }
        }
        
        // Also cleanup legacy root doc if exists
        try? await db.collection("quizzes").document(quizId).delete()
    }
    
    // MARK: - Listening Exercises Management (/listening_exercises/{topicId}/sentences/{exerciseId})
    func fetchAllListeningExercises() async throws -> [ListeningExercise] {
        var allExercises: [ListeningExercise] = []
        
        do {
            let topicDocs = try await db.collection("listening_exercises").getDocuments()
            for tDoc in topicDocs.documents {
                let sentencesSnapshot = try await tDoc.reference.collection("sentences").getDocuments()
                for doc in sentencesSnapshot.documents {
                    let data = doc.data()
                    guard let sentence = data["sentence"] as? String,
                          let translation = data["translation"] as? String else {
                        if let ex = try? doc.data(as: ListeningExercise.self) {
                            allExercises.append(ex)
                        }
                        continue
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let topicId = data["topicId"] as? String ?? tDoc.documentID
                    let level = data["level"] as? String ?? "Beginner"
                    let audioUrl = data["audioUrl"] as? String
                    let hint = data["hint"] as? String
                    allExercises.append(ListeningExercise(id: id, sentence: sentence, translation: translation, topicId: topicId, level: level, audioUrl: audioUrl, hint: hint))
                }
            }
        } catch {
            print("Error fetching hierarchical listening exercises: \(error)")
        }
        
        if allExercises.isEmpty {
            let snapshot = try await db.collection("listening_exercises").getDocuments()
            allExercises = snapshot.documents.compactMap { doc in
                try? doc.data(as: ListeningExercise.self)
            }
        }
        
        return allExercises
    }
    
    func saveListeningExercise(exercise: ListeningExercise) async throws {
        let topicId = exercise.topicId.isEmpty ? "general" : exercise.topicId
        let topicDocRef = db.collection("listening_exercises").document(topicId)
        
        // 1. Ensure Topic Document in /listening_exercises/{topicId} exists
        try await topicDocRef.setData([
            "id": topicId,
            "topicId": topicId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        // 2. Save individual exercise inside subcollection /listening_exercises/{topicId}/sentences/{exercise.id}
        let sentenceDocRef = topicDocRef.collection("sentences").document(exercise.id)
        var dict: [String: Any] = [
            "id": exercise.id,
            "topicId": topicId,
            "sentence": exercise.sentence,
            "translation": exercise.translation,
            "level": exercise.level
        ]
        if let hint = exercise.hint, !hint.isEmpty {
            dict["hint"] = hint
        }
        if let audio = exercise.audioUrl, !audio.isEmpty {
            dict["audioUrl"] = audio
        }
        try await sentenceDocRef.setData(dict, merge: true)
        
        // 3. Update total sentences count
        let countSnapshot = try await topicDocRef.collection("sentences").getDocuments()
        try await topicDocRef.updateData([
            "totalSentences": countSnapshot.documents.count
        ])
    }
    
    func deleteListeningExercise(exerciseId: String, topicId: String? = nil) async throws {
        if let tId = topicId, !tId.isEmpty {
            let topicDocRef = db.collection("listening_exercises").document(tId)
            try await topicDocRef.collection("sentences").document(exerciseId).delete()
            
            let countSnapshot = try await topicDocRef.collection("sentences").getDocuments()
            try await topicDocRef.updateData([
                "totalSentences": countSnapshot.documents.count
            ])
        } else {
            let topicDocs = try await db.collection("listening_exercises").getDocuments()
            for tDoc in topicDocs.documents {
                try? await tDoc.reference.collection("sentences").document(exerciseId).delete()
            }
        }
        
        try? await db.collection("listening_exercises").document(exerciseId).delete()
    }
}
