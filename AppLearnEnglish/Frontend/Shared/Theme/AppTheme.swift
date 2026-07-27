//
//  AppTheme.swift
//  AppLearnEnglish
//

import SwiftUI

struct AppTheme {
    // MARK: - Cute & Eye-Soothing Colors
    static let primaryMint = Color(hex: "48BB78")     // Soft Vibrant Mint Green
    static let primaryCoral = Color(hex: "FF7675")    // Soft Warm Coral
    static let pastelYellow = Color(hex: "FFEAA7")    // Cute Sunshine Yellow
    static let pastelSky = Color(hex: "74B9FF")       // Soft Sky Blue
    static let pastelLavender = Color(hex: "A29BFE")  // Cute Lavender
    static let pastelPeach = Color(hex: "FAB1A0")     // Soft Peach
    
    // Backgrounds
    static let bgGradientStart = Color(hex: "FAFAF7")  // Soft Warm Cream
    static let bgGradientEnd = Color(hex: "EEF6F3")    // Gentle Mint Tint
    static let cardBackground = Color.white
    
    // Text Colors
    static let textDark = Color(hex: "2D3436")
    static let textMuted = Color(hex: "636E72")
    static let textLight = Color(hex: "B2BEC3")
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CuteCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var shadowColor: Color = Color.black.opacity(0.06)
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: 16, x: 0, y: 8)
    }
}

extension View {
    func cuteCardStyle(cornerRadius: CGFloat = 24, shadowColor: Color = Color.black.opacity(0.06)) -> some View {
        self.modifier(CuteCardModifier(cornerRadius: cornerRadius, shadowColor: shadowColor))
    }
}
