//
//  AuthenticationView.swift
//  AppLearnEnglish
//

import SwiftUI

enum AuthMode {
    case login
    case register
}

struct AuthenticationView: View {
    @State private var authMode: AuthMode = .login
    
    // Form States
    @State private var nameText: String = ""
    @State private var emailText: String = ""
    @State private var passwordText: String = ""
    @State private var confirmPasswordText: String = ""
    
    // Alert State
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @EnvironmentObject var authService: AuthService
    @Namespace private var tabNamespace
    
    var body: some View {
        ZStack {
            // Soft Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Decorative Soft Ambient Blobs
            VStack {
                HStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryLight.opacity(0.4))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)
                        .offset(x: -40, y: -20)
                    Spacer()
                    Circle()
                        .fill(DesignSystem.Colors.accentPink.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)
                        .offset(x: 30, y: -40)
                }
                Spacer()
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Top Mascot & Greeting Header
                    VStack(spacing: 12) {
                        // Mascot Circle
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.card)
                                .frame(width: 90, height: 90)
                                .designShadow()
                            
                            OwlMascot(state: authMode == .login ? .greeting : .thinking, size: 76)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text(authMode == .login ? "Chào mừng trở lại!" : "Tạo tài khoản mới")
                                .fontHeading()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            
                            Text(authMode == .login ? "Sẵn sàng chinh phục Tiếng Anh hôm nay chưa?" : "Bắt đầu hành trình học tiếng Anh siêu thú vị nào!")
                                .fontBodySecondary()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // MARK: - Animated Tab Picker
                    HStack(spacing: 0) {
                        // Login Tab Button
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                authMode = .login
                            }
                        }) {
                            ZStack {
                                if authMode == .login {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(DesignSystem.Colors.primary)
                                        .matchedGeometryEffect(id: "TabHighlight", in: tabNamespace)
                                }
                                
                                Text("Đăng nhập")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(authMode == .login ? DesignSystem.Colors.darkNavy : DesignSystem.Colors.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                        }
                        
                        // Register Tab Button
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                authMode = .register
                            }
                        }) {
                            ZStack {
                                if authMode == .register {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(DesignSystem.Colors.accentPink)
                                        .matchedGeometryEffect(id: "TabHighlight", in: tabNamespace)
                                }
                                
                                Text("Đăng ký")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(authMode == .register ? DesignSystem.Colors.darkNavy : DesignSystem.Colors.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                        }
                    }
                    .padding(5)
                    .background(DesignSystem.Colors.card.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    // MARK: - Form Card Container
                    SoftCard(padding: 24) {
                        VStack {
                            if authMode == .login {
                                LoginView(
                                    emailText: $emailText,
                                    passwordText: $passwordText,
                                    onForgotPassword: {
                                        alertTitle = "Quên mật khẩu"
                                        alertMessage = "Vui lòng nhập Email để nhận liên kết khôi phục mật khẩu."
                                        showAlert = true
                                    }
                                )
                                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                            } else {
                                RegisterView(
                                    nameText: $nameText,
                                    emailText: $emailText,
                                    passwordText: $passwordText,
                                    confirmPasswordText: $confirmPasswordText,
                                    onRegisterSuccess: {
                                        alertTitle = "Chúc mừng ✨"
                                        alertMessage = "Tài khoản của bạn đã được tạo thành công! Hãy đăng nhập nhé."
                                        showAlert = true
                                        withAnimation {
                                            authMode = .login
                                        }
                                    }
                                )
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Footer Guest Option
                    Button(action: {
                        alertTitle = "Chế độ trải nghiệm"
                        alertMessage = "Bạn đang vào ứng dụng với tư cách Khách!"
                        showAlert = true
                    }) {
                        Text("Dùng thử không cần đăng nhập ✨")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService.shared)
}
