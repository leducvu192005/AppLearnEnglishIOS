//
//  Quiz.swift
//  AppLearnEnglish
//

import Foundation

struct Quiz: Codable, Identifiable, Hashable {
    let id: String
    let topicId: String
    let question: String
    let answers: [String]
    let correctAnswer: String
    let type: String // "multiple_choice", "fill_blank", "listening"
    let audioUrl: String? // Used for listening quizzes
}
