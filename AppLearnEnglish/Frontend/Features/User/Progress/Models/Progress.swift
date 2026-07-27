//
//  Progress.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

struct ProgressModel: Codable, Equatable {
    var totalWords: Int
    var xp: Int
    var level: Int
    var streak: Int
    var dailyGoal: Int
    var lastStudyDate: Date?
    
    static let defaultValue = ProgressModel(
        totalWords: 0,
        xp: 0,
        level: 1,
        streak: 0,
        dailyGoal: 20,
        lastStudyDate: nil
    )
}
