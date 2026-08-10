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
            // Tab 1: Home Dashboard
            NavigationStack {
                UserHomeDashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Trang chủ", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 2: Vocabulary Page (Học Từ Vựng bên cạnh Trang Chủ)
            NavigationStack {
                VocabularyView()
            }
            .tabItem {
                Label("Từ vựng", systemImage: "character.book.closed.fill")
            }
            .tag(1)
            
            // Tab 3: AI Chat Tutor
            NavigationStack {
                AIChatView()
            }
            .tabItem {
                Label("AI Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(2)
            
            // Tab 4: Profile Settings
            NavigationStack {
                ProfileViewModule()
            }
            .tabItem {
                Label("Hồ sơ", systemImage: "person.crop.circle.fill")
            }
            .tag(3)
        }
        .tint(AppTheme.primaryMint)
    }
}

// MARK: - Subviews for User tabs

struct UserHomeDashboardView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - 1. PREMIUM HEADER PANEL
                HStack(spacing: 16) {
                    // Profile Avatar with dynamic gradient background
                    ZStack {
                        LinearGradient(
                            colors: [AppTheme.primaryMint, AppTheme.pastelSky],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.primaryMint.opacity(0.25), radius: 6, x: 0, y: 3)
                        
                        let name = sessionManager.currentUserModel?.name ?? "Học viên"
                        let initial = String(name.prefix(1)).uppercased()
                        Text(initial)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chào ngày mới 👋")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text(sessionManager.currentUserModel?.name ?? "Học viên")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    Spacer()
                    
                    // Streak flame badge with glowing amber shadow
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 16))
                        Text("\(sessionManager.currentUserModel?.streak ?? 0) ngày")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "F2994A"), Color(hex: "F2C94C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(hex: "F2994A").opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                // MARK: - 2. DAILY GOAL PROGRESS CARD
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mục tiêu hàng ngày")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            
                            // Level Badge
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.pastelYellow)
                                Text("Cấp độ: \(sessionManager.currentUserModel?.level ?? "Beginner")")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primaryMint)
                            .cornerRadius(8)
                        }
                        Spacer()
                        
                        Text("\(sessionManager.currentUserModel?.xp ?? 0) / \(sessionManager.currentUserModel?.dailyGoal ?? 20) XP")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryMint)
                    }
                    
                    // Simple Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.04))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.primaryMint, Color(hex: "2ECC71")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(geo.size.width * CGFloat(Double(sessionManager.currentUserModel?.xp ?? 0) / Double(sessionManager.currentUserModel?.dailyGoal ?? 20)), geo.size.width)), height: 12)
                                .shadow(color: AppTheme.primaryMint.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(20)
                .background(Color.white)
                .cuteCardStyle()
                .padding(.horizontal)
                
                // MARK: - 3. 3-COLUMN STATS PANEL
                HStack(spacing: 12) {
                    // Col 1: Accumulated XP
                    VStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "F2C94C"))
                        Text("Tích lũy")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(sessionManager.currentUserModel?.xp ?? 0) XP")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                    
                    // Col 2: Streak Days
                    VStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryCoral)
                        Text("Chuỗi học")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(sessionManager.currentUserModel?.streak ?? 0) ngày")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                    
                    // Col 3: Daily Target Goal
                    VStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.pastelSky)
                        Text("Mục tiêu")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(sessionManager.currentUserModel?.dailyGoal ?? 20) XP")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal)
                
                // MARK: - 4. REDESIGNED FEATURE CARDS GRID
                VStack(alignment: .leading, spacing: 14) {
                    Text("Luyện tập & Tiện ích")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        // Vocabulary Button -> Switches to Vocabulary Tab (Tab index 1)
                        Button(action: {
                            withAnimation {
                                selectedTab = 1
                            }
                        }) {
                            SkillGridCard(
                                title: "Từ vựng 📚", 
                                subtitle: "Chinh phục 1000+ từ", 
                                icon: "character.book.closed.fill", 
                                startColor: AppTheme.primaryMint, 
                                endColor: Color(hex: "2ECC71")
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        // Listening Practice
                        NavigationLink(destination: ListeningPracticeView()) {
                            SkillGridCard(
                                title: "Luyện nghe 🎧", 
                                subtitle: "Chép chính tả bằng giọng chuẩn Mỹ", 
                                icon: "headphones", 
                                startColor: Color(hex: "F2C94C"), 
                                endColor: Color(hex: "F2994A")
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Quiz Button -> Navigates to QuizView for Travel
                        NavigationLink(destination: QuizView(topicId: "travel", topicName: "Du lịch")) {
                            SkillGridCard(
                                title: "Trắc nghiệm 📝", 
                                subtitle: "Đánh giá phản xạ và từ vựng", 
                                icon: "checkmark.seal.fill", 
                                startColor: AppTheme.pastelSky, 
                                endColor: Color(hex: "0984E3")
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // AI Chat Button -> Switches to AI Chat Tab (Tab index 2)
                        Button(action: {
                            withAnimation {
                                selectedTab = 2
                            }
                        }) {
                            SkillGridCard(
                                title: "AI Chat Tutor 💬", 
                                subtitle: "Hội thoại phản xạ với cú Owl", 
                                icon: "bubble.left.and.bubble.right.fill", 
                                startColor: AppTheme.pastelLavender, 
                                endColor: Color(hex: "6C5CE7")
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Grammar Checker Button -> Navigates to GrammarCheckerView
                        NavigationLink(destination: GrammarCheckerView()) {
                            SkillGridCard(
                                title: "Sửa ngữ pháp 🦉", 
                                subtitle: "Sửa lỗi viết tiếng Anh tức thì bằng RAG", 
                                icon: "pencil.and.outline", 
                                startColor: AppTheme.primaryCoral, 
                                endColor: Color(hex: "D63031")
                            )
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
    let subtitle: String
    let icon: String
    let startColor: Color
    let endColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Glowing Icon Circle Badge
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .background(
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: startColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    UserTabView()
        .environmentObject(SessionManager.shared)
}
