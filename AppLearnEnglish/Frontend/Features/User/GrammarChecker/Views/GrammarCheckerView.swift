//
//  GrammarCheckerView.swift
//  AppLearnEnglish
//

import SwiftUI

struct GrammarCheckerView: View {
    @StateObject private var viewModel = GrammarCheckerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                HStack(spacing: 12) {
                    Text("🦉")
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grammar Checker AI")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        Text("Phân tích lỗi sai và viết chuẩn tiếng Anh")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    Spacer()
                }
                .padding()
                .cuteCardStyle()
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Text Editor Input Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nhập văn bản cần kiểm tra:")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    TextEditor(text: $viewModel.inputText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .frame(height: 130)
                        .padding(12)
                        .background(Color.black.opacity(0.03))
                        .cornerRadius(16)
                        .disabled(viewModel.isLoading)
                    
                    // Display Error Messages if any
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Text("⚠️")
                            Text(error)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryCoral)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Action Button
                    PrimaryCuteButton(
                        title: viewModel.isLoading ? "Owl Tutor is checking..." : "Kiểm tra ngữ pháp ✨",
                        iconName: "wand.and.stars",
                        backgroundColor: AppTheme.primaryMint,
                        shadowColor: Color(hex: "27AE60"),
                        isLoading: viewModel.isLoading
                    ) {
                        viewModel.checkGrammar()
                    }
                    .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
                .cuteCardStyle()
                .padding(.horizontal)
                
                // Loading and Results Section
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(AppTheme.primaryMint)
                            .scaleEffect(1.2)
                        
                        Text("🦉 Owl Tutor đang phân tích lỗi...")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Kết quả sửa lỗi 📊")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    viewModel.clear()
                                }
                            }) {
                                Text("Làm mới")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.primaryCoral)
                            }
                        }
                        .padding(.horizontal)
                        
                        GrammarResultView(result: result)
                            .padding(20)
                            .cuteCardStyle()
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Sửa lỗi ngữ pháp")
    }
}

#Preview {
    NavigationStack {
        GrammarCheckerView()
    }
}
