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
    }
}
