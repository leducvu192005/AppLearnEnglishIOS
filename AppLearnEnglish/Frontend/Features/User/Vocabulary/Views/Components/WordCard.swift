//
//  WordCard.swift
//  AppLearnEnglish
//

import SwiftUI

struct WordCard: View {
    let word: VocabularyWord
    let isLearned: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkmark indicator for learned words
            ZStack {
                Circle()
                    .fill(isLearned ? AppTheme.primaryMint.opacity(0.15) : Color.black.opacity(0.03))
                    .frame(width: 32, height: 32)
                
                if isLearned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primaryMint)
                } else {
                    Circle()
                        .stroke(AppTheme.textLight.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text(word.phonetic)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                Text(word.meaning)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textLight)
        }
        .padding(14)
        .cuteCardStyle()
    }
}

#Preview {
    VStack(spacing: 12) {
        WordCard(word: VocabularyWord(id: "tr1", word: "airport", phonetic: "/ˈeəpɔːt/", meaning: "sân bay", example: "I meet you at the airport.", image: "", audio: "", topicId: "travel", level: "Beginner"), isLearned: true)
        
        WordCard(word: VocabularyWord(id: "tr2", word: "passport", phonetic: "/ˈpɑːspɔːt/", meaning: "hộ chiếu", example: "Check passport details.", image: "", audio: "", topicId: "travel", level: "Beginner"), isLearned: false)
    }
    .padding()
    .background(AppTheme.bgGradientStart)
}
