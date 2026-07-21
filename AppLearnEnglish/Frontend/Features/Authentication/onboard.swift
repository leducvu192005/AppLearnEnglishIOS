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
                // Soft Background
                LinearGradient(
                    colors: [AppTheme.bgGradientStart, AppTheme.bgGradientEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Cute Hero Mascot Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white)
                            .frame(width: 200, height: 200)
                            .shadow(color: AppTheme.primaryMint.opacity(0.25), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 12) {
                            Text("🐥💬🇬🇧")
                                .font(.system(size: 64))
                            
                            Text("English AI")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.primaryMint)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text("Học Tiếng Anh\nDễ Dàng & Thú Vị!")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppTheme.textDark)
                        
                        Text("Luyện Nói 1-1 cùng AI Tutor, nâng trình từ vựng, luyện nghe & viết siêu hiệu quả mỗi ngày.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        PrimaryCuteButton(
                            title: "Bắt đầu ngay ✨",
                            iconName: "sparkles",
                            backgroundColor: AppTheme.primaryMint,
                            shadowColor: Color(hex: "27AE60")
                        ) {
                            navigateToAuth = true
                        }
                        
                        Button(action: {
                            navigateToAuth = true
                        }) {
                            HStack(spacing: 4) {
                                Text("Đã có tài khoản?")
                                    .foregroundColor(AppTheme.textMuted)
                                Text("Đăng nhập")
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.primaryCoral)
                            }
                            .font(.system(size: 15, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
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
