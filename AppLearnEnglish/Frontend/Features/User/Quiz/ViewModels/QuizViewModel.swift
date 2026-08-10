//
//  QuizViewModel.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore
import Combine

class QuizViewModel: ObservableObject {
    @Published var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswer: String? = nil
    @Published var isAnswerChecked: Bool = false
    @Published var isCorrect: Bool = false
    @Published var score: Int = 0
    @Published var wrongQuizzes: [Quiz] = []
    @Published var showResult: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Current Question Helper
    var currentQuiz: Quiz? {
        guard currentQuestionIndex < quizzes.count else { return nil }
        return quizzes[currentQuestionIndex]
    }
    
    // MARK: - Load Quizzes (Firestore with Mock Fallback)
    @MainActor
    func loadQuizzes(for topicId: String) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let snapshot = try await db.collection("quizzes")
                .whereField("topicId", isEqualTo: topicId)
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                self.quizzes = mockQuizzes.filter { $0.topicId == topicId }
            } else {
                self.quizzes = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Quiz.self)
                }
            }
            
            self.resetQuiz()
            self.isLoading = false
        } catch {
            print("Firestore fetch quizzes failed: \(error.localizedDescription). Using Mock data.")
            self.quizzes = mockQuizzes.filter { $0.topicId == topicId }
            self.resetQuiz()
            self.isLoading = false
        }
    }
    
    // MARK: - Quiz Session Control
    func selectAnswer(_ answer: String) {
        guard !isAnswerChecked else { return }
        selectedAnswer = answer
    }
    
    func checkAnswer() {
        guard let quiz = currentQuiz, let answer = selectedAnswer, !isAnswerChecked else { return }
        
        isAnswerChecked = true
        isCorrect = (answer == quiz.correctAnswer)
        
        if isCorrect {
            score += 1
        } else {
            wrongQuizzes.append(quiz)
        }
    }
    
    func nextQuestion() {
        selectedAnswer = nil
        isAnswerChecked = false
        isCorrect = false
        
        if currentQuestionIndex + 1 < quizzes.count {
            currentQuestionIndex += 1
        } else {
            showResult = true
            Task {
                await saveXPToFirestore()
            }
        }
    }
    
    func resetQuiz() {
        currentQuestionIndex = 0
        selectedAnswer = nil
        isAnswerChecked = false
        isCorrect = false
        score = 0
        wrongQuizzes.removeAll()
        showResult = false
    }
    
    // MARK: - Save XP earned to Firestore profile
    @MainActor
    private func saveXPToFirestore() async {
        guard let uid = userId else { return }
        let xpGained = score * 5 // 5 XP per correct answer
        
        do {
            try await UserService.shared.updateProgressAndStreak(uid: uid, xp: xpGained)
            // Reload user progress stats in the session
            await SessionManager.shared.reloadUserProfile()
        } catch {
            print("Error updating quiz XP and streak in Firestore: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Mock Quizzes Definition
    
    private let mockQuizzes = [
        Quiz(id: "q1", topicId: "travel", question: "Nghĩa của từ 'airport' là gì?", answers: ["Máy bay", "Sân bay", "Khách sạn", "Hộ chiếu"], correctAnswer: "Sân bay", type: "multiple_choice", audioUrl: nil),
        Quiz(id: "q2", topicId: "travel", question: "I arrive at the ______ two hours before my flight.", answers: ["hotel", "reservation", "airport", "souvenir"], correctAnswer: "airport", type: "fill_blank", audioUrl: nil),
        Quiz(id: "q3", topicId: "travel", question: "Nghe phát âm và chọn đúng từ:", answers: ["passport", "departure", "vacation", "luggage"], correctAnswer: "passport", type: "listening", audioUrl: ""),
        Quiz(id: "q4", topicId: "travel", question: "Nghĩa của từ 'reservation' là gì?", answers: ["Sự khởi hành", "Hành lý", "Sự đặt chỗ trước", "Vé tàu"], correctAnswer: "Sự đặt chỗ trước", type: "multiple_choice", audioUrl: nil),
        Quiz(id: "q5", topicId: "travel", question: "Please show your ______ at the border control.", answers: ["destination", "passenger", "ticket", "passport"], correctAnswer: "passport", type: "fill_blank", audioUrl: nil)
    ]
}
