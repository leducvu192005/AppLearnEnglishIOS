//
//  AppEvent.swift
//  AppLearnEnglish
//
//  Created by Antigravity AI on 28/9/26.
//

import Foundation

/// Defines standard event types emitted by user actions throughout the app.
public enum AppEventType: String, Codable, CaseIterable {
    case userRegistered = "user_registered"
    case lessonStarted = "lesson_started"
    case lessonCompleted = "lesson_completed"
    case quizCompleted = "quiz_completed"
    case quizFailed = "quiz_failed"
    case streakAtRisk = "streak_at_risk"
    case streakBroken = "streak_broken"
    case vocabularyDue = "vocabulary_due"
    case userInactive = "user_inactive"
    case subscriptionExpiring = "subscription_expiring"
    
    public var displayName: String {
        switch self {
        case .userRegistered: return "Tạo tài khoản mới"
        case .lessonStarted: return "Bắt đầu bài học"
        case .lessonCompleted: return "Hoàn thành bài học"
        case .quizCompleted: return "Hoàn thành bài Quiz (Đạt)"
        case .quizFailed: return "Chưa đạt bài Quiz (<60%)"
        case .streakAtRisk: return "Có nguy cơ đứt Streak"
        case .streakBroken: return "Bị đứt chuỗi Streak"
        case .vocabularyDue: return "Đến hạn ôn từ vựng (SRS)"
        case .userInactive: return "Không hoạt động (>3 ngày)"
        case .subscriptionExpiring: return "Gói tài khoản sắp hết hạn"
        }
    }
    
    public var icon: String {
        switch self {
        case .userRegistered: return "person.badge.plus"
        case .lessonStarted: return "book.fill"
        case .lessonCompleted: return "checkmark.seal.fill"
        case .quizCompleted: return "star.fill"
        case .quizFailed: return "exclamationmark.triangle.fill"
        case .streakAtRisk: return "flame.fill"
        case .streakBroken: return "flame.slash"
        case .vocabularyDue: return "brain.head.profile"
        case .userInactive: return "moon.zzz.fill"
        case .subscriptionExpiring: return "clock.badge.exclamationmark"
        }
    }
}

/// Rich payload structure associated with an emitted event.
public struct AppEvent: Identifiable, Codable {
    public var id: String
    public var type: AppEventType
    public var userId: String
    public var userName: String
    public var timestamp: Date
    public var properties: [String: String]
    
    public init(
        id: String = "evt_\(UUID().uuidString.prefix(8).lowercased())",
        type: AppEventType,
        userId: String,
        userName: String = "Học viên",
        timestamp: Date = Date(),
        properties: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.userName = userName
        self.timestamp = timestamp
        self.properties = properties
    }
    
    // Convenience property getters
    public var quizScore: Int? {
        if let scoreStr = properties["quiz_score"], let score = Int(scoreStr) {
            return score
        }
        return nil
    }
    
    public var streakDays: Int? {
        if let sStr = properties["streak_days"], let s = Int(sStr) {
            return s
        }
        return nil
    }
    
    public var lessonTitle: String? {
        return properties["lesson_title"] ?? properties["last_lesson"]
    }
    
    public var vocabularyCount: Int? {
        if let countStr = properties["vocabulary_count"], let c = Int(countStr) {
            return c
        }
        return nil
    }
    
    public var inactiveDays: Int? {
        if let daysStr = properties["inactive_days"], let d = Int(daysStr) {
            return d
        }
        return nil
    }
}
