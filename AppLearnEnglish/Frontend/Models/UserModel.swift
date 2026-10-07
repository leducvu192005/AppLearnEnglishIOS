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
    var role: String       // "user" hoặc "admin"
    var streak: Int
    var level: String      // ví dụ: "Beginner"
    var xp: Int
    var dailyXP: Int?      // XP kiếm được trong ngày
    var dailyGoal: Int     // Mục tiêu XP/ngày (mặc định 20)
    var createdAt: Date
    var avatar: String?    // URL avatar hoặc tên ảnh
    var fcmToken: String?  // Push notification token
    var isActive: Bool?    // Trạng thái tài khoản hoạt động / bị khóa
    
    // MARK: - ✨ Premium / VIP Subscription Fields (Mới thêm)
    var isPremium: Bool?           // true: tài khoản VIP, false/nil: tài khoản Free
    var premiumPlan: String?       // "monthly", "yearly", "lifetime", "admin_granted", "demo_vip"
    var premiumExpiresAt: Date?    // Thời điểm hết hạn gói
    
    // MARK: - ✨ Helper: Kiểm tra quyền VIP còn hiệu lực không
    var isProMember: Bool {
        guard isPremium == true else { return false }
        
        // Nếu có ngày hết hạn thì kiểm tra xem thời gian hiện tại đã vượt quá chưa
        if let expiresAt = premiumExpiresAt {
            return expiresAt > Date()
        }
        
        // Không có ngày hết hạn tức là gói Mua Trọn Đời (Lifetime)
        return true
    }
    
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
        isActive: Bool? = true,
        isPremium: Bool? = false,
        premiumPlan: String? = nil,
        premiumExpiresAt: Date? = nil
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
        self.isPremium = isPremium
        self.premiumPlan = premiumPlan
        self.premiumExpiresAt = premiumExpiresAt
    }
    
    // CodingKeys giúp Firestore Decode / Encode chính xác
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
        case isPremium
        case premiumPlan
        case premiumExpiresAt
    }
}
