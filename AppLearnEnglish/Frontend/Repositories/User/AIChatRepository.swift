//
//  AIChatRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol AIChatRepositoryProtocol {
    func sendChatMessage(chatHistory: [ChatMessageDTO], vocabulary: [String]?) async throws -> String
}

final class AIChatRepository: AIChatRepositoryProtocol {
    private let aiService: AIService
    
    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }
    
    func sendChatMessage(chatHistory: [ChatMessageDTO], vocabulary: [String]?) async throws -> String {
        try await aiService.sendChatMessage(chatHistory: chatHistory, vocabulary: vocabulary)
    }
}
