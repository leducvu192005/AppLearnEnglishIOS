//
//  ProgressView.swift
//  AppLearnEnglish
//

import SwiftUI

struct ProgressViewModule: View {
    @StateObject private var viewModel = ProgressViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Level Card
                VStack(spacing: 12) {
                    Text("🏅 Cấp Độ Hiện Tại")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryMint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryMint.opacity(0.15))
                        .cornerRadius(8)
                    
                    Text("Cấp độ \(viewModel.progress.level)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    // XP progress bar
                    let nextLevelXP = viewModel.progress.level * 100
                    let currentLevelXP = (viewModel.progress.level - 1) * 100
                    let xpInCurrentLevel = viewModel.progress.xp - currentLevelXP
                    let progressRatio = Double(xpInCurrentLevel) / 100.0
                    
                    VStack(spacing: 6) {
                        HStack {
                            Text("\(xpInCurrentLevel) / 100 XP")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                            Spacer()
                            Text("Đến cấp \(viewModel.progress.level + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryMint)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.04))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.primaryMint)
                                    .frame(width: geo.size.width * CGFloat(max(0, min(1.0, progressRatio))), height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .cuteCardStyle()
                .padding(.horizontal)
                .padding(.top, 16)
                
                // MARK: - Active Streak Widget
                HStack(spacing: 16) {
                    // Streak card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔥 Chuỗi hiện tại")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text("\(viewModel.progress.streak) ngày")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryCoral)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cuteCardStyle()
                    
                    // Total words card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📚 Từ vựng đã học")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text("\(viewModel.progress.totalWords) từ")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.pastelSky)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cuteCardStyle()
                }
                .padding(.horizontal)
                
                // MARK: - Calendar Week Study Grid
                CalendarView(studyDates: viewModel.studyHistoryDates)
                    .padding(.horizontal)
                
                // MARK: - Learning history log
                VStack(alignment: .leading, spacing: 14) {
                    Text("Nhật ký học tập")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HistoryRow(title: "Luyện Từ vựng Airport", detail: "Đã học: 1 từ mới (+10 XP)", time: "Hôm nay")
                        HistoryRow(title: "Bài tập Quiz Du lịch", detail: "Điểm số: 4/5 đúng (+20 XP)", time: "Hôm qua")
                        HistoryRow(title: "Luyện Nói với AI Tutor", detail: "Thời lượng: 5 phút (+15 XP)", time: "3 ngày trước")
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Tiến độ của tôi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryRow: View {
    let title: String
    let detail: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
            }
            Spacer()
            Text(time)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textLight)
        }
        .padding(14)
        .cuteCardStyle()
    }
}

#Preview {
    NavigationStack {
        ProgressViewModule()
    }
}
