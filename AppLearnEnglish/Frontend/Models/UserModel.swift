//
//  UserModel.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

struct UserModel: Codable, Identifiable, Equatable {
    var id: String { uid }
    
    let uid: String
    var name: String
    let email: String
    var role: String       // "user" or "admin"
    var streak: Int
    var level: String      // e.g. "Beginner"
    var xp: Int
    var dailyXP: Int?      // daily XP earned
    var dailyGoal: Int     // e.g. 20 (XP target per day)
    var createdAt: Date
    var avatar: String?    // selected avatar emoji
    var fcmToken: String?  // Firebase Cloud Messaging device push token
    var isActive: Bool?    // whether the account is active or suspended (nil defaults to true)
    
    var isAccountActive: Bool {
        isActive ?? true
    }
    
    init(
        uid: String,
        name: String,
        email: String,
        role: String = "user",
        streak: Int = 0,
        level: String = "Beginner",
        xp: Int = 0,
        dailyXP: Int? = 0,
        dailyGoal: Int = 20,
        createdAt: Date = Date(),
        avatar: String? = nil,
        fcmToken: String? = nil,
        isActive: Bool? = true
    ) {
        self.uid = uid
        self.name = name
        self.email = email
        self.role = role
        self.streak = streak
        self.level = level
        self.xp = xp
        self.dailyXP = dailyXP
        self.dailyGoal = dailyGoal
        self.createdAt = createdAt
        self.avatar = avatar
        self.fcmToken = fcmToken
        self.isActive = isActive
    }
    
    // Custom coding keys if needed for compatibility
    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case email
        case role
        case streak
        case level
        case xp
        case dailyXP
        case dailyGoal
        case createdAt
        case avatar
        case fcmToken
        case isActive
    }
}
