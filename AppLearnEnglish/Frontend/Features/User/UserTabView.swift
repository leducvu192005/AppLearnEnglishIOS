//
//  UserTabView.swift
//  AppLearnEnglish
//

import SwiftUI

struct UserTabView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home Dashboard inside NavigationStack
            NavigationStack {
                UserHomeDashboardView()
            }
            .tabItem {
                Label("Trang chủ", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 2: AI Chat inside NavigationStack
            NavigationStack {
                AIChatView()
            }
            .tabItem {
                Label("AI Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(1)
            
            // Tab 3: Profile Settings inside NavigationStack
            NavigationStack {
                ProfileViewModule()
            }
            .tabItem {
                Label("Hồ sơ", systemImage: "person.crop.circle.fill")
            }
            .tag(2)
        }
        .tint(AppTheme.primaryMint)
    }
}

// MARK: - Subviews for User tabs

struct UserHomeDashboardView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Panel
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chào ngày mới 👋")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text(sessionManager.currentUserModel?.name ?? "Học viên")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    Spacer()
                    
                    // Streak badge
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 20))
                        Text("\(sessionManager.currentUserModel?.streak ?? 0) ngày")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryCoral)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primaryCoral.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Progress Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mục tiêu hàng ngày")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            Text("Trình độ: \(sessionManager.currentUserModel?.level ?? "Beginner")")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                        Text("\(sessionManager.currentUserModel?.xp ?? 0) / \(sessionManager.currentUserModel?.dailyGoal ?? 20) XP")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryMint)
                    }
                    
                    // Simple Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.05))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.primaryMint)
                                .frame(width: max(0, min(geo.size.width * CGFloat(Double(sessionManager.currentUserModel?.xp ?? 0) / Double(sessionManager.currentUserModel?.dailyGoal ?? 20)), geo.size.width)), height: 12)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(20)
                .cuteCardStyle()
                .padding(.horizontal)
                
                // Skill Learning Cards Grid
                VStack(alignment: .leading, spacing: 14) {
                    Text("Luyện tập 4 kỹ năng & Tiện ích")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        // Vocabulary Button -> Navigates to VocabularyView
                        NavigationLink(destination: VocabularyView()) {
                            SkillGridCard(title: "Từ vựng 📚", icon: "character.book.closed.fill", color: AppTheme.primaryMint)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        SkillGridCard(title: "Thẻ từ (Flashcard)", icon: "square.stack.3d.up.fill", color: AppTheme.pastelYellow)
                        
                        // Quiz Button -> Navigates to QuizView for Travel
                        NavigationLink(destination: QuizView(topicId: "travel", topicName: "Du lịch")) {
                            SkillGridCard(title: "Trắc nghiệm (Quiz) 📝", icon: "checkmark.seal.fill", color: AppTheme.pastelSky)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // AI Chat Button -> Navigates to AIChatView
                        NavigationLink(destination: AIChatView()) {
                            SkillGridCard(title: "AI Chat Tutor 🦉", icon: "bubble.left.and.bubble.right.fill", color: AppTheme.pastelLavender)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(AppTheme.bgGradientStart)
    }
}

struct SkillGridCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textDark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .cuteCardStyle()
    }
}

#Preview {
    UserTabView()
        .environmentObject(SessionManager.shared)
}
