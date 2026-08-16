//
//  WordDetailView.swift
//  AppLearnEnglish
//

import SwiftUI

struct WordDetailView: View {
    let word: VocabularyWord
    @State var isLearned: Bool
    @State var isFavorite: Bool
    @ObservedObject var viewModel: VocabularyViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var detailViewModel: WordDetailViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var showingResult = false
    @State private var score = 0
    @State private var showingSaveSheet = false
    
    // Inject the word model into detailViewModel on initialization
    init(word: VocabularyWord, isLearned: Bool, isFavorite: Bool, viewModel: VocabularyViewModel) {
        self.word = word
        self._isLearned = State(initialValue: isLearned)
        self._isFavorite = State(initialValue: isFavorite)
        self.viewModel = viewModel
        self._detailViewModel = StateObject(wrappedValue: WordDetailViewModel(word: word))
    }
    
    var body: some View {
        ZStack {
            // Soft Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        
                        // MARK: - 1. MAIN FLASHCARD
                        SoftCard(padding: 28) {
                            VStack(spacing: 20) {
                                // Mascot companion
                                OwlMascot(state: isLearned ? .celebrating : .thinking, size: 100)
                                    .padding(.bottom, 4)
                                
                                // Word Name
                                Text(word.word)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.darkNavy)
                                    .multilineTextAlignment(.center)
                                
                                // Phonetic IPA
                                Text(word.phonetic)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                // Part of Speech Badge (simulated/extracted or defaults to Level)
                                Text(word.level)
                                    .fontCaption()
                                    .foregroundColor(DesignSystem.Colors.accentPink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.Colors.accentPink.opacity(0.12))
                                    .cornerRadius(8)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                // Translation
                                VStack(spacing: 6) {
                                    Text("Nghĩa tiếng Việt")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .textCase(.uppercase)
                                    Text(word.meaning)
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                        .multilineTextAlignment(.center)
                                }
                                
                                // Example Sentence
                                VStack(spacing: 6) {
                                    Text("Ví dụ minh họa")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .textCase(.uppercase)
                                    Text("\"\(word.example)\"")
                                        .fontBody()
                                        .italic()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                                .padding(.top, 4)
                                
                                HStack(spacing: 12) {
                                    // Audio Player Button
                                    Button(action: {
                                        detailViewModel.playAudio()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: detailViewModel.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                            Text("Nghe phát âm")
                                        }
                                        .fontCaption()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(DesignSystem.Colors.primaryLight)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Save Button
                                    Button(action: {
                                        showingSaveSheet = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "folder.badge.plus")
                                            Text("Lưu vào bộ từ")
                                        }
                                        .fontCaption()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(DesignSystem.Colors.primaryLight)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - 2. PRONUNCIATION PRACTICE CARD
                        SoftCard(padding: 20) {
                            VStack(spacing: 14) {
                                HStack(spacing: 6) {
                                    Text("🎙️")
                                    Text("Luyện phát âm từ này")
                                        .fontSubheading()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                    Spacer()
                                }
                                
                                if speechRecognizer.isRecording {
                                    VStack(spacing: 12) {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 8, height: 8)
                                            Text("Đang ghi âm... Hãy nói từ này")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.red)
                                        }
                                        
                                        Text(speechRecognizer.transcript.isEmpty ? "..." : "\"\(speechRecognizer.transcript)\"")
                                            .fontHeading()
                                            .foregroundColor(DesignSystem.Colors.darkNavy)
                                            .multilineTextAlignment(.center)
                                    }
                                } else if showingResult {
                                    VStack(spacing: 12) {
                                        HStack(spacing: 8) {
                                            Text("Độ chính xác: \(score)%")
                                                .fontCaption()
                                                .foregroundColor(score >= 80 ? DesignSystem.Colors.success : (score >= 50 ? DesignSystem.Colors.warning : .red))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background((score >= 80 ? DesignSystem.Colors.success : (score >= 50 ? DesignSystem.Colors.warning : .red)).opacity(0.12))
                                                .cornerRadius(8)
                                        }
                                        
                                        Text(score >= 80 ? "Tuyệt vời! Bạn phát âm rất chuẩn 🌟" : (score >= 50 ? "Khá tốt! Phát âm gần đúng rồi 👍" : "Hãy nghe lại và thử lại nhé 💪"))
                                            .fontBodySecondary()
                                            .foregroundColor(score >= 80 ? DesignSystem.Colors.success : (score >= 50 ? DesignSystem.Colors.warning : .red))
                                            .multilineTextAlignment(.center)
                                    }
                                } else {
                                    Text("Nhấn nút micro bên dưới để tập nói từ này!")
                                        .fontBodySecondary()
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                
                                // Microphone Action Button
                                Button(action: {
                                    if speechRecognizer.isRecording {
                                        speechRecognizer.stopRecording()
                                        score = speechRecognizer.calculateAccuracy(target: word.word, spoken: speechRecognizer.transcript)
                                        showingResult = true
                                    } else {
                                        showingResult = false
                                        speechRecognizer.startRecording()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(speechRecognizer.isRecording ? Color.red.opacity(0.12) : DesignSystem.Colors.primary.opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(speechRecognizer.isRecording ? Color.red : DesignSystem.Colors.darkNavy)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
                
                // MARK: - 3. FOOTER INTERACTIVE ACTIONS
                HStack(spacing: 16) {
                    // Favorite Heart Button
                    Button(action: {
                        isFavorite.toggle()
                        Task {
                            await viewModel.toggleFavorite(wordId: word.id)
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isFavorite ? DesignSystem.Colors.accentPink.opacity(0.15) : DesignSystem.Colors.card)
                                .frame(width: 56, height: 56)
                                .designShadow()
                            
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(isFavorite ? DesignSystem.Colors.accentPink : DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Don't know / I know actions
                    SecondaryButton(title: "Chưa thuộc") {
                        dismiss()
                    }
                    .frame(maxWidth: 130)
                    
                    PrimaryButton(title: isLearned ? "Đã thuộc ✓" : "Đã thuộc 🌟") {
                        if !isLearned {
                            isLearned = true
                            Task {
                                await viewModel.markAsLearned(wordId: word.id)
                            }
                        }
                        dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Học Từ Vựng")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveWordBottomSheet(word: word, viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    NavigationStack {
        WordDetailView(
            word: VocabularyWord(id: "tr1", word: "airport", phonetic: "/ˈeəpɔːt/", meaning: "sân bay", example: "I will meet you at the airport.", image: "", audio: "", topicId: "travel", level: "Beginner"),
            isLearned: false,
            isFavorite: false,
            viewModel: VocabularyViewModel()
        )
    }
}
