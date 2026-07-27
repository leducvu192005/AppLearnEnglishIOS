//
//  AIChatViewModel.swift
//  AppLearnEnglish
//

import Foundation
import Combine

class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessageDTO] = [
        ChatMessageDTO(role: "model", content: "Hello! I am Owl Tutor 🦉. Let's practice English! How are you feeling today?")
    ]
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let aiService = AIService.shared
    
    // MARK: - Send message to FastAPI AI
    @MainActor
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Append user message
        let userMessage = ChatMessageDTO(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        do {
            let reply = try await aiService.sendChatMessage(chatHistory: messages)
            
            // Append assistant reply
            let assistantMessage = ChatMessageDTO(role: "model", content: reply)
            messages.append(assistantMessage)
            isLoading = false
        } catch {
            print("AI Chat connection failed: \(error.localizedDescription)")
            // Provide a localized explanation and custom tutor fallback
            let fallbackReply = "Excuse me, I'm having trouble connecting to my server right now. Could you make sure uvicorn is running on port 8000?"
            messages.append(ChatMessageDTO(role: "model", content: fallbackReply))
            isLoading = false
        }
    }
    
    func clearChat() {
        messages = [
            ChatMessageDTO(role: "model", content: "Hello! I am Owl Tutor 🦉. Let's practice English! How are you feeling today?")
        ]
        inputText = ""
    }
}
