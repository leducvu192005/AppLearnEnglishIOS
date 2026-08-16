//
//  AppTheme.swift
//  AppLearnEnglish
//

import SwiftUI

struct AppTheme {
    // MARK: - Legacy Compatibility mapping to DesignSystem
    static var primaryMint: Color { DesignSystem.Colors.success }
    static var primaryCoral: Color { DesignSystem.Colors.accentPink }
    static var pastelYellow: Color { DesignSystem.Colors.warning }
    static var pastelSky: Color { DesignSystem.Colors.primary }
    static var pastelLavender: Color { DesignSystem.Colors.primaryLight }
    static var pastelPeach: Color { DesignSystem.Colors.accentPink.opacity(0.8) }
    
    // Backgrounds
    static var bgGradientStart: Color { DesignSystem.Colors.background }
    static var bgGradientEnd: Color { DesignSystem.Colors.background }
    static var cardBackground: Color { DesignSystem.Colors.card }
    
    // Text Colors
    static var textDark: Color { DesignSystem.Colors.darkNavy }
    static var textMuted: Color { DesignSystem.Colors.secondaryText }
    static var textLight: Color { DesignSystem.Colors.secondaryText.opacity(0.6) }
}

// MARK: - View Modifiers
struct CuteCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.Radius.card
    var shadowColor: Color = Color.black.opacity(0.04)
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
    }
}

extension View {
    func cuteCardStyle(cornerRadius: CGFloat = DesignSystem.Radius.card, shadowColor: Color = Color.black.opacity(0.04)) -> some View {
        self.modifier(CuteCardModifier(cornerRadius: cornerRadius, shadowColor: shadowColor))
    }
}
