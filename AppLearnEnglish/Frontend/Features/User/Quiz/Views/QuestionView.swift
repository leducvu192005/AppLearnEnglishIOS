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
            // Owl mascot companion posing the question
            OwlMascot(state: viewModel.isAnswerChecked ? (viewModel.isCorrect ? .celebrating : .encouraging) : .thinking, size: 90)
                .padding(.top, 10)
            
            // Question text
            Text(quiz.question)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.darkNavy)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .frame(minHeight: 60)
            
            // Audio button for listening quiz
            if quiz.type == "listening" {
                Button(action: {
                    // Play pronunciation of the correct answer
                    AudioService.shared.playPronunciation(word: quiz.correctAnswer, audioUrlString: quiz.audioUrl)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Nghe phát âm")
                            .fontCaption()
                    }
                    .foregroundColor(DesignSystem.Colors.darkNavy)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.primaryLight)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
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
                                .fontBody()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            
                            Spacer()
                            
                            // Visual Feedback icon
                            if viewModel.isAnswerChecked {
                                if isCorrectAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(.system(size: 20))
                                } else if isSelected {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.accentPink)
                                        .font(.system(size: 20))
                                }
                            } else if isSelected {
                                Circle()
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(getOptionBgColor(answer: answer, isSelected: isSelected, isCorrectAnswer: isCorrectAnswer))
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
            .padding(.horizontal, 20)
        }
    }
    
    // Determine background color based on checking status
    private func getOptionBgColor(answer: String, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if viewModel.isAnswerChecked {
            if isCorrectAnswer {
                return DesignSystem.Colors.success.opacity(0.12)
            } else if isSelected {
                return DesignSystem.Colors.accentPink.opacity(0.12)
            }
        }
        return DesignSystem.Colors.card
    }
    
    // Determine the border color based on the validation status of the choice
    private func getOptionBorderColor(answer: String, isSelected: Bool, isCorrectAnswer: Bool) -> Color {
        if viewModel.isAnswerChecked {
            if isCorrectAnswer {
                return DesignSystem.Colors.success
            } else if isSelected {
                return DesignSystem.Colors.accentPink
            }
            return Color.black.opacity(0.04)
        } else {
            return isSelected ? DesignSystem.Colors.primary : Color.black.opacity(0.04)
        }
    }
}

#Preview {
    QuestionView(
        quiz: Quiz(id: "q1", topicId: "travel", question: "Nghĩa của từ 'airport' là gì?", answers: ["Máy bay", "Sân bay", "Khách sạn", "Hộ chiếu"], correctAnswer: "Sân bay", type: "multiple_choice", audioUrl: nil),
        viewModel: QuizViewModel()
    )
    .padding()
    .background(DesignSystem.Colors.background)
}
