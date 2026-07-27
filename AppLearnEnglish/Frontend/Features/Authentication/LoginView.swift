//
//  LoginView.swift
//  AppLearnEnglish
//

import SwiftUI

struct LoginView: View {
    @Binding var emailText: String
    @Binding var passwordText: String
    var onForgotPassword: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @State private var localErrorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Message Display
            if let error = localErrorMessage ?? authService.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            
            // Email Input
            CustomTextField(
                title: "Email",
                placeholder: "nhap.email@example.com",
                iconName: "envelope.fill",
                iconTintColor: AppTheme.pastelSky,
                text: $emailText
            )
            
            // Password Input
            VStack(alignment: .trailing, spacing: 6) {
                CustomTextField(
                    title: "Mật khẩu",
                    placeholder: "Nhập mật khẩu của bạn",
                    iconName: "lock.fill",
                    iconTintColor: AppTheme.primaryCoral,
                    isSecure: true,
                    text: $passwordText
                )
                
                Button(action: onForgotPassword) {
                    Text("Quên mật khẩu?")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryCoral)
                }
                .padding(.top, 2)
            }
            
            // Login Button connected to Firebase AuthService
            PrimaryCuteButton(
                title: "Đăng nhập ngay 🚀",
                iconName: "arrow.right.circle.fill",
                backgroundColor: AppTheme.primaryMint,
                shadowColor: Color(hex: "27AE60"),
                isLoading: authService.isLoading
            ) {
                localErrorMessage = nil
                guard !emailText.isEmpty, !passwordText.isEmpty else {
                    localErrorMessage = "Vui lòng nhập đầy đủ Email và Mật khẩu."
                    return
                }
                
                Task {
                    do {
                        try await authService.signIn(email: emailText, password: passwordText)
                    } catch {
                        // Error is handled and published by authService.errorMessage
                    }
                }
            }
            .padding(.top, 8)
            
            // Social Login Section
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(AppTheme.textLight.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("Hoặc kết nối qua")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                    
                    Rectangle()
                        .fill(AppTheme.textLight.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 4)
                
                HStack(spacing: 16) {
                    // Google Button
                    Button(action: {
                        // Firebase Google sign in can be integrated here
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            Text("Google")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "F7F8FA"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                    
                    // Apple Button
                    Button(action: {
                        // Firebase Apple sign in can be integrated here
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                            Text("Apple")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "F7F8FA"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView(
        emailText: .constant(""),
        passwordText: .constant(""),
        onForgotPassword: {}
    )
    .environmentObject(AuthService.shared)
    .padding()
    .cuteCardStyle()
    .padding()
    .background(AppTheme.bgGradientStart)
}
