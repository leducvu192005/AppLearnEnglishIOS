//
//  Topic.swift
//  AppLearnEnglish
//

import Foundation

struct Topic: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let image: String // Resource image or system icon name
    let totalWords: Int
}
