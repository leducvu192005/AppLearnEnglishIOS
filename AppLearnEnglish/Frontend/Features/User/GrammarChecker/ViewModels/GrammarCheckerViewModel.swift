//
//  GrammarCheckerViewModel.swift
//  AppLearnEnglish
//

import Foundation
import Combine

@MainActor
class GrammarCheckerViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var result: GrammarResult? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let aiService = AIService.shared
    
    /// Triggers grammar correction API checks on the current input text.
    func checkGrammar() {
        let textToCheck = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !textToCheck.isEmpty else {
            self.errorMessage = "Vui lòng nhập văn bản tiếng Anh cần kiểm tra lỗi."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.result = nil
        
        Task {
            do {
                let checkResult = try await aiService.correctGrammar(text: textToCheck)
                self.result = checkResult
                self.isLoading = false
            } catch {
                print("Failed to run grammar check: \(error)")
                self.errorMessage = "Không thể kết nối với máy chủ AI sửa lỗi. Vui lòng kiểm tra kết nối mạng và thử lại."
                self.isLoading = false
            }
        }
    }
    
    /// Clears inputs and outputs for a fresh check.
    func clear() {
        self.inputText = ""
        self.result = nil
        self.errorMessage = nil
        self.isLoading = false
    }
}
