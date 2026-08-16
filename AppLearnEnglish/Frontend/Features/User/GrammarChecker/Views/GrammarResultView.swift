//
//  GrammarResultView.swift
//  AppLearnEnglish
//

import SwiftUI

struct GrammarResultView: View {
    let result: GrammarResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Original Text Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Văn bản gốc:")
                    .fontCaption()
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(result.original)
                    .fontSubheading()
                    .foregroundColor(DesignSystem.Colors.accentPink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.accentPink.opacity(0.1))
            .cornerRadius(16)
            
            // Corrected Text Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Văn bản đã sửa:")
                    .fontCaption()
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(result.corrected)
                    .fontSubheading()
                    .foregroundColor(DesignSystem.Colors.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.success.opacity(0.1))
            .cornerRadius(16)
            
            // Changes Lists
            if result.changes.isEmpty {
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 20))
                    Text("Chúc mừng! Câu viết của bạn đã chuẩn ngữ pháp.")
                        .fontSubheading()
                        .foregroundColor(DesignSystem.Colors.success)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chi tiết lỗi sai (\(result.changes.count)):")
                        .fontSubheading()
                        .foregroundColor(DesignSystem.Colors.darkNavy)
                        .padding(.top, 8)
                    
                    ForEach(result.changes) { change in
                        ErrorCard(change: change)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GrammarResultView(result: GrammarResult(
        original: "I has a apple",
        corrected: "I have an apple",
        explanation: "Thay đổi has thành have",
        changes: [
            ChangeItem(wrong: "has", correct: "have", reason: "Subject 'I' uses 'have'"),
            ChangeItem(wrong: "a", correct: "an", reason: "Noun 'apple' starts with vowel")
        ]
    ))
    .padding()
    .background(DesignSystem.Colors.background)
}
