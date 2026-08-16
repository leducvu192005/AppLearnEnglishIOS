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
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(DesignSystem.Colors.primary)
                    Text("Đang chuẩn bị câu hỏi...")
                        .fontBodySecondary()
                        .foregroundColor(DesignSystem.Colors.secondaryText)
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
                        .fontSubheading()
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Button("Quay lại") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            } else {
                VStack(spacing: 0) {
                    
                    // MARK: - Header Progress Bar
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.darkNavy)
                            }
                            
                            Spacer()
                            
                            Text("Chủ đề: \(topicName)")
                                .fontSubheading()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            
                            Spacer()
                            
                            Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.quizzes.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(DesignSystem.Colors.primaryLight)
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(
                                        width: geo.size.width * CGFloat(Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.quizzes.count)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                    .background(DesignSystem.Colors.card)
                    .designShadow()
                    
                    // MARK: - Active Question View
                    if let currentQuiz = viewModel.currentQuiz {
                        QuestionView(quiz: currentQuiz, viewModel: viewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            .id(viewModel.currentQuestionIndex)
                    }
                    
                    Spacer()
                    
                    // MARK: - Bottom Action Validation Bar
                    VStack {
                        if !viewModel.isAnswerChecked {
                            // Check Answer Button
                            PrimaryButton(
                                title: "Kiểm tra đáp án 🔍"
                            ) {
                                viewModel.checkAnswer()
                            }
                            .disabled(viewModel.selectedAnswer == nil)
                            .opacity(viewModel.selectedAnswer == nil ? 0.6 : 1.0)
                        } else {
                            // Correct/Incorrect Feedback Banner Card
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(viewModel.isCorrect ? DesignSystem.Colors.success.opacity(0.18) : DesignSystem.Colors.accentPink.opacity(0.18))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: viewModel.isCorrect ? "checkmark" : "xmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(viewModel.isCorrect ? DesignSystem.Colors.success : DesignSystem.Colors.accentPink)
                                    }
                                    
                                    Text(viewModel.isCorrect ? "Tuyệt vời! Chính xác rồi 🎉" : "Rất tiếc! Chưa chính xác 😢")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(viewModel.isCorrect ? DesignSystem.Colors.success : DesignSystem.Colors.accentPink)
                                    
                                    Spacer()
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.nextQuestion()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text(viewModel.currentQuestionIndex + 1 == viewModel.quizzes.count ? "Xem kết quả 🏁" : "Câu tiếp theo ➔")
                                            .fontSubheading()
                                    }
                                    .foregroundColor(DesignSystem.Colors.darkNavy)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.isCorrect ? DesignSystem.Colors.success : DesignSystem.Colors.accentPink)
                                    .cornerRadius(DesignSystem.Radius.button)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(20)
                            .background(DesignSystem.Colors.card)
                            .cornerRadius(24)
                            .designShadow()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadQuizzes(for: topicId, topicName: topicName)
            }
        }
    }
}

#Preview {
    QuizView(topicId: "travel", topicName: "Du lịch")
}
