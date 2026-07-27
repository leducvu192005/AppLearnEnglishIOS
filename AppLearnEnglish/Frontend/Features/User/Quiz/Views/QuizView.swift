//
//  QuizView.swift
//  AppLearnEnglish
//

import SwiftUI

struct QuizView: View {
    let topicId: String
    let topicName: String
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = QuizViewModel()
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.bgGradientStart.ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppTheme.primaryMint)
                    Text("Đang chuẩn bị câu hỏi...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
            } else if viewModel.showResult {
                ResultView(viewModel: viewModel) {
                    dismiss()
                }
            } else if viewModel.quizzes.isEmpty {
                VStack(spacing: 16) {
                    Text("📭")
                        .font(.system(size: 64))
                    Text("Không có câu hỏi nào.")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                    
                    Button("Quay lại") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryMint)
                    .fontWeight(.bold)
                }
            } else {
                VStack(spacing: 0) {
                    
                    // MARK: - Header Progress Bar
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                            }
                            
                            Spacer()
                            
                            Text("Chủ đề: \(topicName)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                            
                            Spacer()
                            
                            Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.quizzes.count)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.primaryMint)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.04))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.primaryMint)
                                    .frame(
                                        width: geo.size.width * CGFloat(Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.quizzes.count)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    .background(Color.white)
                    
                    // MARK: - Active Question View
                    if let currentQuiz = viewModel.currentQuiz {
                        QuestionView(quiz: currentQuiz, viewModel: viewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            .id(viewModel.currentQuestionIndex) // Triggers transitions when ID changes
                    }
                    
                    Spacer()
                    
                    // MARK: - Bottom Action Validation Bar
                    VStack {
                        if !viewModel.isAnswerChecked {
                            // Check Answer Button
                            PrimaryCuteButton(
                                title: "Kiểm tra đáp án 🔍",
                                backgroundColor: viewModel.selectedAnswer == nil ? Color.gray.opacity(0.3) : AppTheme.primaryMint,
                                shadowColor: viewModel.selectedAnswer == nil ? Color.clear : Color(hex: "27AE60")
                            ) {
                                viewModel.checkAnswer()
                            }
                            .disabled(viewModel.selectedAnswer == nil)
                        } else {
                            // Correct/Incorrect Feedback Banner
                            VStack(spacing: 12) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(viewModel.isCorrect ? AppTheme.primaryMint.opacity(0.2) : AppTheme.primaryCoral.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: viewModel.isCorrect ? "checkmark" : "xmark")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(viewModel.isCorrect ? AppTheme.primaryMint : AppTheme.primaryCoral)
                                    }
                                    
                                    Text(viewModel.isCorrect ? "Tuyệt vời! Chính xác rồi 🎉" : "Rất tiếc! Chưa chính xác 😢")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(viewModel.isCorrect ? AppTheme.primaryMint : AppTheme.primaryCoral)
                                    
                                    Spacer()
                                }
                                
                                PrimaryCuteButton(
                                    title: viewModel.currentQuestionIndex + 1 == viewModel.quizzes.count ? "Xem kết quả 🏁" : "Câu tiếp theo ➔",
                                    backgroundColor: viewModel.isCorrect ? AppTheme.primaryMint : AppTheme.primaryCoral,
                                    shadowColor: viewModel.isCorrect ? Color(hex: "27AE60") : Color(hex: "E74C3C")
                                ) {
                                    withAnimation {
                                        viewModel.nextQuestion()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -4)
                            .transition(.move(edge: .bottom))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadQuizzes(for: topicId)
            }
        }
    }
}

#Preview {
    QuizView(topicId: "travel", topicName: "Du lịch")
}
