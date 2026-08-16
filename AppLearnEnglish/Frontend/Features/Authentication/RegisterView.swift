//
//  RegisterView.swift
//  AppLearnEnglish
//

import SwiftUI

struct RegisterView: View {
    @Binding var nameText: String
    @Binding var emailText: String
    @Binding var passwordText: String
    @Binding var confirmPasswordText: String
    var onRegisterSuccess: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @State private var isAgreed: Bool = true
    @State private var localErrorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Message Display
            if let error = localErrorMessage ?? authService.errorMessage {
                Text(error)
                    .fontCaption()
                    .foregroundColor(DesignSystem.Colors.accentPink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            
            // Name Input
            CustomTextField(
                title: "Họ và tên",
                placeholder: "Ví dụ: Alex Nguyễn",
                iconName: "person.fill",
                iconTintColor: DesignSystem.Colors.primary,
                text: $nameText
            )
            
            // Email Input
            CustomTextField(
                title: "Email",
                placeholder: "nhap.email@example.com",
                iconName: "envelope.fill",
                iconTintColor: DesignSystem.Colors.primary,
                text: $emailText
            )
            
            // Password Input
            CustomTextField(
                title: "Mật khẩu",
                placeholder: "Tối thiểu 6 ký tự",
                iconName: "lock.fill",
                iconTintColor: DesignSystem.Colors.accentPink,
                isSecure: true,
                text: $passwordText
            )
            
            // Confirm Password Input
            CustomTextField(
                title: "Xác nhận mật khẩu",
                placeholder: "Nhập lại mật khẩu",
                iconName: "lock.shield.fill",
                iconTintColor: DesignSystem.Colors.warning,
                isSecure: true,
                text: $confirmPasswordText
            )
            
            // Terms Agreement
            HStack(alignment: .center, spacing: 10) {
                Button(action: {
                    withAnimation {
                        isAgreed.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isAgreed ? DesignSystem.Colors.primary : Color(hex: "E2E8F0"))
                            .frame(width: 22, height: 22)
                        
                        if isAgreed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                        }
                    }
                }
                
                Text("Tôi đồng ý với **Điều khoản & Chính sách**")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
            }
            .padding(.top, 4)
            
            // Register Button connected to Firebase AuthService
            PrimaryButton(
                title: "Tạo tài khoản ngay 🌟",
                iconName: "sparkles"
            ) {
                localErrorMessage = nil
                
                guard !nameText.isEmpty, !emailText.isEmpty, !passwordText.isEmpty, !confirmPasswordText.isEmpty else {
                    localErrorMessage = "Vui lòng nhập đầy đủ các trường thông tin."
                    return
                }
                
                guard passwordText == confirmPasswordText else {
                    localErrorMessage = "Mật khẩu xác nhận không trùng khớp."
                    return
                }
                
                guard isAgreed else {
                    localErrorMessage = "Bạn cần đồng ý với Điều khoản & Chính sách bảo mật."
                    return
                }
                
                Task {
                    do {
                        try await authService.signUp(email: emailText, password: passwordText, name: nameText)
                        onRegisterSuccess()
                    } catch {
                        // Error is handled and published by authService.errorMessage
                    }
                }
            }
            .padding(.top, 6)
            .opacity(authService.isLoading ? 0.6 : 1.0)
            .disabled(authService.isLoading)
        }
    }
}

#Preview {
    RegisterView(
        nameText: .constant(""),
        emailText: .constant(""),
        passwordText: .constant(""),
        confirmPasswordText: .constant(""),
        onRegisterSuccess: {}
    )
    .environmentObject(AuthService.shared)
    .padding()
    .background(DesignSystem.Colors.background)
}
