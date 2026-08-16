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
                    .fontSubheading()
                    .foregroundColor(DesignSystem.Colors.accentPink)
                    .strikethrough(change.wrong.isEmpty ? false : true)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(change.correct.isEmpty ? "(Lược bỏ)" : change.correct)
                    .fontSubheading()
                    .foregroundColor(DesignSystem.Colors.success)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lý do sửa lỗi:")
                    .fontCaption()
                    .foregroundColor(DesignSystem.Colors.darkNavy)
                
                Text(change.reason)
                    .fontBodySecondary()
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.card)
        .cornerRadius(16)
        .designShadow()
    }
}

#Preview {
    ErrorCard(change: ChangeItem(wrong: "has", correct: "have", reason: "Subject 'I' uses 'have' instead of 'has'."))
        .padding()
        .background(DesignSystem.Colors.background)
}
