//
//  GrammarCheckerView.swift
//  AppLearnEnglish
//

import SwiftUI

struct GrammarCheckerView: View {
    @StateObject private var viewModel = GrammarCheckerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header Card
                SoftCard(padding: 16) {
                    HStack(spacing: 16) {
                        OwlMascot(state: .explaining, size: 68)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Grammar Checker AI")
                                .fontSubheading()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            Text("Phân tích lỗi sai và viết chuẩn tiếng Anh")
                                .fontBodySecondary()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Text Editor Input Card
                SoftCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Nhập văn bản tiếng Anh cần kiểm tra:")
                            .fontSubheading()
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                        
                        TextEditor(text: $viewModel.inputText)
                            .fontBody()
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                            .frame(height: 120)
                            .padding(12)
                            .background(DesignSystem.Colors.background)
                            .cornerRadius(14)
                            .disabled(viewModel.isLoading)
                        
                        // Display Error Messages if any
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 6) {
                                Text("⚠️")
                                Text(error)
                                    .fontCaption()
                                    .foregroundColor(DesignSystem.Colors.accentPink)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Action Button
                        PrimaryButton(
                            title: viewModel.isLoading ? "Owl Tutor is checking..." : "Kiểm tra ngữ pháp ✨",
                            iconName: "wand.and.stars"
                        ) {
                            viewModel.checkGrammar()
                        }
                        .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity((viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal)
                
                // Loading and Results Section
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(DesignSystem.Colors.primary)
                            .scaleEffect(1.2)
                        
                        Text("🦉 Owl Tutor đang phân tích lỗi...")
                            .fontBody()
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Kết quả sửa lỗi 📊")
                                .fontHeading()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    viewModel.clear()
                                }
                            }) {
                                Text("Làm mới")
                                    .fontCaption()
                                    .foregroundColor(DesignSystem.Colors.accentPink)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        SoftCard(padding: 20) {
                            GrammarResultView(result: result)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Sửa lỗi ngữ pháp")
    }
}

#Preview {
    NavigationStack {
        GrammarCheckerView()
    }
}
