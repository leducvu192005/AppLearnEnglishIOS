//
//  QuestionView.swift
//  AppLearnEnglish
//

import SwiftUI

struct QuestionView: View {
    let quiz: Quiz
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Question text
            Text(quiz.question)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(minHeight: 80)
            
            // Audio button for listening quiz
            if quiz.type == "listening" {
                Button(action: {
                    // Play pronunciation of the correct answer
                    AudioService.shared.playPronunciation(word: quiz.correctAnswer, audioUrlString: quiz.audioUrl)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Nghe phát âm")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.pastelSky)
                    .cornerRadius(18)
                }
                .padding(.bottom, 10)
            }
            
            // Answer Options list
            VStack(spacing: 12) {
                ForEach(quiz.answers, id: \.self) { answer in
                    let isSelected = viewModel.selectedAnswer == answer
                    let isCorrectAnswer = answer == quiz.correctAnswer
                    
                    Button(action: {
                        viewModel.selectAnswer(answer)
                    }) {
                        HStack {
                            Text(answer)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            
                            Spacer()
                            
                            // Visual Feedback icon
                            if viewModel.isAnswerChecked {
                                if isCorrectAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primaryMint)
                                } else if isSelected {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.primaryCoral)
                                }
                            } else if isSelected {
                                Circle()
                                    .fill(AppTheme.primaryMint)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    getOptionBorderColor(answer: answer, isSelected: isSelected, isCorrectAnswer: isCorrectAnswer),
                                    lineWidth: isSelected || (viewModel.isAnswerChecked && isCorrectAnswer) ? 2.5 : 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.isAnswerChecked)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Determine the border color based on the validation status of the choice
    private func getOptionBorderColor(answer: String, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if viewModel.isAnswerChecked {
            if isCorrectAnswer {
                return AppTheme.primaryMint // Green outline for correct option
            } else if isSelected {
                return AppTheme.primaryCoral // Red outline for selected wrong option
            }
            return Color.black.opacity(0.06)
        } else {
            return isSelected ? AppTheme.primaryMint : Color.black.opacity(0.06)
        }
    }
}

#Preview {
    QuestionView(
        quiz: Quiz(id: "q1", topicId: "travel", question: "Nghĩa của từ 'airport' là gì?", answers: ["Máy bay", "Sân bay", "Khách sạn", "Hộ chiếu"], correctAnswer: "Sân bay", type: "multiple_choice", audioUrl: nil),
        viewModel: QuizViewModel()
    )
    .padding()
    .background(AppTheme.bgGradientStart)
}
