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
            // Soft Eye-Soothing Background Gradient
            LinearGradient(
                colors: [AppTheme.bgGradientStart, AppTheme.bgGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative Soft Ambient Blobs
            VStack {
                HStack {
                    Circle()
                        .fill(AppTheme.pastelYellow.opacity(0.35))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)
                        .offset(x: -40, y: -20)
                    Spacer()
                    Circle()
                        .fill(AppTheme.pastelSky.opacity(0.35))
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
                        // Cute Animated Owl / Character Badge
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 90, height: 90)
                                .shadow(color: AppTheme.primaryMint.opacity(0.2), radius: 12, x: 0, y: 6)
                            
                            Text(authMode == .login ? "🦉" : "🐣")
                                .font(.system(size: 52))
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: authMode)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text(authMode == .login ? "Chào mừng trở lại!" : "Tạo tài khoản mới")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            
                            Text(authMode == .login ? "Sẵn sàng chinh phục Tiếng Anh hôm nay chưa?" : "Bắt đầu hành trình học tiếng Anh siêu thú vị nào!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
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
                                        .fill(AppTheme.primaryMint)
                                        .matchedGeometryEffect(id: "TabHighlight", in: tabNamespace)
                                        .shadow(color: AppTheme.primaryMint.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                
                                Text("Đăng nhập")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(authMode == .login ? .white : AppTheme.textMuted)
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
                                        .fill(AppTheme.primaryCoral)
                                        .matchedGeometryEffect(id: "TabHighlight", in: tabNamespace)
                                        .shadow(color: AppTheme.primaryCoral.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                
                                Text("Đăng ký")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(authMode == .register ? .white : AppTheme.textMuted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                        }
                    }
                    .padding(5)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    // MARK: - Form Card Container
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
                    .padding(24)
                    .cuteCardStyle()
                    .padding(.horizontal, 20)
                    
                    // MARK: - Footer Guest Option
                    Button(action: {
                        alertTitle = "Chế độ trải nghiệm"
                        alertMessage = "Bạn đang vào ứng dụng với tư cách Khách!"
                        showAlert = true
                    }) {
                        Text("Dùng thử không cần đăng nhập ✨")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
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
