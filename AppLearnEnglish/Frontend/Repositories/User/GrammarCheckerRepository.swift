//
//  GrammarCheckerRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol GrammarCheckerRepositoryProtocol {
    func correctGrammar(text: String) async throws -> GrammarResult
}

final class GrammarCheckerRepository: GrammarCheckerRepositoryProtocol {
    private let aiService: AIService
    
    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }
    
    func correctGrammar(text: String) async throws -> GrammarResult {
        try await aiService.correctGrammar(text: text)
    }
}
