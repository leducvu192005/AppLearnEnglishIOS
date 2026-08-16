//
//  PrimaryCuteButton.swift
//  AppLearnEnglish
//

import SwiftUI

struct PrimaryCuteButton: View {
    let title: String
    var iconName: String? = nil
    var backgroundColor: Color = AppTheme.primaryMint
    var shadowColor: Color = Color(hex: "27AE60") // Slightly darker shade for 3D depth
    var textColor: Color = .white
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    if let iconName = iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // 3D Bottom Shadow Lip
                    RoundedRectangle(cornerRadius: 20)
                        .fill(shadowColor)
                        .offset(y: isPressed ? 0 : 5)
                    
                    // Main Front Surface
                    RoundedRectangle(cornerRadius: 20)
                        .fill(backgroundColor)
                        .offset(y: isPressed ? 4 : 0)
                }
            )
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
    }
}

// Custom ButtonStyle to track press state for 3D animation
struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .onChange(of: configuration.isPressed) { _, newValue in
                    withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.7)) {
                        isPressed = newValue
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryCuteButton(title: "Đăng nhập", iconName: "arrow.right.circle.fill") {}
        PrimaryCuteButton(title: "Tạo tài khoản", backgroundColor: AppTheme.primaryCoral, shadowColor: Color(hex: "E74C3C")) {}
    }
    .padding()
    .background(AppTheme.bgGradientStart)
}
