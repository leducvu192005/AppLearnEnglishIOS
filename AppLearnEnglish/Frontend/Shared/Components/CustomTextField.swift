//
//  CustomTextField.swift
//  AppLearnEnglish
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    let iconName: String
    var iconTintColor: Color = AppTheme.pastelSky
    var isSecure: Bool = false
    @Binding var text: String
    
    @FocusState private var isFocused: Bool
    @State private var showPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textMuted)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                // Cute Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconTintColor.opacity(0.2))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconTintColor)
                }
                
                // Input Field
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textDark)
                .focused($isFocused)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                // Clear or Password Toggle Button
                if isSecure {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textLight)
                    }
                } else if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textLight)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "F7F8FA"))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isFocused ? AppTheme.primaryMint : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CustomTextField(title: "Email", placeholder: "nhap.email@gmail.com", iconName: "envelope.fill", iconTintColor: AppTheme.pastelSky, text: .constant(""))
        CustomTextField(title: "Mật khẩu", placeholder: "••••••••", iconName: "lock.fill", iconTintColor: AppTheme.primaryCoral, isSecure: true, text: .constant("123456"))
    }
    .padding()
    .background(AppTheme.bgGradientStart)
}
