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
    
    @StateObject private var detailViewModel: WordDetailViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var showingResult = false
    @State private var score = 0
    
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
            LinearGradient(
                colors: [AppTheme.bgGradientStart, AppTheme.bgGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Content Scroll Container (prevents overflow on smaller devices)
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - 1. Word & Audio Header Card
                        VStack(spacing: 16) {
                            Text(word.word)
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            
                            Text(word.phonetic)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                            
                            // Audio Player Button
                            AudioButton(isPlaying: detailViewModel.isPlaying) {
                                detailViewModel.playAudio()
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .cuteCardStyle()
                        .padding(.horizontal, 20)
                        
                        // MARK: - 2. Meaning & Example Cards
                        VStack(spacing: 16) {
                            // Meaning card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("🏷")
                                    Text("Ý nghĩa")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                
                                Text(word.meaning)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textDark)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cuteCardStyle()
                            
                            // Example card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("📝")
                                    Text("Ví dụ minh họa")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                
                                Text("\"\(word.example)\"")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .italic()
                                    .foregroundColor(AppTheme.textDark)
                                    .lineLimit(3)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cuteCardStyle()
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - 3. Pronunciation Practice Card (Luyện Phát Âm 🎙️)
                        VStack(spacing: 14) {
                            HStack(spacing: 6) {
                                Text("🎙️")
                                Text("Luyện phát âm tiếng Anh")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                                Spacer()
                            }
                            
                            if speechRecognizer.isRecording {
                                // Recording voice visualizer mockup and live transcript
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .opacity(0.8)
                                        Text("Đang ghi âm... Hãy nói từ này")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text(speechRecognizer.transcript.isEmpty ? "..." : "\"\(speechRecognizer.transcript)\"")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textDark)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            } else if showingResult {
                                // Result accuracy score feedback cards
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Bạn vừa đọc:")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(AppTheme.textMuted)
                                        Text("\"\(speechRecognizer.transcript)\"")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textDark)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("Độ chính xác: \(score)%")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(score >= 80 ? Color(hex: "27AE60") : (score >= 50 ? Color.orange : Color.red))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background((score >= 80 ? Color(hex: "27AE60") : (score >= 50 ? Color.orange : Color.red)).opacity(0.12))
                                            .cornerRadius(10)
                                    }
                                    
                                    Text(score >= 80 ? "Tuyệt vời! Bạn phát âm rất chuẩn 🌟" : (score >= 50 ? "Khá tốt! Phát âm gần đúng rồi 👍" : "Hãy nghe lại loa và thử lại nhé 💪"))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(score >= 80 ? Color(hex: "27AE60") : (score >= 50 ? Color.orange : Color.red))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            } else {
                                // Prompt default label
                                Text("Nhấn nút micro bên dưới để thử phát âm từ này!")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Microphone Button
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
                                        .fill(speechRecognizer.isRecording ? Color.red.opacity(0.15) : AppTheme.primaryMint.opacity(0.15))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(speechRecognizer.isRecording ? Color.red : AppTheme.primaryMint)
                                }
                            }
                            .padding(.top, 4)
                            
                            if let err = speechRecognizer.errorMessage {
                                Text(err)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .cuteCardStyle()
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                
                // MARK: - 4. Footer Interactive Actions (Favorites & Done)
                HStack(spacing: 16) {
                    // Favorite Toggle Heart Button
                    Button(action: {
                        isFavorite.toggle()
                        Task {
                            await viewModel.toggleFavorite(wordId: word.id)
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isFavorite ? AppTheme.primaryCoral.opacity(0.15) : Color.white)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
                            
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isFavorite ? AppTheme.primaryCoral : AppTheme.textLight)
                        }
                    }
                    
                    // Checkmark Learned Button
                    PrimaryCuteButton(
                        title: isLearned ? "Đã thuộc từ này ✓" : "Đã thuộc từ này 🌟",
                        iconName: isLearned ? "checkmark.circle.fill" : "star.fill",
                        backgroundColor: isLearned ? Color(hex: "27AE60") : AppTheme.primaryMint,
                        shadowColor: isLearned ? Color(hex: "1E8449") : Color(hex: "2ECC71")
                    ) {
                        if !isLearned {
                            isLearned = true
                            Task {
                                await viewModel.markAsLearned(wordId: word.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(Color.white.opacity(0.01)) // Subtle alignment layer
            }
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Guarantee speech session stops when navigating back
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
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
