//
//  TopicDetailView.swift
//  AppLearnEnglish
//

import SwiftUI

struct TopicDetailView: View {
    let topic: Topic
    @ObservedObject var viewModel: VocabularyViewModel
    @State private var showAddWordSheet = false
    
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
                        
                        // IF custom topic -> Show a premium "Add Word" card button at the top
                        if topic.id.hasPrefix("custom_") {
                            Button(action: { showAddWordSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text("Thêm từ mới vào bộ")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AppTheme.primaryMint)
                                .cornerRadius(16)
                                .shadow(color: AppTheme.primaryMint.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            .padding(.bottom, 8)
                        }
                        
                        if viewModel.words.isEmpty {
                            VStack(spacing: 12) {
                                Text("📭")
                                    .font(.system(size: 36))
                                Text("Bộ từ vựng này đang trống.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        } else {
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
        .sheet(isPresented: $showAddWordSheet) {
            AddWordSheet(topicId: topic.id, viewModel: viewModel)
        }
    }
}

// MARK: - AddWordSheet

struct AddWordSheet: View {
    @Environment(\.dismiss) var dismiss
    let topicId: String
    @ObservedObject var viewModel: VocabularyViewModel
    
    @State private var word = ""
    @State private var phonetic = ""
    @State private var meaning = ""
    @State private var example = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Chi tiết từ vựng mới")) {
                    TextField("Từ vựng tiếng Anh (ví dụ: Diligent)", text: $word)
                    TextField("Phiên âm (ví dụ: /ˈdɪl.ɪ.dʒənt/)", text: $phonetic)
                    TextField("Nghĩa tiếng Việt (ví dụ: Chăm chỉ)", text: $meaning)
                    TextField("Ví dụ minh họa (câu mẫu)", text: $example)
                }
            }
            .navigationTitle("Thêm từ mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Thêm") {
                        if !word.isEmpty && !meaning.isEmpty {
                            viewModel.addCustomWord(
                                word: word,
                                phonetic: phonetic,
                                meaning: meaning,
                                example: example,
                                topicId: topicId
                            )
                            // Refresh vocabulary list
                            Task {
                                await viewModel.loadWords(for: topicId)
                            }
                            dismiss()
                        }
                    }
                    .disabled(word.isEmpty || meaning.isEmpty)
                }
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
