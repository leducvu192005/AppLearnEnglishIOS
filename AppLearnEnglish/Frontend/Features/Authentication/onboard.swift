//
//  onboard.swift
//  AppLearnEnglish
//

import SwiftUI

struct OnboardingView: View {
    @State private var navigateToAuth = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.large) {
                    Spacer()
                    
                    // Large brand illustration (Mascot)
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryLight)
                            .frame(width: 220, height: 220)
                            .designShadow()
                        
                        OwlMascot(state: .greeting, size: 180)
                    }
                    
                    // Brand Message
                    VStack(spacing: 12) {
                        Text("Học Tiếng Anh\nDễ Dàng & Thú Vị!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                        
                        Text("Luyện hội thoại 1-1 cùng AI Tutor, chinh phục từ vựng và tự tin giao tiếp tiếng Anh mỗi ngày.")
                            .fontBodySecondary()
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        PrimaryButton(
                            title: "Bắt đầu ngay ✨",
                            iconName: "sparkles"
                        ) {
                            navigateToAuth = true
                        }
                        
                        Button(action: {
                            navigateToAuth = true
                        }) {
                            HStack(spacing: 4) {
                                Text("Đã có tài khoản?")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text("Đăng nhập")
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .font(.system(size: 15, design: .rounded))
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthenticationView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
