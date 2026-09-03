//
//  AdminHomeView.swift
//  AppLearnEnglish
//

import SwiftUI
import AVFoundation

// MARK: - Premium SaaS macOS Design System (Linear, Stripe, Vercel, Raycast Inspired)
struct AdminTheme {
    // Backgrounds
    static let appBackground = Color(hex: "F5F7FA")  // Canvas background
    static let surface = Color(hex: "FFFFFF")        // White Card / Table Surface
    static let surfaceHover = Color(hex: "F8FAFC")   // Subtle Row Hover / Header Surface
    static let sidebarBg = Color(hex: "F8FAFC")      // Native macOS Left Sidebar
    static let border = Color(hex: "E2E8F0")         // 1pt clean divider lines
    
    // Primaries
    static let deepNavy = Color(hex: "0F172A")       // Deep Brand Navy
    static let primary = Color(hex: "2563EB")        // SaaS Royal Blue
    static let accentBlue = Color(hex: "3B82F6")     // Secondary Accent Blue
    static let primaryLight = Color(hex: "EFF6FF")   // Selected Row / Tag Light Blue
    
    // Typography Colors
    static let textPrimary = Color(hex: "0F172A")    // Primary Text (Slate Dark)
    static let textSecondary = Color(hex: "64748B")  // Secondary Text
    static let textMuted = Color(hex: "94A3B8")      // Muted / Placeholder Text
    
    // Semantic Colors & Badges
    static let success = Color(hex: "10B981")        // Emerald Green
    static let successBg = Color(hex: "ECFDF5")      // Emerald Light
    static let warning = Color(hex: "F59E0B")        // Amber Yellow
    static let warningBg = Color(hex: "FFFBEB")      // Amber Light
    static let danger = Color(hex: "EF4444")         // Rose Red
    static let dangerBg = Color(hex: "FEF2F2")       // Rose Light
    static let purple = Color(hex: "8B5CF6")         // Purple
    static let purpleBg = Color(hex: "F5F3FF")       // Purple Light
}

struct AdminHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = AdminViewModel()
    
    // Selected Sidebar Tab (0: Dashboard, 1: Topics & Vocabulary, 2: Quizzes, 3: Listening, 4: Students, 5: Settings, 6: Activity Log)
    @State private var selectedTab: Int? = 0
    
    // Selected Topic for Vocabulary detail view
    @State private var selectedTopicForWords: Topic? = nil
    
    // Selected Vocabulary word for Right-side Detail Inspector
    @State private var selectedWordForInspector: VocabularyWord? = nil
    
    // Alert States for Delete Confirmation
    @State private var topicToDelete: Topic? = nil
    @State private var showingDeleteTopicAlert = false
    
    @State private var wordToDelete: VocabularyWord? = nil
    @State private var showingDeleteWordAlert = false
    
    @State private var quizToDelete: Quiz? = nil
    @State private var showingDeleteQuizAlert = false
    
    @State private var listeningToDelete: ListeningExercise? = nil
    @State private var showingDeleteListeningAlert = false
    
    // Add/Edit Topic Sheet States
    @State private var showingTopicSheet = false
    @State private var editingTopic: Topic? = nil
    @State private var topicName = ""
    @State private var topicDesc = ""
    @State private var topicImage = ""
    
    // Add/Edit Word Sheet States
    @State private var showingWordSheet = false
    @State private var editingWord: VocabularyWord? = nil
    @State private var wordText = ""
    @State private var wordPhonetic = ""
    @State private var wordMeaning = ""
    @State private var wordExample = ""
    @State private var wordImage = ""
    @State private var wordAudio = ""
    @State private var wordTopicId = ""
    @State private var wordLevel = "Beginner"
    
    // Add/Edit Quiz Sheet States
    @State private var showingQuizSheet = false
    @State private var editingQuiz: Quiz? = nil
    @State private var quizQuestion = ""
    @State private var quizAnswerA = ""
    @State private var quizAnswerB = ""
    @State private var quizAnswerC = ""
    @State private var quizAnswerD = ""
    @State private var quizCorrectAnswer = ""
    @State private var quizTopicId = "travel"
    @State private var quizLevel = "Beginner"
    @State private var quizType = "multiple_choice"
    
    // Add/Edit Listening Sheet States
    @State private var showingListeningSheet = false
    @State private var editingListening: ListeningExercise? = nil
    @State private var listeningSentence = ""
    @State private var listeningTranslation = ""
    @State private var listeningTopicId = "travel"
    @State private var listeningLevel = "Beginner"
    @State private var listeningHint = ""
    @State private var listeningAudioUrl = ""
    
    // Import Wizard Sheet States (Vocabulary, Quiz, Listening)
    @State private var showingImportSheet = false
    @State private var importStep = 1 // 1: Upload, 2: Preview, 3: Success
    @State private var importText = ""
    @State private var isImportJSON = false
    
    // Quiz Import States
    @State private var showingQuizImportSheet = false
    @State private var quizImportText = ""
    @State private var isQuizImportJSON = false
    @State private var quizImportTopicMode = "existing" // "existing" or "new"
    @State private var quizImportSelectedTopicId = "travel"
    @State private var quizImportNewTopicName = ""
    @State private var quizImportNewTopicDesc = ""
    
    // Listening Import States
    @State private var showingListeningImportSheet = false
    @State private var listeningImportText = ""
    @State private var isListeningImportJSON = false
    @State private var listeningImportTopicMode = "existing" // "existing" or "new"
    @State private var listeningImportSelectedTopicId = "travel"
    @State private var listeningImportNewTopicName = ""
    @State private var listeningImportNewTopicDesc = ""
    
    // Hover States
    @State private var hoveredRowId: String? = nil
    
    // Audio synthesizer for previewing pronunciation
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR (macOS Catalyst Native SaaS Style)
            sidebarView
                .frame(width: 240)
                .background(AdminTheme.sidebarBg)
            
            // 1pt clean divider
            Rectangle()
                .fill(AdminTheme.border)
                .frame(width: 1)
                .ignoresSafeArea()
            
            // DETAIL PANE (High-density SaaS Canvas)
            ZStack {
                AdminTheme.appBackground
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.topics.isEmpty {
                    tableSkeletonView
                } else if let err = viewModel.errorMessage, viewModel.topics.isEmpty {
                    errorView(errorMsg: err)
                } else {
                    switch selectedTab ?? 0 {
                    case 0:
                        adminDashboardView
                    case 1:
                        if let selectedTopic = selectedTopicForWords {
                            vocabularyDetailView(topic: selectedTopic)
                        } else {
                            topicsMainView
                        }
                    case 2:
                        adminQuizzesView
                    case 3:
                        adminListeningView
                    case 4:
                        adminUsersView
                    case 5:
                        adminSettingsView
                    case 6:
                        adminActivityLogView
                    default:
                        adminDashboardView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AdminTheme.appBackground)
        .ignoresSafeArea()
        .task {
            await viewModel.loadAllData()
        }
        .sheet(isPresented: $showingTopicSheet) {
            topicFormSheet
        }
        .sheet(isPresented: $showingWordSheet) {
            wordFormSheet
        }
        .sheet(isPresented: $showingQuizSheet) {
            quizFormSheet
        }
        .sheet(isPresented: $showingListeningSheet) {
            listeningFormSheet
        }
        .sheet(isPresented: $showingImportSheet) {
            importWizardSheet
        }
        .sheet(isPresented: $showingQuizImportSheet) {
            quizImportWizardSheet
        }
        .sheet(isPresented: $showingListeningImportSheet) {
            listeningImportWizardSheet
        }
        .alert(isPresented: $showingDeleteTopicAlert) {
            deleteTopicAlert
        }
        .alert(isPresented: $showingDeleteWordAlert) {
            deleteWordAlert
        }
        .alert(isPresented: $showingDeleteQuizAlert) {
            deleteQuizAlert
        }
        .alert(isPresented: $showingDeleteListeningAlert) {
            deleteListeningAlert
        }
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Brand Section
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(AdminTheme.deepNavy)
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("SYSTEM PORTAL")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(AdminTheme.textPrimary)
                        .tracking(1.2)
                    
                    Text("English LMS Admin")
                        .font(.system(size: 10))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 18)
            
            Divider()
                .background(AdminTheme.border)
            
            // Sidebar Menu Navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section: WORKSPACE
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORKSPACE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                            .tracking(0.8)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                        
                        sidebarButton(title: "Dashboard", icon: "rectangle.grid.2x2", tag: 0)
                        sidebarButton(title: "Topics & Vocabulary", icon: "square.stack.3d.up", tag: 1)
                        sidebarButton(title: "Quizzes", icon: "checklist", tag: 2)
                        sidebarButton(title: "Listening", icon: "headphones", tag: 3)
                        sidebarButton(title: "Students", icon: "person.2", tag: 4)
                    }
                    
                    // Section: SYSTEM
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                            .tracking(0.8)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                        
                        sidebarButton(title: "Settings", icon: "gearshape", tag: 5)
                        sidebarButton(title: "Activity Log", icon: "clock.arrow.circlepath", tag: 6)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 14)
            }
            
            Spacer()
            
            Divider()
                .background(AdminTheme.border)
            
            // Bottom Admin Profile Card
            HStack(spacing: 10) {
                // Initials Avatar
                ZStack {
                    Circle()
                        .fill(AdminTheme.deepNavy)
                        .frame(width: 32, height: 32)
                    
                    Text(userInitials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionManager.currentUserModel?.name ?? "Administrator")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text("Administrator")
                        .font(.system(size: 10))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: { sessionManager.signOut() }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AdminTheme.textSecondary)
                        .padding(6)
                        .background(Color.clear)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AdminTheme.surface)
        }
        .frame(minWidth: 230, idealWidth: 240, maxWidth: 260)
        .background(AdminTheme.sidebarBg)
    }
    
    private var userInitials: String {
        let name = sessionManager.currentUserModel?.name ?? "Admin"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    // MARK: - Sidebar Item Component
    private func sidebarButton(title: String, icon: String, tag: Int) -> some View {
        let isSelected = selectedTab == tag
        return Button(action: {
            selectedTab = tag
            if tag == 1 && selectedTopicForWords == nil {
                selectedWordForInspector = nil
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AdminTheme.primary : AdminTheme.textSecondary)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AdminTheme.textPrimary : AdminTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AdminTheme.primaryLight : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - DASHBOARD (Redesigned Platform Overview & Quick Actions)
    private var adminDashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header Section
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Text("Good evening, \(sessionManager.currentUserModel?.name ?? "Admin") • Here's what's happening across your learning platform.")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // All systems operational pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AdminTheme.success)
                            .frame(width: 7, height: 7)
                        
                        Text("All systems operational")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AdminTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AdminTheme.border, lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal, 36)
                .padding(.top, 24)
                
                // Alert Banner (if any)
                if let err = viewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AdminTheme.warning)
                            .font(.system(size: 16))
                        
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(AdminTheme.warningBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AdminTheme.warning.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal, 36)
                }
                
                // 1. Structured Platform Overview (5 Clean Metric Cards)
                VStack(alignment: .leading, spacing: 14) {
                    Text("PLATFORM OVERVIEW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 36)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        metricCard(title: "Topics", value: "\(viewModel.topics.count)", trend: "+12.4%", icon: "square.stack.3d.up", tag: 1)
                        metricCard(title: "Vocabulary", value: "\(viewModel.words.count)", trend: "+8.4%", icon: "character.book.closed", tag: 1)
                        metricCard(title: "Quizzes", value: "\(viewModel.quizzes.count)", trend: "+4.2%", icon: "checklist", tag: 2)
                        metricCard(title: "Students", value: "\(viewModel.users.count)", trend: "+15.1%", icon: "person.2", tag: 3)
                        metricCard(title: "Average XP", value: "\(averageXP)", trend: "+6.8%", icon: "bolt", tag: 0)
                    }
                    .padding(.horizontal, 36)
                }
                
                // 2. Quick Actions Toolbar
                VStack(alignment: .leading, spacing: 14) {
                    Text("QUICK ACTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 36)
                    
                    HStack(spacing: 12) {
                        // Primary Action
                        Button(action: {
                            editingTopic = nil
                            topicName = ""
                            topicDesc = ""
                            topicImage = "folder"
                            showingTopicSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("New Topic")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(AdminTheme.primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Secondary Actions
                        Button(action: {
                            selectedTab = 1
                            if let firstTopic = viewModel.topics.first {
                                selectedTopicForWords = firstTopic
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Vocabulary")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            if let firstTopic = viewModel.topics.first {
                                selectedTopicForWords = firstTopic
                            }
                            importText = ""
                            importStep = 1
                            showingImportSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Import")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            Task { await viewModel.loadAllData() }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Sync")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                }
                
                // 3. System Status & Recent Activity (Dual Panels)
                HStack(alignment: .top, spacing: 20) {
                    // System Status Panel
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("System Status")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AdminTheme.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(AdminTheme.success)
                                .font(.system(size: 13))
                        }
                        
                        VStack(spacing: 12) {
                            systemStatusItem(name: "Firestore", status: "Operational", isActive: true)
                            Divider().background(AdminTheme.border)
                            systemStatusItem(name: "Firebase Authentication", status: "Operational", isActive: true)
                            Divider().background(AdminTheme.border)
                            systemStatusItem(name: "Realtime Sync", status: "Active", isActive: true)
                        }
                    }
                    .padding(20)
                    .background(AdminTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AdminTheme.border, lineWidth: 1)
                    )
                    .cornerRadius(12)
                    
                    // Recent Activity Panel
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AdminTheme.textPrimary)
                            Spacer()
                            Text("Audit Trail")
                                .font(.system(size: 11))
                                .foregroundColor(AdminTheme.textMuted)
                        }
                        
                        VStack(spacing: 12) {
                            activityItem(title: "Vocabulary database synced", time: "Just now", icon: "arrow.triangle.2.circlepath")
                            Divider().background(AdminTheme.border)
                            activityItem(title: "Topics verified with Firestore", time: "15 min ago", icon: "checkmark.circle")
                            Divider().background(AdminTheme.border)
                            activityItem(title: "Admin logged into system portal", time: "32 min ago", icon: "person.badge.shield.checkmark")
                        }
                    }
                    .padding(20)
                    .background(AdminTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AdminTheme.border, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
            }
        }
    }
    
    private var averageXP: Int {
        guard !viewModel.users.isEmpty else { return 0 }
        let total = viewModel.users.reduce(0) { $0 + $1.xp }
        return total / viewModel.users.count
    }
    
    // Metric Card Component
    private func metricCard(title: String, value: String, trend: String, icon: String, tag: Int) -> some View {
        Button(action: {
            if tag != 0 {
                selectedTab = tag
                selectedTopicForWords = nil
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AdminTheme.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                }
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AdminTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(trend)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AdminTheme.success)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AdminTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AdminTheme.border, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func systemStatusItem(name: String, status: String, isActive: Bool) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? AdminTheme.success : AdminTheme.warning)
                    .frame(width: 6, height: 6)
                
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AdminTheme.textPrimary)
            }
            
            Spacer()
            
            Text(status)
                .font(.system(size: 12))
                .foregroundColor(AdminTheme.textSecondary)
        }
    }
    
    private func activityItem(title: String, time: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AdminTheme.primary)
                .frame(width: 16)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AdminTheme.textPrimary)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11))
                .foregroundColor(AdminTheme.textMuted)
        }
    }
    
    // MARK: - TOPICS MAIN VIEW (High-Density macOS Table)
    private var topicsMainView: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Topics & Vocabulary")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("Manage learning curricula, topics, and vocabulary content.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    editingTopic = nil
                    topicName = ""
                    topicDesc = ""
                    topicImage = "folder"
                    showingTopicSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New Topic")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AdminTheme.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Toolbar Search & Sort
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    TextField("Search topics...", text: $viewModel.topicSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AdminTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AdminTheme.border, lineWidth: 1)
                )
                .cornerRadius(8)
                .frame(width: 280)
                
                Spacer()
                
                Picker("Sort", selection: $viewModel.selectedTopicSort) {
                    Text("Name A → Z").tag("A-Z")
                    Text("Name Z → A").tag("Z-A")
                    Text("Most Words").tag("Most Words")
                    Text("Least Words").tag("Least Words")
                }
                .frame(width: 160)
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 16)
            
            Divider().background(AdminTheme.border)
            
            // High Density Topics Table
            if viewModel.filteredTopics.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 40))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    Text("No topics found")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("Create your first topic to organize vocabulary lessons.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        Text("ICON").frame(width: 60, alignment: .leading)
                        Text("TOPIC").frame(width: 180, alignment: .leading)
                        Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading)
                        Text("WORDS").frame(width: 90, alignment: .trailing)
                        Text("STATUS").frame(width: 100, alignment: .center)
                        Text("ACTIONS").frame(width: 180, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AdminTheme.textMuted)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 10)
                    .background(AdminTheme.surfaceHover)
                    
                    Divider().background(AdminTheme.border)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.filteredTopics) { topic in
                                HStack(spacing: 0) {
                                    // SF Symbol Icon
                                    Image(systemName: topic.image.isEmpty ? "folder" : topic.image)
                                        .font(.system(size: 14))
                                        .foregroundColor(AdminTheme.primary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    // Topic Name
                                    Text(topic.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AdminTheme.textPrimary)
                                        .frame(width: 180, alignment: .leading)
                                    
                                    // Description
                                    Text(topic.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(AdminTheme.textSecondary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Words count
                                    Text("\(topic.totalWords)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(AdminTheme.textPrimary)
                                        .frame(width: 90, alignment: .trailing)
                                    
                                    // Status Badge (Active)
                                    HStack {
                                        Text("Active")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AdminTheme.success)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(AdminTheme.successBg)
                                            .cornerRadius(4)
                                    }
                                    .frame(width: 100, alignment: .center)
                                    
                                    // Actions
                                    HStack(spacing: 12) {
                                        Button("View words") {
                                            selectedTopicForWords = topic
                                            selectedWordForInspector = nil
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AdminTheme.primary)
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button("Edit") {
                                            editingTopic = topic
                                            topicName = topic.name
                                            topicDesc = topic.description
                                            topicImage = topic.image
                                            showingTopicSheet = true
                                        }
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(AdminTheme.textSecondary)
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button("Delete") {
                                            topicToDelete = topic
                                            showingDeleteTopicAlert = true
                                        }
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(AdminTheme.danger)
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .frame(width: 180, alignment: .trailing)
                                }
                                .padding(.horizontal, 36)
                                .padding(.vertical, 13)
                                .background(hoveredRowId == topic.id ? AdminTheme.surfaceHover : AdminTheme.surface)
                                .onHover { isHovered in
                                    hoveredRowId = isHovered ? topic.id : nil
                                }
                                
                                Divider().background(AdminTheme.border)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - VOCABULARY DETAIL VIEW (Table + Right-Side Detail Inspector)
    private func vocabularyDetailView(topic: Topic) -> some View {
        HStack(spacing: 0) {
            // Main Vocabulary Table Panel
            VStack(spacing: 0) {
                // Breadcrumb Navigation
                HStack(spacing: 6) {
                    Button(action: {
                        selectedTopicForWords = nil
                        selectedWordForInspector = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Topics")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(AdminTheme.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("/")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    Text(topic.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("/")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    Text("Vocabulary")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 36)
                .padding(.top, 18)
                .padding(.bottom, 8)
                
                // Header & Action Buttons
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(topic.name)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(AdminTheme.textPrimary)
                            
                            Text("\(topic.totalWords) words")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AdminTheme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AdminTheme.surfaceHover)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            importText = ""
                            importStep = 1
                            showingImportSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Import")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(7)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            editingWord = nil
                            wordText = ""
                            wordPhonetic = ""
                            wordMeaning = ""
                            wordExample = ""
                            wordImage = ""
                            wordAudio = ""
                            wordTopicId = topic.id
                            wordLevel = "Beginner"
                            showingWordSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Add Vocabulary")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AdminTheme.primary)
                            .cornerRadius(7)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 14)
                
                // Toolbar: Search, Level Filter, Sort
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        TextField("Search vocabulary...", text: $viewModel.wordSearchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(7)
                    .frame(width: 240)
                    
                    Picker("Level", selection: $viewModel.selectedLevelFilter) {
                        Text("Level: All").tag("All")
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    .frame(width: 140)
                    
                    Picker("Sort", selection: $viewModel.selectedWordSort) {
                        Text("Word A → Z").tag("A-Z")
                        Text("Word Z → A").tag("Z-A")
                        Text("Newest").tag("Newest")
                        Text("Oldest").tag("Oldest")
                    }
                    .frame(width: 140)
                    
                    Spacer()
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 14)
                
                Divider().background(AdminTheme.border)
                
                // Vocabulary High Density Table
                let wordsList = viewModel.filteredWords(for: topic.id)
                
                if wordsList.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Text("No vocabulary found")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Text("Add vocabulary words or import records from CSV/JSON.")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Header Row
                        HStack(spacing: 0) {
                            Text("WORD").frame(width: 160, alignment: .leading)
                            Text("PHONETIC").frame(width: 140, alignment: .leading)
                            Text("MEANING").frame(maxWidth: .infinity, alignment: .leading)
                            Text("LEVEL").frame(width: 110, alignment: .leading)
                            Text("ACTIONS").frame(width: 90, alignment: .trailing)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 10)
                        .background(AdminTheme.surfaceHover)
                        
                        Divider().background(AdminTheme.border)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(wordsList) { word in
                                    let isSelected = selectedWordForInspector?.id == word.id
                                    
                                    HStack(spacing: 0) {
                                        // Word
                                        Text(word.word)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AdminTheme.textPrimary)
                                            .frame(width: 160, alignment: .leading)
                                        
                                        // Phonetic
                                        Text(word.phonetic)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(AdminTheme.textSecondary)
                                            .frame(width: 140, alignment: .leading)
                                        
                                        // Meaning
                                        Text(word.meaning)
                                            .font(.system(size: 13))
                                            .foregroundColor(AdminTheme.textPrimary)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Level Badge (Pastel styling)
                                        levelBadgeView(level: word.level)
                                            .frame(width: 110, alignment: .leading)
                                        
                                        // Quick Actions
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                editingWord = word
                                                wordText = word.word
                                                wordPhonetic = word.phonetic
                                                wordMeaning = word.meaning
                                                wordExample = word.example
                                                wordImage = word.image
                                                wordAudio = word.audio
                                                wordTopicId = word.topicId
                                                wordLevel = word.level
                                                showingWordSheet = true
                                            }) {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AdminTheme.textSecondary)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                wordToDelete = word
                                                showingDeleteWordAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AdminTheme.danger)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .frame(width: 90, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 36)
                                    .padding(.vertical, 12)
                                    .background(isSelected ? AdminTheme.primaryLight : (hoveredRowId == word.id ? AdminTheme.surfaceHover : AdminTheme.surface))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedWordForInspector = word
                                        }
                                    }
                                    .onHover { isHovered in
                                        hoveredRowId = isHovered ? word.id : nil
                                    }
                                    
                                    Divider().background(AdminTheme.border)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Right-side Detail Inspector Drawer
            if let word = selectedWordForInspector {
                Divider().background(AdminTheme.border)
                
                vocabularyInspectorPanel(word: word, topicName: topic.name)
                    .frame(width: 320)
                    .background(AdminTheme.surface)
                    .transition(.move(edge: .trailing))
            }
        }
    }
    
    // Level Badge Helper (Pastel tones)
    private func levelBadgeView(level: String) -> some View {
        let (bg, text) = levelColors(level)
        return Text(level)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(bg)
            .cornerRadius(4)
    }
    
    private func levelColors(_ lvl: String) -> (Color, Color) {
        switch lvl.lowercased() {
        case "beginner":
            return (AdminTheme.successBg, AdminTheme.success)
        case "intermediate":
            return (AdminTheme.primaryLight, AdminTheme.primary)
        case "advanced":
            return (AdminTheme.dangerBg, AdminTheme.danger)
        default:
            return (AdminTheme.surfaceHover, AdminTheme.textSecondary)
        }
    }
    
    // Right-side Inspector Panel Component
    private func vocabularyInspectorPanel(word: VocabularyWord, topicName: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Inspector Header
            HStack {
                Text("VOCABULARY DETAILS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AdminTheme.textMuted)
                    .tracking(0.8)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedWordForInspector = nil
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AdminTheme.textSecondary)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(18)
            
            Divider().background(AdminTheme.border)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Word & Phonetics Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.word)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Text(word.phonetic)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    
                    // Classification Tags
                    HStack(spacing: 8) {
                        levelBadgeView(level: word.level)
                        
                        Text(topicName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AdminTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AdminTheme.surfaceHover)
                            .cornerRadius(4)
                    }
                    
                    Divider().background(AdminTheme.border)
                    
                    // Meaning Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MEANING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Text(word.meaning)
                            .font(.system(size: 14))
                            .foregroundColor(AdminTheme.textPrimary)
                    }
                    
                    // Example Section
                    if !word.example.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EXAMPLE SENTENCE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AdminTheme.textMuted)
                            
                            Text("\"\(word.example)\"")
                                .font(.system(size: 13))
                                .foregroundColor(AdminTheme.textSecondary)
                                .italic()
                        }
                    }
                    
                    Divider().background(AdminTheme.border)
                    
                    // Media Section (Image Preview & Audio Preview)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MEDIA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        // Image Preview
                        if !word.image.isEmpty, let url = URL(string: word.image) {
                            AsyncImage(url: url) { img in
                                img.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .cornerRadius(6)
                                    .clipped()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AdminTheme.surfaceHover)
                                    .frame(height: 120)
                                    .overlay(ProgressView())
                            }
                        }
                        
                        // Audio Preview
                        HStack {
                            Text("Pronunciation Audio")
                                .font(.system(size: 12))
                                .foregroundColor(AdminTheme.textSecondary)
                            
                            Spacer()
                            
                            AudioPreviewButton(audioUrlString: word.audio)
                        }
                        .padding(10)
                        .background(AdminTheme.surfaceHover)
                        .cornerRadius(6)
                    }
                    
                    Spacer(minLength: 24)
                    
                    // Actions Footer
                    HStack(spacing: 10) {
                        Button(action: {
                            editingWord = word
                            wordText = word.word
                            wordPhonetic = word.phonetic
                            wordMeaning = word.meaning
                            wordExample = word.example
                            wordImage = word.image
                            wordAudio = word.audio
                            wordTopicId = word.topicId
                            wordLevel = word.level
                            showingWordSheet = true
                        }) {
                            Text("Edit Word")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AdminTheme.primaryLight)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            wordToDelete = word
                            showingDeleteWordAlert = true
                        }) {
                            Text("Delete")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AdminTheme.dangerBg)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(18)
            }
        }
    }
    
    // MARK: - QUIZZES VIEW (Clean Question Cards & Actions)
    private var adminQuizzesView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quizzes")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("\(viewModel.quizzes.count) question items available in database.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        quizImportText = ""
                        showingQuizImportSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Import Quizzes")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AdminTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AdminTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        editingQuiz = nil
                        quizQuestion = ""
                        quizAnswerA = ""
                        quizAnswerB = ""
                        quizAnswerC = ""
                        quizAnswerD = ""
                        quizCorrectAnswer = ""
                        quizTopicId = viewModel.topics.first?.id ?? "travel"
                        quizLevel = "Beginner"
                        quizType = "multiple_choice"
                        showingQuizSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("New Quiz")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AdminTheme.primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider().background(AdminTheme.border)
            
            // Search & Filter Toolbar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    TextField("Search quizzes by question or answer...", text: $viewModel.quizSearchText)
                        .font(.system(size: 13))
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AdminTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(6)
                .frame(maxWidth: 320)
                
                // Topic filter picker
                Picker("Topic", selection: $viewModel.selectedQuizTopicFilter) {
                    Text("All Topics").tag("All")
                    ForEach(viewModel.topics) { t in
                        Text(t.name).tag(t.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                Spacer()
                
                Text("\(viewModel.filteredQuizzes.count) matching")
                    .font(.system(size: 12))
                    .foregroundColor(AdminTheme.textMuted)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .background(AdminTheme.surfaceHover)
            
            Divider().background(AdminTheme.border)
            
            // Quizzes Cards
            ScrollView {
                if viewModel.filteredQuizzes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 40))
                            .foregroundColor(AdminTheme.textMuted)
                        Text("No quizzes found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.filteredQuizzes.enumerated()), id: \.element.id) { index, quiz in
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .center) {
                                    HStack(spacing: 6) {
                                        Text(String(format: "QUIZ #%04d", index + 1))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AdminTheme.primary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AdminTheme.primaryLight)
                                            .cornerRadius(4)
                                        
                                        if let topicName = viewModel.topics.first(where: { $0.id == quiz.topicId })?.name {
                                            Text(topicName)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(AdminTheme.textSecondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AdminTheme.surfaceHover)
                                                .cornerRadius(4)
                                        }
                                        
                                        if let level = quiz.level {
                                            levelBadgeView(level: level)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Edit and Delete buttons
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            editingQuiz = quiz
                                            quizQuestion = quiz.question
                                            quizAnswerA = quiz.answers.indices.contains(0) ? quiz.answers[0] : ""
                                            quizAnswerB = quiz.answers.indices.contains(1) ? quiz.answers[1] : ""
                                            quizAnswerC = quiz.answers.indices.contains(2) ? quiz.answers[2] : ""
                                            quizAnswerD = quiz.answers.indices.contains(3) ? quiz.answers[3] : ""
                                            quizCorrectAnswer = quiz.correctAnswer
                                            quizTopicId = quiz.topicId
                                            quizLevel = quiz.level ?? "Beginner"
                                            quizType = quiz.type
                                            showingQuizSheet = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 12))
                                                .foregroundColor(AdminTheme.textSecondary)
                                                .padding(6)
                                                .background(AdminTheme.surfaceHover)
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            quizToDelete = quiz
                                            showingDeleteQuizAlert = true
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundColor(AdminTheme.danger)
                                                .padding(6)
                                                .background(AdminTheme.dangerBg)
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Text(quiz.question)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AdminTheme.textPrimary)
                                
                                VStack(spacing: 8) {
                                    ForEach(Array(quiz.answers.enumerated()), id: \.offset) { optIndex, ans in
                                        let isCorrect = ans == quiz.correctAnswer
                                        let letter = ["A", "B", "C", "D"][optIndex % 4]
                                        
                                        HStack(spacing: 10) {
                                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(isCorrect ? AdminTheme.success : AdminTheme.textMuted)
                                            
                                            Text("\(letter)   \(ans)")
                                                .font(.system(size: 13, weight: isCorrect ? .semibold : .regular))
                                                .foregroundColor(isCorrect ? AdminTheme.textPrimary : AdminTheme.textSecondary)
                                            
                                            Spacer()
                                            
                                            if isCorrect {
                                                Text("Correct Answer")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(AdminTheme.success)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isCorrect ? AdminTheme.successBg : AdminTheme.surfaceHover)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isCorrect ? AdminTheme.success.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(18)
                            .background(AdminTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AdminTheme.border, lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - LISTENING EXERCISES VIEW (Audio Dictation Management Table)
    private var adminListeningView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Listening & Dictation")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("\(viewModel.listeningExercises.count) dictation exercises available in database.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        listeningImportText = ""
                        showingListeningImportSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Import Listening")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AdminTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AdminTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        editingListening = nil
                        listeningSentence = ""
                        listeningTranslation = ""
                        listeningTopicId = viewModel.topics.first?.id ?? "travel"
                        listeningLevel = "Beginner"
                        listeningHint = ""
                        listeningAudioUrl = ""
                        showingListeningSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("New Exercise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AdminTheme.primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider().background(AdminTheme.border)
            
            // Search & Filter Toolbar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    TextField("Search sentence or translation...", text: $viewModel.listeningSearchText)
                        .font(.system(size: 13))
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AdminTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(6)
                .frame(maxWidth: 320)
                
                // Topic filter picker
                Picker("Topic", selection: $viewModel.selectedListeningTopicFilter) {
                    Text("All Topics").tag("All")
                    ForEach(viewModel.topics) { t in
                        Text(t.name).tag(t.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                // Level filter picker
                Picker("Level", selection: $viewModel.selectedListeningLevelFilter) {
                    Text("All Levels").tag("All")
                    Text("Beginner").tag("Beginner")
                    Text("Intermediate").tag("Intermediate")
                    Text("Advanced").tag("Advanced")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 140)
                
                Spacer()
                
                Text("\(viewModel.filteredListeningExercises.count) matching")
                    .font(.system(size: 12))
                    .foregroundColor(AdminTheme.textMuted)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .background(AdminTheme.surfaceHover)
            
            Divider().background(AdminTheme.border)
            
            // Listening Exercises Table
            ScrollView {
                if viewModel.filteredListeningExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "headphones")
                            .font(.system(size: 40))
                            .foregroundColor(AdminTheme.textMuted)
                        Text("No listening exercises found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredListeningExercises) { item in
                            HStack(alignment: .center, spacing: 16) {
                                // Audio play preview button
                                Button(action: {
                                    speakSentence(item.sentence)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(AdminTheme.primaryLight)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AdminTheme.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.sentence)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AdminTheme.textPrimary)
                                    
                                    Text(item.translation)
                                        .font(.system(size: 12))
                                        .foregroundColor(AdminTheme.textSecondary)
                                    
                                    if let hint = item.hint, !hint.isEmpty {
                                        Text("Hint: \(hint)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AdminTheme.warning)
                                    }
                                }
                                
                                Spacer()
                                
                                // Topic badge
                                if let topicName = viewModel.topics.first(where: { $0.id == item.topicId })?.name {
                                    Text(topicName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AdminTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AdminTheme.surfaceHover)
                                        .cornerRadius(4)
                                }
                                
                                // Level badge
                                levelBadgeView(level: item.level)
                                
                                // Action buttons
                                HStack(spacing: 8) {
                                    Button(action: {
                                        editingListening = item
                                        listeningSentence = item.sentence
                                        listeningTranslation = item.translation
                                        listeningTopicId = item.topicId
                                        listeningLevel = item.level
                                        listeningHint = item.hint ?? ""
                                        listeningAudioUrl = item.audioUrl ?? ""
                                        showingListeningSheet = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12))
                                            .foregroundColor(AdminTheme.textSecondary)
                                            .padding(6)
                                            .background(AdminTheme.surfaceHover)
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        listeningToDelete = item
                                        showingDeleteListeningAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundColor(AdminTheme.danger)
                                            .padding(6)
                                            .background(AdminTheme.dangerBg)
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(14)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - STUDENTS VIEW (High-density User Management Table)
    private var adminUsersView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Students")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("\(viewModel.users.count) registered learners enrolled.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider().background(AdminTheme.border)
            
            // Students Table
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("STUDENT").frame(width: 220, alignment: .leading)
                    Text("EMAIL").frame(maxWidth: .infinity, alignment: .leading)
                    Text("XP").frame(width: 110, alignment: .trailing)
                    Text("ACTIVITY").frame(width: 120, alignment: .center)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AdminTheme.textMuted)
                .padding(.horizontal, 36)
                .padding(.vertical, 10)
                .background(AdminTheme.surfaceHover)
                
                Divider().background(AdminTheme.border)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.users) { user in
                            HStack(spacing: 0) {
                                // Initials Avatar + Name
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(AdminTheme.deepNavy.opacity(0.85))
                                            .frame(width: 28, height: 28)
                                        
                                        Text(String(user.name.prefix(2)).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(user.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AdminTheme.textPrimary)
                                }
                                .frame(width: 220, alignment: .leading)
                                
                                // Email
                                Text(user.email)
                                    .font(.system(size: 12))
                                    .foregroundColor(AdminTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // XP Score Badge
                                Text("\(user.xp) XP")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AdminTheme.success)
                                    .frame(width: 110, alignment: .trailing)
                                
                                // Activity Status
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(AdminTheme.success)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("Active")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AdminTheme.textSecondary)
                                }
                                .frame(width: 120, alignment: .center)
                            }
                            .padding(.horizontal, 36)
                            .padding(.vertical, 12)
                            .background(AdminTheme.surface)
                            
                            Divider().background(AdminTheme.border)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - SETTINGS VIEW
    private var adminSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    Text("Platform configuration and system metadata.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                
                Divider().background(AdminTheme.border)
                
                // Administrator Information Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("ADMINISTRATOR PROFILE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    VStack(spacing: 12) {
                        settingRow(label: "Name", value: sessionManager.currentUserModel?.name ?? "Administrator")
                        settingRow(label: "Email", value: sessionManager.currentUserModel?.email ?? "admin@app.com")
                        settingRow(label: "Role", value: "Master Administrator")
                    }
                    .padding(16)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(10)
                }
                
                // Cloud Infrastructure Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("DATABASE INFRASTRUCTURE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    VStack(spacing: 12) {
                        settingRow(label: "Backend Provider", value: "Google Cloud Firestore")
                        settingRow(label: "Authentication", value: "Firebase Auth (macOS Keychain Enabled)")
                        settingRow(label: "Catalyst Build", value: "Native Desktop macOS Target")
                    }
                    .padding(16)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
        }
    }
    
    private func settingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AdminTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AdminTheme.textPrimary)
        }
    }
    
    // MARK: - ACTIVITY LOG VIEW
    private var adminActivityLogView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Activity Log")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AdminTheme.textPrimary)
                Text("Chronological audit log of operations across collections.")
                    .font(.system(size: 13))
                    .foregroundColor(AdminTheme.textSecondary)
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider().background(AdminTheme.border)
            
            ScrollView {
                VStack(spacing: 12) {
                    activityLogRow(title: "Database loaded and synced", desc: "Loaded topics and vocabulary collections", time: "Just now", status: "Success")
                    activityLogRow(title: "Session initialized", desc: "Admin credentials authenticated via Keychain", time: "15 min ago", status: "Success")
                    activityLogRow(title: "Security rules verified", desc: "Firestore rules validation active", time: "1 hr ago", status: "Success")
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 20)
            }
        }
    }
    
    private func activityLogRow(title: String, desc: String, time: String, status: String) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AdminTheme.success)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AdminTheme.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(AdminTheme.textSecondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11))
                .foregroundColor(AdminTheme.textMuted)
        }
        .padding(14)
        .background(AdminTheme.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
        .cornerRadius(8)
    }
    
    // MARK: - TOPIC FORM SHEET
    private var topicFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("GENERAL")) {
                    TextField("Topic Name", text: $topicName)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        TextEditor(text: $topicDesc)
                            .frame(height: 80)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AdminTheme.border, lineWidth: 1))
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("APPEARANCE")) {
                    HStack(spacing: 12) {
                        TextField("SF Symbol (e.g. folder, airplane, book)", text: $topicImage)
                        
                        Image(systemName: topicImage.isEmpty ? "folder" : topicImage)
                            .font(.system(size: 16))
                            .foregroundColor(AdminTheme.primary)
                            .frame(width: 36, height: 36)
                            .background(AdminTheme.surfaceHover)
                            .cornerRadius(6)
                    }
                }
                
                Section(header: Text("SETTINGS")) {
                    HStack {
                        Text("Total Vocabulary")
                            .font(.system(size: 13))
                        Spacer()
                        Text("Automatically calculated")
                            .font(.system(size: 12))
                            .foregroundColor(AdminTheme.textMuted)
                    }
                }
            }
            .navigationTitle(editingTopic == nil ? "Create New Topic" : "Edit Topic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTopicSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTopic == nil ? "Create Topic" : "Save Changes") {
                        Task {
                            await viewModel.saveTopic(
                                id: editingTopic?.id,
                                name: topicName,
                                description: topicDesc,
                                image: topicImage
                            )
                            showingTopicSheet = false
                        }
                    }
                    .disabled(topicName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - WORD FORM SHEET
    private var wordFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("WORD")) {
                    TextField("Word", text: $wordText)
                    TextField("Phonetic (IPA)", text: $wordPhonetic)
                }
                
                Section(header: Text("MEANING")) {
                    TextField("Definition / Nghĩa", text: $wordMeaning)
                    TextField("Example Sentence", text: $wordExample)
                }
                
                Section(header: Text("CLASSIFICATION")) {
                    Picker("Level", selection: $wordLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    
                    Picker("Topic", selection: $wordTopicId) {
                        ForEach(viewModel.topics) { topic in
                            Text(topic.name).tag(topic.id)
                        }
                    }
                    .disabled(editingWord == nil)
                }
                
                Section(header: Text("MEDIA")) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Image URL", text: $wordImage)
                        if !wordImage.isEmpty, let url = URL(string: wordImage) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 90)
                                    .cornerRadius(6)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Audio URL", text: $wordAudio)
                        AudioPreviewButton(audioUrlString: wordAudio)
                    }
                }
            }
            .navigationTitle(editingWord == nil ? "Add Vocabulary" : "Edit Vocabulary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingWordSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingWord == nil ? "Add Word" : "Save Changes") {
                        Task {
                            await viewModel.saveWord(
                                id: editingWord?.id,
                                word: wordText,
                                phonetic: wordPhonetic,
                                meaning: wordMeaning,
                                example: wordExample,
                                image: wordImage,
                                audio: wordAudio,
                                topicId: wordTopicId,
                                level: wordLevel
                            )
                            showingWordSheet = false
                        }
                    }
                    .disabled(wordText.isEmpty || wordMeaning.isEmpty)
                }
            }
        }
    }
    
    // MARK: - IMPORT WIZARD (3-Step Modern Flow)
    private var importWizardSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step Indicator Header
                HStack(spacing: 16) {
                    wizardStepBadge(step: 1, label: "Upload", isActive: importStep >= 1)
                    Rectangle().fill(importStep >= 2 ? AdminTheme.primary : AdminTheme.border).frame(width: 30, height: 1)
                    wizardStepBadge(step: 2, label: "Review", isActive: importStep >= 2)
                    Rectangle().fill(importStep >= 3 ? AdminTheme.primary : AdminTheme.border).frame(width: 30, height: 1)
                    wizardStepBadge(step: 3, label: "Complete", isActive: importStep >= 3)
                }
                .padding(.vertical, 14)
                .background(AdminTheme.surfaceHover)
                
                Divider().background(AdminTheme.border)
                
                // Wizard Body
                if importStep == 1 {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Import Raw Data")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AdminTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle(isOn: $isImportJSON) {
                                Text("JSON Mode")
                                    .font(.system(size: 12))
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        .padding(.horizontal, 24)
                        
                        TextEditor(text: $importText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AdminTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(AdminTheme.surface)
                            .frame(height: 220)
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .padding(.horizontal, 24)
                        
                        HStack {
                            Button("Load Sample Template") {
                                if isImportJSON {
                                    importText = """
                                    [
                                      {
                                        "word": "Airport",
                                        "phonetic": "/ˈeəpɔːt/",
                                        "meaning": "Sân bay",
                                        "example": "See you at the airport",
                                        "level": "Beginner"
                                      }
                                    ]
                                    """
                                } else {
                                    importText = "word,phonetic,meaning,example,image,audio,topicId,level\nAirport,/ˈeəpɔːt/,Sân bay,See you at the airport,,,travel,Beginner"
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(AdminTheme.primary)
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        Divider().background(AdminTheme.border)
                        
                        HStack {
                            Button("Cancel") { showingImportSheet = false }
                            Spacer()
                            Button("Next: Review") {
                                if let topic = selectedTopicForWords {
                                    viewModel.parseImportData(text: importText, isJSON: isImportJSON, currentTopicId: topic.id)
                                    importStep = 2
                                }
                            }
                            .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(18)
                    }
                } else if importStep == 2 {
                    VStack(spacing: 14) {
                        // Counters
                        HStack(spacing: 16) {
                            Text("✓ \(viewModel.importStats.validCount) valid")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.success)
                            
                            Text("⚠ \(viewModel.importStats.duplicateCount) duplicate")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.warning)
                            
                            Text("× \(viewModel.importStats.invalidCount) invalid")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.danger)
                        }
                        .padding(.top, 12)
                        
                        // Validation Table
                        VStack(spacing: 0) {
                            HStack {
                                Text("STATUS").frame(width: 80, alignment: .leading)
                                Text("WORD").frame(width: 120, alignment: .leading)
                                Text("MEANING").frame(width: 140, alignment: .leading)
                                Text("LEVEL").frame(width: 80, alignment: .leading)
                                Text("REASON").frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AdminTheme.surfaceHover)
                            
                            Divider().background(AdminTheme.border)
                            
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.parsedImportRecords) { record in
                                        HStack {
                                            Text(record.status.rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(record.status == .valid ? AdminTheme.success : (record.status == .duplicate ? AdminTheme.warning : AdminTheme.danger))
                                                .frame(width: 80, alignment: .leading)
                                            
                                            Text(record.word)
                                                .font(.system(size: 12, weight: .semibold))
                                                .frame(width: 120, alignment: .leading)
                                            
                                            Text(record.meaning)
                                                .font(.system(size: 12))
                                                .frame(width: 140, alignment: .leading)
                                            
                                            Text(record.level)
                                                .font(.system(size: 11))
                                                .frame(width: 80, alignment: .leading)
                                            
                                            Text(record.statusReason)
                                                .font(.system(size: 11))
                                                .foregroundColor(AdminTheme.textSecondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        Divider().background(AdminTheme.border)
                                    }
                                }
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        Divider().background(AdminTheme.border)
                        
                        HStack {
                            Button("Back") { importStep = 1 }
                            Spacer()
                            Button("Import \(viewModel.importStats.validCount) Records") {
                                Task {
                                    await viewModel.commitImportedRecords()
                                    importStep = 3
                                }
                            }
                            .disabled(viewModel.importStats.validCount == 0)
                        }
                        .padding(18)
                    }
                } else if importStep == 3 {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AdminTheme.success)
                        
                        Text("Import Complete")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Text("\(viewModel.importStats.validCount) vocabulary records successfully synchronized to Firestore.")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        Spacer()
                        Divider().background(AdminTheme.border)
                        
                        Button("Done") { showingImportSheet = false }
                            .padding(18)
                    }
                }
            }
            .navigationTitle("Import Vocabulary Wizard")
        }
    }
    
    private func wizardStepBadge(step: Int, label: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? AdminTheme.primary : AdminTheme.border)
                    .frame(width: 20, height: 20)
                
                Text("\(step)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isActive ? .white : AdminTheme.textMuted)
            }
            
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? AdminTheme.textPrimary : AdminTheme.textMuted)
        }
    }
    
    // MARK: - DELETE ALERTS
    private var deleteTopicAlert: Alert {
        guard let topic = topicToDelete else { return Alert(title: Text("Error")) }
        if topic.totalWords > 0 {
            return Alert(
                title: Text("Cannot Delete Topic"),
                message: Text("“\(topic.name)” currently contains \(topic.totalWords) vocabulary words. You must delete or reassign its vocabulary words first."),
                primaryButton: .default(Text("View Vocabulary")) { selectedTopicForWords = topic },
                secondaryButton: .cancel(Text("Cancel"))
            )
        } else {
            return Alert(
                title: Text("Delete Topic?"),
                message: Text("Are you sure you want to delete “\(topic.name)”? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteTopic(topicId: topic.id) }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    private var deleteWordAlert: Alert {
        guard let word = wordToDelete else { return Alert(title: Text("Error")) }
        return Alert(
            title: Text("Delete Vocabulary Word?"),
            message: Text("Are you sure you want to delete “\(word.word)”? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                Task {
                    await viewModel.deleteWord(wordId: word.id, topicId: word.topicId)
                    if selectedWordForInspector?.id == word.id {
                        selectedWordForInspector = nil
                    }
                }
            },
            secondaryButton: .cancel(Text("Cancel"))
        )
    }
    
    // MARK: - SKELETON & ERROR VIEWS
    private var tableSkeletonView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Loading data...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AdminTheme.textMuted)
            
            VStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AdminTheme.border)
                            .frame(width: 40, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AdminTheme.border)
                            .frame(width: 120, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AdminTheme.border)
                            .frame(maxWidth: .infinity)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AdminTheme.border)
                            .frame(width: 60, height: 16)
                    }
                    .padding()
                    .background(AdminTheme.surface)
                    .cornerRadius(8)
                }
            }
        }
        .padding(36)
    }
    
    private func errorView(errorMsg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.octagon")
                .font(.system(size: 40))
                .foregroundColor(AdminTheme.danger)
            
            Text("Unable to load data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AdminTheme.textPrimary)
            
            Text(errorMsg)
                .font(.system(size: 13))
                .foregroundColor(AdminTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await viewModel.loadAllData() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AdminTheme.primary)
            .cornerRadius(8)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(36)
    }
    // MARK: - Pronunciation Speech Synthesizer Helper
    private func speakSentence(_ text: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - QUIZ FORM SHEET
    private var quizFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("QUESTION")) {
                    TextField("Question content (e.g. Nghĩa của từ 'airport' là gì?)", text: $quizQuestion)
                }
                
                Section(header: Text("ANSWER OPTIONS")) {
                    TextField("Option A", text: $quizAnswerA)
                    TextField("Option B", text: $quizAnswerB)
                    TextField("Option C", text: $quizAnswerC)
                    TextField("Option D", text: $quizAnswerD)
                }
                
                Section(header: Text("CORRECT ANSWER")) {
                    Picker("Select Correct Answer", selection: $quizCorrectAnswer) {
                        if !quizAnswerA.isEmpty { Text("A: \(quizAnswerA)").tag(quizAnswerA) }
                        if !quizAnswerB.isEmpty { Text("B: \(quizAnswerB)").tag(quizAnswerB) }
                        if !quizAnswerC.isEmpty { Text("C: \(quizAnswerC)").tag(quizAnswerC) }
                        if !quizAnswerD.isEmpty { Text("D: \(quizAnswerD)").tag(quizAnswerD) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("CLASSIFICATION")) {
                    Picker("Topic", selection: $quizTopicId) {
                        ForEach(viewModel.topics) { topic in
                            Text(topic.name).tag(topic.id)
                        }
                    }
                    
                    Picker("Level", selection: $quizLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    
                    Picker("Type", selection: $quizType) {
                        Text("Multiple Choice").tag("multiple_choice")
                        Text("Fill in Blank").tag("fill_blank")
                        Text("Listening").tag("listening")
                    }
                }
            }
            .navigationTitle(editingQuiz == nil ? "Add New Quiz" : "Edit Quiz")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingQuizSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingQuiz == nil ? "Add Quiz" : "Save Changes") {
                        Task {
                            let answers = [quizAnswerA, quizAnswerB, quizAnswerC, quizAnswerD].filter { !$0.isEmpty }
                            let correct = quizCorrectAnswer.isEmpty ? (answers.first ?? "") : quizCorrectAnswer
                            await viewModel.saveQuiz(
                                id: editingQuiz?.id,
                                question: quizQuestion,
                                answers: answers,
                                correctAnswer: correct,
                                topicId: quizTopicId,
                                type: quizType,
                                level: quizLevel
                            )
                            showingQuizSheet = false
                        }
                    }
                    .disabled(quizQuestion.isEmpty || quizAnswerA.isEmpty || quizAnswerB.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper to resolve or auto-create Topic from dataset name
    private func resolveTopicId(
        topicMode: String,
        selectedTopicId: String,
        newTopicName: String,
        newTopicDesc: String
    ) async -> String {
        if topicMode == "existing" && !selectedTopicId.isEmpty {
            return selectedTopicId
        }
        
        let trimmedName = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return selectedTopicId.isEmpty ? (viewModel.topics.first?.id ?? "general") : selectedTopicId
        }
        
        // Generate clean alphanumeric slug ID from Vietnamese title
        var slug = trimmedName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        
        if slug.isEmpty {
            slug = "topic_\(Int(Date().timeIntervalSince1970))"
        }
        
        // Save Topic to Firestore if it does not already exist
        if !viewModel.topics.contains(where: { $0.id == slug }) {
            let desc = newTopicDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Bộ dữ liệu \(trimmedName)"
                : newTopicDesc
            let defaultImg = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3"
            await viewModel.saveTopic(id: slug, name: trimmedName, description: desc, image: defaultImg)
        }
        
        return slug
    }
    
    // MARK: - QUIZ IMPORT WIZARD SHEET
    private var quizImportWizardSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Bộ dữ liệu / Topic
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. CHỌN HOẶC TẠO BỘ DỮ LIỆU (CHỦ ĐỀ)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AdminTheme.accentBlue)
                            .tracking(0.5)
                        
                        Picker("Bộ dữ liệu", selection: $quizImportTopicMode) {
                            Text("Chọn bộ có sẵn").tag("existing")
                            Text("Tạo bộ mới (+)").tag("new")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 320)
                        
                        if quizImportTopicMode == "existing" {
                            HStack(spacing: 12) {
                                Text("Bộ dữ liệu đích:")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AdminTheme.textSecondary)
                                
                                Picker("Chủ đề", selection: $quizImportSelectedTopicId) {
                                    ForEach(viewModel.topics) { t in
                                        Text(t.name).tag(t.id)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Nhập tên bộ dữ liệu mới (ví dụ: Công nghệ, Lập trình AI...)", text: $quizImportNewTopicName)
                                    .font(.system(size: 13))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .padding(10)
                                    .background(AdminTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                                
                                TextField("Mô tả bộ dữ liệu (tùy chọn)", text: $quizImportNewTopicDesc)
                                    .font(.system(size: 12))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .padding(8)
                                    .background(AdminTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(14)
                    .background(AdminTheme.surfaceHover)
                    .cornerRadius(8)
                    
                    // Section 2: Dữ liệu câu hỏi
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("2. DỮ LIỆU CÂU HỎI TRẮC NGHIỆM")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Picker("Format", selection: $isQuizImportJSON) {
                                Text("CSV").tag(false)
                                Text("JSON").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        Text(isQuizImportJSON
                             ? "JSON Format: [{\"question\": \"...\", \"answers\": [\"A\",\"B\",\"C\",\"D\"], \"correctAnswer\": \"...\", \"level\": \"Beginner\"}]"
                             : "CSV Format: question,answerA,answerB,answerC,answerD,correctAnswer,level (hoặc có thêm topicId)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AdminTheme.textSecondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AdminTheme.surfaceHover)
                            .cornerRadius(6)
                        
                        TextEditor(text: $quizImportText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AdminTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(AdminTheme.surface)
                            .frame(minHeight: 180)
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Button("Clear") { quizImportText = "" }
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        Spacer()
                        
                        Button("Import vào Bộ Dữ Liệu") {
                            Task {
                                await importQuizzesData(
                                    text: quizImportText,
                                    isJSON: isQuizImportJSON,
                                    topicMode: quizImportTopicMode,
                                    selectedTopicId: quizImportSelectedTopicId,
                                    newTopicName: quizImportNewTopicName,
                                    newTopicDesc: quizImportNewTopicDesc
                                )
                                showingQuizImportSheet = false
                            }
                        }
                        .disabled(quizImportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (quizImportTopicMode == "new" && quizImportNewTopicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(AdminTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Import Quizzes vào Bộ Dữ Liệu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showingQuizImportSheet = false }
                }
            }
        }
        .frame(minWidth: 580, minHeight: 520)
    }
    
    // Helper to parse a single CSV line with quote escaping and stripping support
    private func parseCSVRow(_ row: String) -> [String] {
        var results: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                var val = current.trimmingCharacters(in: .whitespaces)
                if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
                    val = String(val.dropFirst().dropLast())
                }
                results.append(val)
                current = ""
            } else {
                current.append(char)
            }
        }
        var val = current.trimmingCharacters(in: .whitespaces)
        if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
            val = String(val.dropFirst().dropLast())
        }
        results.append(val)
        return results
    }
    
    // Helper to parse and import Quizzes
    private func importQuizzesData(
        text: String,
        isJSON: Bool,
        topicMode: String,
        selectedTopicId: String,
        newTopicName: String,
        newTopicDesc: String
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let resolvedTopicId = await resolveTopicId(
            topicMode: topicMode,
            selectedTopicId: selectedTopicId,
            newTopicName: newTopicName,
            newTopicDesc: newTopicDesc
        )
        
        if isJSON {
            struct LooseQuiz: Decodable {
                let question: String?
                let answers: [String]?
                let correctAnswer: String?
                let topicId: String?
                let level: String?
                let type: String?
            }
            guard let data = trimmed.data(using: .utf8),
                  let items = try? JSONDecoder().decode([LooseQuiz].self, from: data) else { return }
            
            for item in items {
                guard let q = item.question, !q.isEmpty,
                      let ans = item.answers, ans.count >= 2 else { continue }
                let correct = item.correctAnswer ?? ans[0]
                let lvl = item.level ?? "Beginner"
                let t = item.type ?? "multiple_choice"
                await viewModel.saveQuiz(id: nil, question: q, answers: ans, correctAnswer: correct, topicId: resolvedTopicId, type: t, level: lvl)
            }
        } else {
            let lines = trimmed.components(separatedBy: .newlines)
            var startIndex = 0
            if lines.indices.contains(0) && lines[0].lowercased().contains("question") {
                startIndex = 1
            }
            for i in startIndex..<lines.count {
                let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty { continue }
                let fields = parseCSVRow(line)
                if fields.count >= 6 {
                    let q = fields[0]
                    let a = fields[1]
                    let b = fields[2]
                    let c = fields.indices.contains(3) ? fields[3] : ""
                    let d = fields.indices.contains(4) ? fields[4] : ""
                    let correct = fields[5]
                    
                    var lvl = "Beginner"
                    
                    if fields.count >= 8 {
                        if !fields[7].isEmpty { lvl = fields[7] }
                    } else if fields.count == 7 {
                        let f6 = fields[6]
                        if ["beginner", "intermediate", "advanced"].contains(f6.lowercased()) {
                            lvl = f6.capitalized
                        }
                    }
                    
                    let ans = [a, b, c, d].filter { !$0.isEmpty }
                    await viewModel.saveQuiz(id: nil, question: q, answers: ans, correctAnswer: correct, topicId: resolvedTopicId, type: "multiple_choice", level: lvl)
                }
            }
        }
        
        // Reload all data so new topics and questions reflect immediately
        await viewModel.loadAllData()
        viewModel.selectedQuizTopicFilter = "All"
    }
    
    // MARK: - LISTENING FORM SHEET
    private var listeningFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("SENTENCE")) {
                    TextField("English sentence (e.g. I will meet you at the airport.)", text: $listeningSentence)
                        .foregroundColor(AdminTheme.textPrimary)
                    TextField("Vietnamese translation", text: $listeningTranslation)
                        .foregroundColor(AdminTheme.textPrimary)
                }
                
                Section(header: Text("CLASSIFICATION")) {
                    Picker("Topic", selection: $listeningTopicId) {
                        ForEach(viewModel.topics) { topic in
                            Text(topic.name).tag(topic.id)
                        }
                    }
                    
                    Picker("Level", selection: $listeningLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                }
                
                Section(header: Text("EXTRAS")) {
                    TextField("Hint (optional keyword)", text: $listeningHint)
                        .foregroundColor(AdminTheme.textPrimary)
                    TextField("Custom Audio URL (optional)", text: $listeningAudioUrl)
                        .foregroundColor(AdminTheme.textPrimary)
                }
            }
            .navigationTitle(editingListening == nil ? "Add Dictation Exercise" : "Edit Dictation Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingListeningSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingListening == nil ? "Add Exercise" : "Save Changes") {
                        Task {
                            await viewModel.saveListeningExercise(
                                id: editingListening?.id,
                                sentence: listeningSentence,
                                translation: listeningTranslation,
                                topicId: listeningTopicId,
                                level: listeningLevel,
                                audioUrl: listeningAudioUrl.isEmpty ? nil : listeningAudioUrl,
                                hint: listeningHint.isEmpty ? nil : listeningHint
                            )
                            showingListeningSheet = false
                        }
                    }
                    .disabled(listeningSentence.isEmpty || listeningTranslation.isEmpty)
                }
            }
        }
    }
    
    // MARK: - LISTENING IMPORT WIZARD SHEET
    private var listeningImportWizardSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Bộ dữ liệu / Topic
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. CHỌN HOẶC TẠO BỘ DỮ LIỆU (CHỦ ĐỀ)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AdminTheme.primary)
                            .tracking(0.5)
                        
                        Picker("Bộ dữ liệu", selection: $listeningImportTopicMode) {
                            Text("Chọn bộ có sẵn").tag("existing")
                            Text("Tạo bộ mới (+)").tag("new")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 320)
                        
                        if listeningImportTopicMode == "existing" {
                            HStack(spacing: 12) {
                                Text("Bộ dữ liệu đích:")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AdminTheme.textSecondary)
                                
                                Picker("Chủ đề", selection: $listeningImportSelectedTopicId) {
                                    ForEach(viewModel.topics) { t in
                                        Text(t.name).tag(t.id)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Nhập tên bộ dữ liệu mới (ví dụ: Công nghệ, Giao tiếp công sở...)", text: $listeningImportNewTopicName)
                                    .font(.system(size: 13))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .padding(10)
                                    .background(AdminTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                                
                                TextField("Mô tả bộ dữ liệu (tùy chọn)", text: $listeningImportNewTopicDesc)
                                    .font(.system(size: 12))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .padding(8)
                                    .background(AdminTheme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(14)
                    .background(AdminTheme.surfaceHover)
                    .cornerRadius(8)
                    
                    // Section 2: Dữ liệu câu nghe chép
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("2. DỮ LIỆU CÂU NGHE & CHÉP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Picker("Format", selection: $isListeningImportJSON) {
                                Text("CSV").tag(false)
                                Text("JSON").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        Text(isListeningImportJSON
                             ? "JSON Format: [{\"sentence\": \"...\", \"translation\": \"...\", \"level\": \"Beginner\", \"hint\": \"...\"}]"
                             : "CSV Format: sentence,translation,level,hint (hoặc có thêm topicId)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AdminTheme.textSecondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AdminTheme.surfaceHover)
                            .cornerRadius(6)
                        
                        TextEditor(text: $listeningImportText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(AdminTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(AdminTheme.surface)
                            .frame(minHeight: 180)
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Button("Clear") { listeningImportText = "" }
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        Spacer()
                        
                        Button("Import vào Bộ Dữ Liệu") {
                            Task {
                                await importListeningData(
                                    text: listeningImportText,
                                    isJSON: isListeningImportJSON,
                                    topicMode: listeningImportTopicMode,
                                    selectedTopicId: listeningImportSelectedTopicId,
                                    newTopicName: listeningImportNewTopicName,
                                    newTopicDesc: listeningImportNewTopicDesc
                                )
                                showingListeningImportSheet = false
                            }
                        }
                        .disabled(listeningImportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (listeningImportTopicMode == "new" && listeningImportNewTopicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(AdminTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Import Listening vào Bộ Dữ Liệu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showingListeningImportSheet = false }
                }
            }
        }
        .frame(minWidth: 580, minHeight: 520)
    }
    
    // Helper to parse and import Listening Exercises
    private func importListeningData(
        text: String,
        isJSON: Bool,
        topicMode: String,
        selectedTopicId: String,
        newTopicName: String,
        newTopicDesc: String
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let resolvedTopicId = await resolveTopicId(
            topicMode: topicMode,
            selectedTopicId: selectedTopicId,
            newTopicName: newTopicName,
            newTopicDesc: newTopicDesc
        )
        
        if isJSON {
            struct LooseListening: Decodable {
                let sentence: String?
                let translation: String?
                let topicId: String?
                let level: String?
                let hint: String?
            }
            guard let data = trimmed.data(using: .utf8),
                  let items = try? JSONDecoder().decode([LooseListening].self, from: data) else { return }
            
            for item in items {
                guard let s = item.sentence, !s.isEmpty,
                      let tr = item.translation, !tr.isEmpty else { continue }
                let lvl = item.level ?? "Beginner"
                await viewModel.saveListeningExercise(id: nil, sentence: s, translation: tr, topicId: resolvedTopicId, level: lvl, audioUrl: nil, hint: item.hint)
            }
        } else {
            let lines = trimmed.components(separatedBy: .newlines)
            var startIndex = 0
            if lines.indices.contains(0) && lines[0].lowercased().contains("sentence") {
                startIndex = 1
            }
            for i in startIndex..<lines.count {
                let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty { continue }
                let fields = parseCSVRow(line)
                if fields.count >= 2 {
                    let s = fields[0]
                    let tr = fields[1]
                    
                    var lvl = "Beginner"
                    var hint: String? = nil
                    
                    if fields.count >= 5 {
                        if !fields[3].isEmpty { lvl = fields[3] }
                        hint = fields[4].isEmpty ? nil : fields[4]
                    } else if fields.count == 4 {
                        let f2 = fields[2]
                        if ["beginner", "intermediate", "advanced"].contains(f2.lowercased()) {
                            lvl = f2.capitalized
                            hint = fields[3].isEmpty ? nil : fields[3]
                        } else {
                            lvl = fields[3].isEmpty ? "Beginner" : fields[3]
                        }
                    } else if fields.count == 3 {
                        let f2 = fields[2]
                        if ["beginner", "intermediate", "advanced"].contains(f2.lowercased()) {
                            lvl = f2.capitalized
                        }
                    }
                    
                    await viewModel.saveListeningExercise(id: nil, sentence: s, translation: tr, topicId: resolvedTopicId, level: lvl, audioUrl: nil, hint: hint)
                }
            }
        }
        
        // Reload all data so new topics and exercises reflect immediately
        await viewModel.loadAllData()
        viewModel.selectedListeningTopicFilter = "All"
    }
    
    // MARK: - ALERTS FOR DELETE CONFIRMATION
    private var deleteQuizAlert: Alert {
        Alert(
            title: Text("Delete Quiz?"),
            message: Text("Are you sure you want to delete this question? This cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                if let quiz = quizToDelete {
                    Task {
                        await viewModel.deleteQuiz(quizId: quiz.id, topicId: quiz.topicId)
                    }
                }
            },
            secondaryButton: .cancel()
        )
    }
    
    private var deleteListeningAlert: Alert {
        Alert(
            title: Text("Delete Dictation Exercise?"),
            message: Text("Are you sure you want to delete this listening exercise? This cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                if let ex = listeningToDelete {
                    Task {
                        await viewModel.deleteListeningExercise(exerciseId: ex.id, topicId: ex.topicId)
                    }
                }
            },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Audio Preview Button using AVPlayer
struct AudioPreviewButton: View {
    let audioUrlString: String
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            let urlStr = audioUrlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: urlStr) else { return }
            
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player = AVPlayer(url: url)
                player?.play()
                isPlaying = true
                
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem,
                    queue: .main
                ) { _ in
                    isPlaying = false
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 10))
                Text(isPlaying ? "Stop" : "▶ Preview")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(audioUrlString.isEmpty ? AdminTheme.textMuted : AdminTheme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(audioUrlString.isEmpty ? Color.clear : AdminTheme.primaryLight)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(audioUrlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

// MARK: - Checkbox Toggle Style Helper
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundColor(configuration.isOn ? AdminTheme.primary : AdminTheme.textMuted)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AdminHomeView()
        .environmentObject(SessionManager.shared)
}
