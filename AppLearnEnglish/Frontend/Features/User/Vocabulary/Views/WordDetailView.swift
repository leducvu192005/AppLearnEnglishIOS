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
            
            VStack(spacing: 24) {
                Spacer()
                
                // MARK: - Word & Audio Header Card
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
                .padding(.vertical, 30)
                .cuteCardStyle()
                .padding(.horizontal, 20)
                
                // MARK: - Meaning & Example Cards
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
                
                Spacer()
                
                // MARK: - Footer Interactive Actions
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
            }
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
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
