//
//  GrammarResult.swift
//  AppLearnEnglish
//

import Foundation

struct ChangeItem: Codable, Identifiable {
    var id: String {
        return "\(wrong)-\(correct)-\(reason)"
    }
    let wrong: String
    let correct: String
    let reason: String
}

struct GrammarResult: Codable {
    let original: String
    let corrected: String
    let explanation: String
    let changes: [ChangeItem]
}
