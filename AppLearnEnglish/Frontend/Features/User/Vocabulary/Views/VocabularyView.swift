//
//  VocabularyView.swift
//  AppLearnEnglish
//

import SwiftUI

struct VocabularyView: View {
    @StateObject private var viewModel = VocabularyViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Section Title header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chủ Đề Học Từ Vựng")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text("Chọn một chủ đề bên dưới để bắt đầu học từ mới nhé!")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                if viewModel.isLoading && viewModel.topics.isEmpty {
                    VStack {
                        ProgressView()
                            .tint(AppTheme.primaryMint)
                        Text("Đang tải danh sách chủ đề...")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                } else {
                    // Topic Grid Layout
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.topics) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic, viewModel: viewModel)) {
                                TopicCard(topic: topic)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Từ vựng")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadUserPreferences()
            }
        }
    }
}

#Preview {
    NavigationStack {
        VocabularyView()
    }
}
