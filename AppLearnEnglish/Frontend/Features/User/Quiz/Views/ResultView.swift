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
            VStack(spacing: DesignSystem.Spacing.large) {
                // Mascot Celebration
                OwlMascot(state: .celebratingTrophy, size: 110)
                    .padding(.top, 24)
                
                // Header congratulation
                VStack(spacing: 8) {
                    Text("🎓 Kết Quả Quiz")
                        .fontCaption()
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.primaryLight)
                        .cornerRadius(8)
                    
                    Text("Chúc mừng bạn!")
                        .fontTitle()
                        .foregroundColor(DesignSystem.Colors.darkNavy)
                }
                
                // Score circular progress widget
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.primaryLight, lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .stroke(
                            DesignSystem.Colors.primary,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(viewModel.score)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                        Text("/ \(viewModel.quizzes.count) đúng")
                            .fontCaption()
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                
                // Stats Card Grid
                HStack(spacing: 16) {
                    // XP Gained Card
                    SoftCard(padding: 16) {
                        VStack(spacing: 6) {
                            Text("⚡️")
                                .font(.system(size: 20))
                            Text("+\(viewModel.score * 5) XP")
                                .fontSubheading()
                                .foregroundColor(DesignSystem.Colors.success)
                            Text("Kinh nghiệm")
                                .fontCaption()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Mistakes Card
                    SoftCard(padding: 16) {
                        VStack(spacing: 6) {
                            Text("❌")
                                .font(.system(size: 20))
                            Text("\(viewModel.wrongQuizzes.count) lỗi")
                                .fontSubheading()
                                .foregroundColor(DesignSystem.Colors.accentPink)
                            Text("Câu sai")
                                .fontCaption()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Review mistakes section if any
                if !viewModel.wrongQuizzes.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(
                            title: "Ôn lại câu trả lời sai",
                            subtitle: "Học từ những lỗi sai để cải thiện kỹ năng"
                        )
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.wrongQuizzes) { quiz in
                                SoftCard(padding: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(quiz.question)
                                            .fontSubheading()
                                            .foregroundColor(DesignSystem.Colors.darkNavy)
                                        
                                        HStack(spacing: 4) {
                                            Text("Đáp án đúng:")
                                                .fontBodySecondary()
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                            Text(quiz.correctAnswer)
                                                .fontBody()
                                                .foregroundColor(DesignSystem.Colors.success)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Finish button
                PrimaryButton(title: "Hoàn thành 🚀", iconName: "checkmark.circle.fill") {
                    onFinish()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

#Preview {
    ResultView(viewModel: QuizViewModel()) {}
}
