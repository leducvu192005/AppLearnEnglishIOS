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
                    .fontCaption()
                    .foregroundColor(DesignSystem.Colors.accentPink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            
            // Email Input
            CustomTextField(
                title: "Email",
                placeholder: "nhap.email@example.com",
                iconName: "envelope.fill",
                iconTintColor: DesignSystem.Colors.primary,
                text: $emailText
            )
            
            // Password Input
            VStack(alignment: .trailing, spacing: 6) {
                CustomTextField(
                    title: "Mật khẩu",
                    placeholder: "Nhập mật khẩu của bạn",
                    iconName: "lock.fill",
                    iconTintColor: DesignSystem.Colors.accentPink,
                    isSecure: true,
                    text: $passwordText
                )
                
                Button(action: onForgotPassword) {
                    Text("Quên mật khẩu?")
                        .fontCaption()
                        .foregroundColor(DesignSystem.Colors.accentPink)
                }
                .padding(.top, 2)
            }
            
            // Login Button connected to Firebase AuthService
            PrimaryButton(
                title: "Đăng nhập ngay 🚀",
                iconName: "arrow.right.circle.fill"
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
            .opacity(authService.isLoading ? 0.6 : 1.0)
            .disabled(authService.isLoading)
            
            // Social Login Section
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(DesignSystem.Colors.secondaryText.opacity(0.2))
                        .frame(height: 1)
                    
                    Text("Hoặc kết nối qua")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Rectangle()
                        .fill(DesignSystem.Colors.secondaryText.opacity(0.2))
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
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(DesignSystem.Radius.button)
                    }
                    
                    // Apple Button
                    Button(action: {
                        // Firebase Apple sign in can be integrated here
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18))
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            Text("Apple")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(DesignSystem.Radius.button)
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
    .background(DesignSystem.Colors.background)
}
