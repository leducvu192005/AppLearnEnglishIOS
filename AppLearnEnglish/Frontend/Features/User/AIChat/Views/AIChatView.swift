//
//  AIChatView.swift
//  AppLearnEnglish
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hội thoại AI 🦉")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text("Luyện nói và chat tiếng Anh 1-1 cùng Owl Tutor")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                Spacer()
                
                // Clear chat button
                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryCoral)
                        .padding(10)
                        .background(AppTheme.primaryCoral.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            
            // Message log list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<viewModel.messages.count, id: \.self) { index in
                            let message = viewModel.messages[index]
                            let isUser = message.role == "user"
                            
                            HStack {
                                if isUser { Spacer() }
                                
                                Text(message.content)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .foregroundColor(isUser ? .white : AppTheme.textDark)
                                    .background(isUser ? AppTheme.primaryMint : Color.white)
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                                    .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
                                
                                if !isUser { Spacer() }
                            }
                            .id(index)
                        }
                        
                        // Typing/loading indicator
                        if viewModel.isLoading {
                            HStack {
                                HStack(spacing: 4) {
                                    Circle().fill(AppTheme.textMuted).frame(width: 6, height: 6)
                                    Circle().fill(AppTheme.textMuted).frame(width: 6, height: 6)
                                    Circle().fill(AppTheme.textMuted).frame(width: 6, height: 6)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                                
                                Spacer()
                            }
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, count in
                    if count > 0 {
                        withAnimation {
                            proxy.scrollTo(count - 1, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { _, loading in
                    if loading {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            .background(AppTheme.bgGradientStart)
            
            // Bottom Input Panel
            HStack(spacing: 12) {
                TextField("Nhập tin nhắn tiếng Anh...", text: $viewModel.inputText)
                    .font(.system(size: 15, design: .rounded))
                    .padding(14)
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(18)
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.primaryMint)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.primaryMint.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AIChatView()
}
