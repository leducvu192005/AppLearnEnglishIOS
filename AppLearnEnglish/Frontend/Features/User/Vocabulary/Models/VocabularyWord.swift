//
//  VocabularyWord.swift
//  AppLearnEnglish
//

import Foundation

struct VocabularyWord: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let word: String
    let phonetic: String
    let meaning: String
    let example: String
    let image: String
    let audio: String
    let topicId: String
    let level: String // e.g. "Beginner", "Intermediate"
}
