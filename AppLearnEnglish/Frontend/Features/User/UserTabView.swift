//
//  UserTabView.swift
//  AppLearnEnglish
//

import SwiftUI

struct UserTabView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var vocabViewModel = VocabularyViewModel()
    @State private var selectedTab = 0
    
    // Notification banner states
    @State private var showingAddedBanner = false
    @State private var addedWordTitle = ""
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Home Dashboard
                NavigationStack {
                    UserHomeDashboardView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Label("Trang chủ", systemImage: "house.fill")
                }
                .tag(0)
                
                // Tab 2: Learn Screen
                NavigationStack {
                    LearnView()
                }
                .tabItem {
                    Label("Học tập", systemImage: "book.closed.fill")
                }
                .tag(1)
                
                // Tab 3: Practice Screen
                NavigationStack {
                    PracticeView()
                }
                .tabItem {
                    Label("Luyện tập", systemImage: "headphones")
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
            .tint(DesignSystem.Colors.primary)
            .environmentObject(vocabViewModel)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddWordFromNotification"))) { notification in
                if let wordDict = notification.userInfo?["word"] as? [String: String] {
                    vocabViewModel.addWordFromNotification(word: wordDict)
                    addedWordTitle = wordDict["word"] ?? ""
                    withAnimation(.spring()) {
                        showingAddedBanner = true
                    }
                    // Auto-hide after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation(.spring()) {
                            showingAddedBanner = false
                        }
                    }
                }
            }
            
            // Premium Overlay Notification Banner
            if showingAddedBanner {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "headphones.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Đã lưu từ vựng thụ động! 🌟")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Từ \"\(addedWordTitle)\" đã được thêm vào bộ Oxford 3000.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(DesignSystem.Colors.success)
                    .cornerRadius(20)
                    .shadow(color: DesignSystem.Colors.success.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .zIndex(999)
            }
        }
    }
}

// MARK: - Subviews for User tabs

struct UserHomeDashboardView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Binding var selectedTab: Int
    
    @State private var activeQuizTopicId: String? = nil
    @State private var activeQuizTopicName: String? = nil
    @State private var activeQuizIndex: Int = 0
    @State private var activeQuizTotal: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // MARK: - 1. GREETING HEADER
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        let name = sessionManager.currentUserModel?.name ?? "Học viên"
                        Text("Chào \(name)! 👋")
                            .fontTitle()
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                        
                        Text("Hôm nay bạn muốn bắt đầu học từ đâu?")
                            .fontBodySecondary()
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                    
                    // Streak badge
                    StreakCard(streakDays: sessionManager.currentUserModel?.streak ?? 0)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                // MARK: - 2. OWL COMPANION GREETING BUBBLE
                HStack(alignment: .center, spacing: 16) {
                    OwlMascot(state: .greeting, size: 84)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cú Owl AI")
                            .fontCaption()
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("\"Hãy hoàn thành mục tiêu ngày hôm nay để duy trì chuỗi học tập nhé!\"")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.darkNavy)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(DesignSystem.Colors.primaryLight)
                    .cornerRadius(18)
                    Spacer()
                }
                .padding(.horizontal)
                
                // MARK: - 3. CONTINUE LEARNING HERO CARD
                if let topicId = activeQuizTopicId {
                    SoftCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tiếp tục ôn tập 📝")
                                        .fontSubheading()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                    Text("Bài tập đang dở: \(activeQuizTopicName ?? "Du lịch")")
                                        .fontCaption()
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                Spacer()
                                
                                Text("Câu \(activeQuizIndex + 1) / \(activeQuizTotal)")
                                    .fontSubheading()
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.Colors.primaryLight)
                                        .frame(height: 10)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.Colors.primary)
                                        .frame(width: max(0, min(geo.size.width * CGFloat(Double(activeQuizIndex + 1) / Double(max(1, activeQuizTotal))), geo.size.width)), height: 10)
                                }
                            }
                            .frame(height: 10)
                            
                            // Navigation link button styled as primary button
                            NavigationLink(destination: QuizView(topicId: topicId, topicName: activeQuizTopicName ?? "Du lịch")) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Làm tiếp ngay ➔")
                                        .fontSubheading()
                                }
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DesignSystem.Colors.primary)
                                .cornerRadius(DesignSystem.Radius.button)
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Default card when no active quiz
                    SoftCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tiếp tục học tập")
                                        .fontSubheading()
                                        .foregroundColor(DesignSystem.Colors.darkNavy)
                                    Text("Mục tiêu ngày")
                                        .fontCaption()
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                Spacer()
                                
                                Text("\(sessionManager.currentUserModel?.dailyXP ?? 0) / \(sessionManager.currentUserModel?.dailyGoal ?? 20) XP")
                                    .fontSubheading()
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.Colors.primaryLight)
                                        .frame(height: 10)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.Colors.primary)
                                        .frame(width: max(0, min(geo.size.width * CGFloat(Double(sessionManager.currentUserModel?.dailyXP ?? 0) / Double(sessionManager.currentUserModel?.dailyGoal ?? 20)), geo.size.width)), height: 10)
                                }
                            }
                            .frame(height: 10)
                            
                            PrimaryButton(title: "Học ngay ✨", iconName: "sparkles") {
                                withAnimation {
                                    selectedTab = 1 // Navigate to Learn tab
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - 4. REDESIGNED FEATURE CARDS GRID (2-Column Grid)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Danh mục học tập")
                        .fontHeading()
                        .foregroundColor(DesignSystem.Colors.darkNavy)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        
                        // 1. Vocabulary
                        Button(action: {
                            withAnimation {
                                selectedTab = 1 // Learn Tab
                            }
                        }) {
                            HomeFeatureCard(
                                title: "Từ Vựng",
                                subtitle: "Chinh phục 1000+ từ",
                                icon: "character.book.closed.fill",
                                color: DesignSystem.Colors.primary
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 2. Quiz Practice
                        NavigationLink(destination: QuizView(topicId: "travel", topicName: "Du lịch")) {
                            HomeFeatureCard(
                                title: "Trắc Nghiệm",
                                subtitle: "Luyện phản xạ nhanh",
                                icon: "checkmark.seal.fill",
                                color: DesignSystem.Colors.warning
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 3. Grammar Checker
                        NavigationLink(destination: GrammarCheckerView()) {
                            HomeFeatureCard(
                                title: "Sửa Ngữ Pháp",
                                subtitle: "Xem AI chữa bài viết",
                                icon: "pencil.and.outline",
                                color: DesignSystem.Colors.accentPink
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 4. Practice Hub
                        Button(action: {
                            withAnimation {
                                selectedTab = 2 // Practice Tab
                            }
                        }) {
                            HomeFeatureCard(
                                title: "Luyện Tập",
                                subtitle: "Nghe nói viết 1-1",
                                icon: "headphones",
                                color: DesignSystem.Colors.success
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            activeQuizTopicId = UserDefaults.standard.string(forKey: "AppLearnEnglish_ActiveQuizTopicId")
            activeQuizTopicName = UserDefaults.standard.string(forKey: "AppLearnEnglish_ActiveQuizTopicName")
            activeQuizIndex = UserDefaults.standard.integer(forKey: "AppLearnEnglish_ActiveQuizIndex")
            activeQuizTotal = UserDefaults.standard.integer(forKey: "AppLearnEnglish_ActiveQuizTotal")
        }
    }
}

// MARK: - Home Feature Card Component
struct HomeFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        SoftCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Circular icon frame
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fontSubheading()
                        .foregroundColor(DesignSystem.Colors.darkNavy)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    UserTabView()
        .environmentObject(SessionManager.shared)
}
