//
//  UserService.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch User Profile from Firestore
    func fetchUser(uid: String) async throws -> UserModel {
        let docRef = db.collection("users").document(uid)
        let document = try await docRef.getDocument()
        
        guard document.exists else {
            throw NSError(
                domain: "UserService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy hồ sơ người dùng trong hệ thống."]
            )
        }
        
        do {
            // Decodes automatically using Codable extensions in FirebaseFirestore
            let user = try document.data(as: UserModel.self)
            return user
        } catch {
            print("Lỗi decode UserModel: \(error). Tiến hành giải mã thủ công...")
            
            // Manual Decoding fallback to prevent app crashing on slight model variations
            let data = document.data() ?? [:]
            let name = data["name"] as? String ?? "Người dùng mới"
            let email = data["email"] as? String ?? ""
            let role = data["role"] as? String ?? "user"
            let streak = data["streak"] as? Int ?? 0
            let level = data["level"] as? String ?? "Beginner"
            let xp = data["xp"] as? Int ?? 0
            let dailyGoal = data["dailyGoal"] as? Int ?? 20
            
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
                dailyGoal: dailyGoal,
                createdAt: createdAt
            )
        }
    }
    
    // MARK: - Save or Update Entire User Profile
    func updateUser(user: UserModel) async throws {
        let docRef = db.collection("users").document(user.uid)
        try docRef.setData(from: user, merge: true)
    }
    
    // MARK: - Update Learning Progress & Streak dynamically using Firestore lastStudyDate
    func updateProgressAndStreak(uid: String, xp: Int) async throws {
        let docRef = db.collection("users").document(uid)
        
        // Fetch current user details to calculate streak
        let document = try await docRef.getDocument()
        let data = document.data() ?? [:]
        
        let currentStreak = data["streak"] as? Int ?? 0
        let lastStudyTimestamp = data["lastStudyDate"] as? Timestamp
        
        var newStreak = currentStreak
        let calendar = Calendar.current
        let today = Date()
        
        if let lastDate = lastStudyTimestamp?.dateValue() {
            if calendar.isDateInToday(lastDate) {
                // Studied today, streak stays same
                newStreak = currentStreak
            } else if calendar.isDateInYesterday(lastDate) {
                // Studied yesterday, increment streak
                newStreak = currentStreak + 1
            } else {
                // Missed day(s), reset streak to 1
                newStreak = 1
            }
        } else {
            // First study session, start at 1
            newStreak = 1
        }
        
        try await docRef.updateData([
            "xp": FieldValue.increment(Int64(xp)),
            "streak": newStreak,
            "lastStudyDate": Timestamp(date: today)
        ])
    }
}
