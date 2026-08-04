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
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                
                Text(result.original)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.primaryCoral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryCoral.opacity(0.08))
            .cornerRadius(18)
            
            // Corrected Text Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Văn bản đã sửa:")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                
                Text(result.corrected)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.primaryMint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryMint.opacity(0.08))
            .cornerRadius(18)
            
            // Changes Lists
            if result.changes.isEmpty {
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 20))
                    Text("Chúc mừng! Câu viết của bạn đã chuẩn ngữ pháp.")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryMint)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chi tiết lỗi sai (\(result.changes.count)):")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
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
    .background(AppTheme.bgGradientStart)
}
