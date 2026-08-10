//
//  AIService.swift
//  AppLearnEnglish
//

import Foundation

// MARK: - Networking Models

struct ExplainWordResponse: Codable {
    let word: String
    let meaning: String
    let explanation: String
    let examples: [String]
}

struct CorrectionResponse: Codable {
    let original: String
    let corrected: String
    let explanation: String
}

struct ChatMessageDTO: Codable {
    let role: String // "user" or "model" / "assistant"
    let content: String
}

class AIService {
    static let shared = AIService()
    
    // Configured default FastAPI server address from AppConfig settings
    private let baseURLString = "\(AppConfig.apiURL)/api"
    
    private init() {}
    
    // MARK: - Explain Word
    func explainWord(word: String) async throws -> ExplainWordResponse {
        guard let url = URL(string: "\(baseURLString)/explain-word") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["word": word]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(ExplainWordResponse.self, from: data)
    }
    
    // MARK: - Generate Example Sentence based on Word & Level
    func generateExample(word: String, level: String) async throws -> String {
        guard let url = URL(string: "\(baseURLString)/example") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["word": word, "level": level]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["sentence"] as? String ?? ""
    }
    
    // MARK: - Correct Grammar
    func correctGrammar(text: String) async throws -> GrammarResult {
        guard let url = URL(string: "\(baseURLString)/correct") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(GrammarResult.self, from: data)
    }
    
    // MARK: - AI Chatbot Conversation with vocabulary RAG context
    func sendChatMessage(chatHistory: [ChatMessageDTO], vocabulary: [String]? = nil) async throws -> String {
        guard let url = URL(string: "\(baseURLString)/chat") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode chat messages history list and optionally vocabulary
        let encoder = JSONEncoder()
        var requestBody: [String: Any] = [
            "messages": try JSONSerialization.jsonObject(with: encoder.encode(chatHistory))
        ]
        
        if let vocabulary = vocabulary {
            requestBody["vocabulary"] = vocabulary
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["reply"] as? String ?? "No reply"
    }
}
