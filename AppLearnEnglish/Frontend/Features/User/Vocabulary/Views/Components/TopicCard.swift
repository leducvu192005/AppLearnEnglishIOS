//
//  TopicCard.swift
//  AppLearnEnglish
//

import SwiftUI

struct TopicCard: View {
    let topic: Topic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Cute colored icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.primaryMint.opacity(0.15))
                    .frame(width: 54, height: 54)
                
                Image(systemName: topic.image.isEmpty ? "airplane" : topic.image)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.primaryMint)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(topic.name)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Text(topic.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(2)
            }
            
            HStack {
                Spacer()
                Text("\(topic.totalWords) từ")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryMint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryMint.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuteCardStyle()
    }
}

#Preview {
    TopicCard(topic: Topic(id: "travel", name: "Du lịch", description: "Các từ vựng hữu dụng tại sân bay, khách sạn", image: "airplane.circle.fill", totalWords: 20))
        .padding()
        .background(AppTheme.bgGradientStart)
}
