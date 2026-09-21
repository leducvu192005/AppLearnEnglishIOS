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
            let fcmToken = data["fcmToken"] as? String
            let isActive = data["isActive"] as? Bool ?? true
            
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
                avatar: avatar,
                fcmToken: fcmToken,
                isActive: isActive
            )
        }
    }
    
    func saveUser(user: UserModel) async throws {
        let docRef = db.collection("users").document(user.uid)
        var dict: [String: Any] = [
            "uid": user.uid,
            "name": user.name,
            "email": user.email,
            "role": user.role,
            "streak": user.streak,
            "level": user.level,
            "xp": user.xp,
            "dailyGoal": user.dailyGoal,
            "isActive": user.isAccountActive,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let dailyXP = user.dailyXP {
            dict["dailyXP"] = dailyXP
        }
        if let avatar = user.avatar, !avatar.isEmpty {
            dict["avatar"] = avatar
        }
        if let fcmToken = user.fcmToken, !fcmToken.isEmpty {
            dict["fcmToken"] = fcmToken
        }
        try await docRef.setData(dict, merge: true)
    }
    
    func createUser(user: UserModel) async throws {
        let docRef = db.collection("users").document(user.uid)
        var dict: [String: Any] = [
            "uid": user.uid,
            "name": user.name,
            "email": user.email,
            "role": user.role,
            "streak": user.streak,
            "level": user.level,
            "xp": user.xp,
            "dailyXP": user.dailyXP ?? 0,
            "dailyGoal": user.dailyGoal,
            "isActive": user.isAccountActive,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let avatar = user.avatar, !avatar.isEmpty {
            dict["avatar"] = avatar
        }
        try await docRef.setData(dict)
    }
    
    func deleteUser(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }
    
    func toggleUserActiveStatus(uid: String, isActive: Bool) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData([
            "isActive": isActive,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func updateUserXPAndLevel(uid: String, xp: Int, level: String) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData([
            "xp": xp,
            "level": level,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - 1. VOCABULARY & TOPICS (/topics and /vocabulary)
    func fetchAllTopics() async throws -> [Topic] {
        let snapshot = try await db.collection("topics").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Topic.self)
        }
    }
    
    func saveTopic(topic: Topic) async throws {
        let docRef = db.collection("topics").document(topic.id)
        try docRef.setData(from: topic, merge: true)
    }
    
    func deleteTopic(topicId: String) async throws {
        // Delete the vocabulary topic document
        try await db.collection("topics").document(topicId).delete()
        
        // Delete all vocabulary words associated with this topic
        let wordsSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: topicId)
            .getDocuments()
        
        let batch = db.batch()
        for doc in wordsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
    
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        let snapshot = try await db.collection("vocabulary").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: VocabularyWord.self)
        }
    }
    
    func saveWord(word: VocabularyWord) async throws {
        let docRef = db.collection("vocabulary").document(word.id)
        
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
        
        let wordsInTopicSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: topicId)
            .getDocuments()
        
        let totalCount = wordsInTopicSnapshot.documents.count
        try await db.collection("topics").document(topicId).updateData([
            "totalWords": totalCount
        ])
    }
    
    func saveWordsBatch(words: [VocabularyWord], topicId: String) async throws {
        let resolvedTopicId = topicId.isEmpty ? "general" : topicId
        let topicDocRef = db.collection("topics").document(resolvedTopicId)
        
        try await topicDocRef.setData([
            "id": resolvedTopicId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        let batch = db.batch()
        for word in words {
            let docRef = db.collection("vocabulary").document(word.id)
            let dict: [String: Any] = [
                "id": word.id,
                "word": word.word,
                "phonetic": word.phonetic,
                "meaning": word.meaning,
                "example": word.example,
                "image": word.image,
                "audio": word.audio,
                "topicId": resolvedTopicId,
                "level": word.level
            ]
            batch.setData(dict, forDocument: docRef, merge: true)
        }
        try await batch.commit()
        
        let countSnapshot = try await db.collection("vocabulary")
            .whereField("topicId", isEqualTo: resolvedTopicId)
            .getDocuments()
        try await topicDocRef.updateData([
            "totalWords": countSnapshot.documents.count
        ])
    }
    
    // MARK: - 2. QUIZZES SEPARATE COLLECTION (/quizzes and /quizzes/{topicId}/questions)
    func fetchQuizTopics() async throws -> [Topic] {
        let snapshot = try await db.collection("quizzes").getDocuments()
        return snapshot.documents.compactMap { doc -> Topic? in
            let data = doc.data()
            let topicId = doc.documentID
            let name = data["name"] as? String ?? topicId.capitalized
            let desc = data["description"] as? String ?? ""
            let image = data["image"] as? String ?? "checklist"
            let count = data["totalQuestions"] as? Int ?? 0
            return Topic(id: topicId, name: name, description: desc, image: image, totalWords: count)
        }
    }
    
    func saveQuizTopic(topic: Topic) async throws {
        let topicDocRef = db.collection("quizzes").document(topic.id)
        try await topicDocRef.setData([
            "id": topic.id,
            "topicId": topic.id,
            "name": topic.name,
            "description": topic.description,
            "image": topic.image,
            "totalQuestions": topic.totalWords,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    func deleteQuizTopic(topicId: String) async throws {
        let topicDocRef = db.collection("quizzes").document(topicId)
        
        // 1. Delete all questions in subcollection /quizzes/{topicId}/questions
        let questionsSnapshot = try await topicDocRef.collection("questions").getDocuments()
        let batch = db.batch()
        for doc in questionsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        
        // 2. Delete the quiz topic document /quizzes/{topicId}
        try await topicDocRef.delete()
        
        // 3. Delete any legacy flat quiz docs with topicId == topicId
        let legacySnapshot = try await db.collection("quizzes").whereField("topicId", isEqualTo: topicId).getDocuments()
        if !legacySnapshot.documents.isEmpty {
            let legacyBatch = db.batch()
            for doc in legacySnapshot.documents {
                legacyBatch.deleteDocument(doc.reference)
            }
            try await legacyBatch.commit()
        }
    }
    
    func fetchAllQuizzes() async throws -> [Quiz] {
        var allQuizzes: [Quiz] = []
        var foundDocIds = Set<String>()
        
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
                            if !foundDocIds.contains(q.id) {
                                foundDocIds.insert(q.id)
                                allQuizzes.append(q)
                            }
                        }
                        continue
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let topicId = data["topicId"] as? String ?? tDoc.documentID
                    let type = data["type"] as? String ?? "multiple_choice"
                    let level = data["level"] as? String ?? "Beginner"
                    let audioUrl = data["audioUrl"] as? String
                    
                    if !foundDocIds.contains(id) {
                        foundDocIds.insert(id)
                        allQuizzes.append(Quiz(id: id, topicId: topicId, question: question, answers: answers, correctAnswer: correctAnswer, type: type, level: level, audioUrl: audioUrl))
                    }
                }
                
                // Legacy flat quiz document check
                let tData = tDoc.data()
                if let q = tData["question"] as? String,
                   let ans = tData["answers"] as? [String],
                   let correct = tData["correctAnswer"] as? String {
                    let id = tDoc.documentID
                    if !foundDocIds.contains(id) {
                        foundDocIds.insert(id)
                        let topicId = tData["topicId"] as? String ?? "general"
                        let type = tData["type"] as? String ?? "multiple_choice"
                        let level = tData["level"] as? String ?? "Beginner"
                        let audioUrl = tData["audioUrl"] as? String
                        allQuizzes.append(Quiz(id: id, topicId: topicId, question: q, answers: ans, correctAnswer: correct, type: type, level: level, audioUrl: audioUrl))
                    }
                }
            }
        } catch {
            print("Error fetching quizzes: \(error)")
        }
        
        return allQuizzes
    }
    
    func saveQuiz(quiz: Quiz) async throws {
        let topicId = quiz.topicId.isEmpty ? "general" : quiz.topicId
        let topicDocRef = db.collection("quizzes").document(topicId)
        
        // 1. Ensure Quiz Topic Document exists
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
        try await topicDocRef.setData([
            "totalQuestions": countSnapshot.documents.count
        ], merge: true)
    }
    
    func saveQuizzesBatch(quizzes: [Quiz], topicId: String) async throws {
        guard !quizzes.isEmpty else { return }
        let resolvedTopicId = topicId.isEmpty ? "general" : topicId
        let topicDocRef = db.collection("quizzes").document(resolvedTopicId)
        
        // 1. Ensure Topic Document exists
        try await topicDocRef.setData([
            "id": resolvedTopicId,
            "topicId": resolvedTopicId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        // 2. Batch write all questions
        let batch = db.batch()
        for quiz in quizzes {
            let qRef = topicDocRef.collection("questions").document(quiz.id)
            var dict: [String: Any] = [
                "id": quiz.id,
                "topicId": resolvedTopicId,
                "question": quiz.question,
                "answers": quiz.answers,
                "correctAnswer": quiz.correctAnswer,
                "type": quiz.type,
                "level": quiz.level ?? "Beginner"
            ]
            if let audio = quiz.audioUrl, !audio.isEmpty {
                dict["audioUrl"] = audio
            }
            batch.setData(dict, forDocument: qRef, merge: true)
        }
        try await batch.commit()
        
        // 3. Update question counter
        let countSnapshot = try await topicDocRef.collection("questions").getDocuments()
        try await topicDocRef.setData([
            "totalQuestions": countSnapshot.documents.count
        ], merge: true)
    }
    
    func deleteQuiz(quizId: String, topicId: String? = nil) async throws {
        if let tId = topicId, !tId.isEmpty {
            let topicDocRef = db.collection("quizzes").document(tId)
            try await topicDocRef.collection("questions").document(quizId).delete()
            
            let countSnapshot = try await topicDocRef.collection("questions").getDocuments()
            try await topicDocRef.setData([
                "totalQuestions": countSnapshot.documents.count
            ], merge: true)
        } else {
            let topicDocs = try await db.collection("quizzes").getDocuments()
            for tDoc in topicDocs.documents {
                try? await tDoc.reference.collection("questions").document(quizId).delete()
            }
        }
        
        try? await db.collection("quizzes").document(quizId).delete()
    }
    
    // MARK: - 3. LISTENING SEPARATE COLLECTION (/listening_exercises and /listening_exercises/{topicId}/sentences)
    func fetchListeningTopics() async throws -> [Topic] {
        let snapshot = try await db.collection("listening_exercises").getDocuments()
        return snapshot.documents.compactMap { doc -> Topic? in
            let data = doc.data()
            let topicId = doc.documentID
            let name = data["name"] as? String ?? topicId.capitalized
            let desc = data["description"] as? String ?? ""
            let image = data["image"] as? String ?? "headphones"
            let count = data["totalSentences"] as? Int ?? 0
            return Topic(id: topicId, name: name, description: desc, image: image, totalWords: count)
        }
    }
    
    func saveListeningTopic(topic: Topic) async throws {
        let topicDocRef = db.collection("listening_exercises").document(topic.id)
        try await topicDocRef.setData([
            "id": topic.id,
            "topicId": topic.id,
            "name": topic.name,
            "description": topic.description,
            "image": topic.image,
            "totalSentences": topic.totalWords,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    func deleteListeningTopic(topicId: String) async throws {
        let topicDocRef = db.collection("listening_exercises").document(topicId)
        
        // 1. Delete all sentences in subcollection /listening_exercises/{topicId}/sentences
        let sentencesSnapshot = try await topicDocRef.collection("sentences").getDocuments()
        let batch = db.batch()
        for doc in sentencesSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        
        // 2. Delete the listening topic document /listening_exercises/{topicId}
        try await topicDocRef.delete()
        
        // 3. Delete any legacy flat listening docs with topicId == topicId
        let legacySnapshot = try await db.collection("listening_exercises").whereField("topicId", isEqualTo: topicId).getDocuments()
        if !legacySnapshot.documents.isEmpty {
            let legacyBatch = db.batch()
            for doc in legacySnapshot.documents {
                legacyBatch.deleteDocument(doc.reference)
            }
            try await legacyBatch.commit()
        }
    }
    
    func fetchAllListeningExercises() async throws -> [ListeningExercise] {
        var allExercises: [ListeningExercise] = []
        var foundDocIds = Set<String>()
        
        do {
            let topicDocs = try await db.collection("listening_exercises").getDocuments()
            for tDoc in topicDocs.documents {
                let sentencesSnapshot = try await tDoc.reference.collection("sentences").getDocuments()
                for doc in sentencesSnapshot.documents {
                    let data = doc.data()
                    guard let sentence = data["sentence"] as? String,
                          let translation = data["translation"] as? String else {
                        if let ex = try? doc.data(as: ListeningExercise.self) {
                            if !foundDocIds.contains(ex.id) {
                                foundDocIds.insert(ex.id)
                                allExercises.append(ex)
                            }
                        }
                        continue
                    }
                    let id = data["id"] as? String ?? doc.documentID
                    let topicId = data["topicId"] as? String ?? tDoc.documentID
                    let level = data["level"] as? String ?? "Beginner"
                    let audioUrl = data["audioUrl"] as? String
                    let hint = data["hint"] as? String
                    
                    if !foundDocIds.contains(id) {
                        foundDocIds.insert(id)
                        allExercises.append(ListeningExercise(id: id, sentence: sentence, translation: translation, topicId: topicId, level: level, audioUrl: audioUrl, hint: hint))
                    }
                }
                
                // Legacy flat listening exercise check
                let tData = tDoc.data()
                if let s = tData["sentence"] as? String,
                   let tr = tData["translation"] as? String {
                    let id = tDoc.documentID
                    if !foundDocIds.contains(id) {
                        foundDocIds.insert(id)
                        let topicId = tData["topicId"] as? String ?? "general"
                        let level = tData["level"] as? String ?? "Beginner"
                        let audioUrl = tData["audioUrl"] as? String
                        let hint = tData["hint"] as? String
                        allExercises.append(ListeningExercise(id: id, sentence: s, translation: tr, topicId: topicId, level: level, audioUrl: audioUrl, hint: hint))
                    }
                }
            }
        } catch {
            print("Error fetching listening exercises: \(error)")
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
        try await topicDocRef.setData([
            "totalSentences": countSnapshot.documents.count
        ], merge: true)
    }
    
    func saveListeningExercisesBatch(exercises: [ListeningExercise], topicId: String) async throws {
        guard !exercises.isEmpty else { return }
        let resolvedTopicId = topicId.isEmpty ? "general" : topicId
        let topicDocRef = db.collection("listening_exercises").document(resolvedTopicId)
        
        // 1. Ensure Topic Document exists
        try await topicDocRef.setData([
            "id": resolvedTopicId,
            "topicId": resolvedTopicId,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        // 2. Batch write all sentences
        let batch = db.batch()
        for ex in exercises {
            let sRef = topicDocRef.collection("sentences").document(ex.id)
            var dict: [String: Any] = [
                "id": ex.id,
                "topicId": resolvedTopicId,
                "sentence": ex.sentence,
                "translation": ex.translation,
                "level": ex.level
            ]
            if let hint = ex.hint, !hint.isEmpty {
                dict["hint"] = hint
            }
            if let audio = ex.audioUrl, !audio.isEmpty {
                dict["audioUrl"] = audio
            }
            batch.setData(dict, forDocument: sRef, merge: true)
        }
        try await batch.commit()
        
        // 3. Update count
        let countSnapshot = try await topicDocRef.collection("sentences").getDocuments()
        try await topicDocRef.setData([
            "totalSentences": countSnapshot.documents.count
        ], merge: true)
    }
    
    func deleteListeningExercise(exerciseId: String, topicId: String? = nil) async throws {
        if let tId = topicId, !tId.isEmpty {
            let topicDocRef = db.collection("listening_exercises").document(tId)
            try await topicDocRef.collection("sentences").document(exerciseId).delete()
            
            let countSnapshot = try await topicDocRef.collection("sentences").getDocuments()
            try await topicDocRef.setData([
                "totalSentences": countSnapshot.documents.count
            ], merge: true)
        } else {
            let topicDocs = try await db.collection("listening_exercises").getDocuments()
            for tDoc in topicDocs.documents {
                try? await tDoc.reference.collection("sentences").document(exerciseId).delete()
            }
        }
        
        try? await db.collection("listening_exercises").document(exerciseId).delete()
    }
    
    // MARK: - 4. NOTIFICATIONS & PUSH CAMPAIGNS (/notifications_history)
    func fetchAllNotifications() async throws -> [AdminNotification] {
        do {
            let snapshot = try await db.collection("notifications_history")
                .order(by: "sentAt", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: AdminNotification.self)
            }
        } catch {
            print("Error fetching notifications: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveNotification(notification: AdminNotification) async throws {
        let docRef = db.collection("notifications_history").document(notification.id)
        try docRef.setData(from: notification, merge: true)
        
        // Also write in recipient in-app notifications subcollection
        if notification.targetType == "specific_user", let userId = notification.targetUserId, !userId.isEmpty {
            let userNotifRef = db.collection("users").document(userId).collection("notifications").document(notification.id)
            var dict: [String: Any] = [
                "id": notification.id,
                "title": notification.title,
                "body": notification.body,
                "category": notification.category,
                "createdAt": FieldValue.serverTimestamp(),
                "isRead": false
            ]
            if let link = notification.deepLink { dict["deepLink"] = link }
            if let img = notification.imageUrl { dict["imageUrl"] = img }
            try? await userNotifRef.setData(dict, merge: true)
        }
    }
    
    func deleteNotification(id: String) async throws {
        try await db.collection("notifications_history").document(id).delete()
    }
}
