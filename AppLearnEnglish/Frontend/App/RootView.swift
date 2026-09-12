//
//  RootView.swift
//  AppLearnEnglish
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        Group {
            if sessionManager.isLoading {
                // MARK: - Loading State (Cute owl spinner)
                VStack(spacing: 16) {
                    Text("🦉")
                        .font(.system(size: 72))
                        .rotationEffect(.degrees(sessionManager.isLoading ? 360 : 0))
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: sessionManager.isLoading
                        )
                    
                    Text("Đang tải dữ liệu học tập...")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.bgGradientStart)
                
            } else if sessionManager.isLoggedIn {
                // MARK: - Authenticated States
                if sessionManager.userRole == "admin" && !sessionManager.isPreviewingAsStudent {
                    AdminHomeView()
                        .transition(.slide.combined(with: .opacity))
                } else {
                    UserTabView()
                        .transition(.slide.combined(with: .opacity))
                }
            } else {
                // MARK: - Unauthenticated State
                OnboardingView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: sessionManager.isLoggedIn)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: sessionManager.isLoading)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: sessionManager.userRole)
    }
}

#Preview {
    RootView()
        .environmentObject(SessionManager.shared)
}
