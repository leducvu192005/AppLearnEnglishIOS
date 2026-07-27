//
//  TopicDetailView.swift
//  AppLearnEnglish
//

import SwiftUI

struct TopicDetailView: View {
    let topic: Topic
    @ObservedObject var viewModel: VocabularyViewModel
    
    // Computed property to calculate learned count
    private var learnedCount: Int {
        viewModel.words.filter { viewModel.learnedWordIds.contains($0.id) }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Topic Summary Bar
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.name)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        
                        Text(topic.description)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    Spacer()
                    
                    // Cute Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.black.opacity(0.04), lineWidth: 5)
                            .frame(width: 52, height: 52)
                        
                        Circle()
                            .stroke(AppTheme.primaryMint, lineWidth: 5)
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                            .help("Độ hoàn thành")
                        
                        Text("\(learnedCount)/\(viewModel.words.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryMint)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.top, 12)
            }
            
            // Word List
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(AppTheme.primaryMint)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.words) { word in
                            NavigationLink(
                                destination: WordDetailView(
                                    word: word,
                                    isLearned: viewModel.learnedWordIds.contains(word.id),
                                    isFavorite: viewModel.favoriteWordIds.contains(word.id),
                                    viewModel: viewModel
                                )
                            ) {
                                WordCard(
                                    word: word,
                                    isLearned: viewModel.learnedWordIds.contains(word.id)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadWords(for: topic.id)
                await viewModel.loadUserPreferences()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(
            topic: Topic(id: "travel", name: "Du lịch", description: "Các từ vựng hữu dụng tại sân bay, khách sạn", image: "airplane", totalWords: 20),
            viewModel: VocabularyViewModel()
        )
    }
}
