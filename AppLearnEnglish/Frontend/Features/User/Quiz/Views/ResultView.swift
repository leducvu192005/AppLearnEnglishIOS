//
//  ResultView.swift
//  AppLearnEnglish
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: QuizViewModel
    let onFinish: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header congratulation
                VStack(spacing: 8) {
                    Text("🎓 Kết Quả Quiz")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryMint.opacity(0.15))
                        .cornerRadius(8)
                    
                    Text("Chúc mừng bạn!")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                }
                .padding(.top, 20)
                
                // Score circular progress widget
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.04), lineWidth: 16)
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(
                            AppTheme.primaryMint,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(viewModel.score)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        Text("/ \(viewModel.quizzes.count) đúng")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.vertical, 10)
                
                // Stats Card Grid
                HStack(spacing: 16) {
                    // XP Gained Card
                    VStack(spacing: 6) {
                        Text("⚡️")
                            .font(.system(size: 22))
                        Text("+\(viewModel.score * 5) XP")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryMint)
                        Text("Kinh nghiệm")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cuteCardStyle()
                    
                    // Mistakes Card
                    VStack(spacing: 6) {
                        Text("❌")
                            .font(.system(size: 22))
                        Text("\(viewModel.wrongQuizzes.count) lỗi")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryCoral)
                        Text("Câu sai")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cuteCardStyle()
                }
                .padding(.horizontal)
                
                // MARK: - Review mistakes section if any
                if !viewModel.wrongQuizzes.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ôn lại câu trả lời sai")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.wrongQuizzes) { quiz in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(quiz.question)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textDark)
                                    
                                    HStack {
                                        Text("Đáp án đúng:")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(AppTheme.textMuted)
                                        Text(quiz.correctAnswer)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.primaryMint)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Finish button
                PrimaryCuteButton(
                    title: "Hoàn thành 🚀",
                    iconName: "checkmark.circle.fill",
                    backgroundColor: AppTheme.primaryMint,
                    shadowColor: Color(hex: "27AE60")
                ) {
                    onFinish()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(AppTheme.bgGradientStart)
    }
}

#Preview {
    ResultView(viewModel: QuizViewModel()) {}
}
