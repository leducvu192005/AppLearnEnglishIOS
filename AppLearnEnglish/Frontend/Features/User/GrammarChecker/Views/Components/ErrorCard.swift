//
//  ErrorCard.swift
//  AppLearnEnglish
//

import SwiftUI

struct ErrorCard: View {
    let change: ChangeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("❌")
                    .font(.system(size: 16))
                
                Text(change.wrong.isEmpty ? "(Thêm từ)" : change.wrong)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryCoral)
                    .strikethrough(change.wrong.isEmpty ? false : true)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                Text(change.correct.isEmpty ? "(Lược bỏ)" : change.correct)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryMint)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lý do sửa lỗi:")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Text(change.reason)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ErrorCard(change: ChangeItem(wrong: "has", correct: "have", reason: "Subject 'I' uses 'have' instead of 'has'."))
        .padding()
        .background(AppTheme.bgGradientStart)
}
