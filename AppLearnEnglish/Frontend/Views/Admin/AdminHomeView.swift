//
//  AdminHomeView.swift
//  AppLearnEnglish
//

import SwiftUI
import AVFoundation

// Dedicated Premium Light SaaS Theme (Stripe, Vercel, Shopify inspired)
struct AdminTheme {
    static let primary = Color(hex: "2563EB")       // SaaS Royal Blue
    static let primaryLight = Color(hex: "EFF6FF")  // Muted light blue
    static let bg = Color.white                    // Pure White Content Area
    static let sidebarBg = Color(hex: "F8FAFC")    // Light Gray Sidebar (Xcode / Finder style)
    static let cardBg = Color.white                // Clean Card White
    static let textDark = Color(hex: "0F172A")      // Rich Slate Dark (Text Primary)
    static let textMuted = Color(hex: "475569")     // Slate Gray (Text Secondary - Highly visible)
    static let border = Color(hex: "E2E8F0")        // 1pt clean divider border
    
    // Status / Indicator Colors
    static let success = Color(hex: "059669")      // Emerald Green
    static let danger = Color(hex: "DC2626")       // Rose Red
    static let warning = Color(hex: "D97706")      // Amber Yellow
    static let info = Color(hex: "2563EB")         // Royal Blue
}

struct AdminHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = AdminViewModel()
    
    // Selected Sidebar Tab (0: Dashboard, 1: Topics & Vocabulary, 2: Quizzes, 3: Students)
    @State private var selectedTab: Int? = 1
    
    // Selected Topic for Vocabulary detail view
    @State private var selectedTopicForWords: Topic? = nil
    
    // Alert States for Delete Confirmation
    @State private var topicToDelete: Topic? = nil
    @State private var showingDeleteTopicAlert = false
    
    @State private var wordToDelete: VocabularyWord? = nil
    @State private var showingDeleteWordAlert = false
    
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
    
    // Import Wizard Sheet States
    @State private var showingImportSheet = false
    @State private var importStep = 1 // 1: Upload, 2: Preview, 3: Success
    @State private var importText = ""
    @State private var isImportJSON = false
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR (Premium Light Gray Theme)
            VStack(alignment: .leading, spacing: 0) {
                // Header Panel
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AdminTheme.primary)
                                .frame(width: 32, height: 32)
                            Image(systemName: "shield.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("SYSTEM PORTAL")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(AdminTheme.primary)
                            .tracking(1.5)
                    }
                    .padding(.bottom, 6)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(sessionManager.currentUserModel?.name ?? "Administrator")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AdminTheme.textDark)
                        
                        Text(sessionManager.currentUserModel?.email ?? "")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AdminTheme.textMuted)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                Divider()
                    .background(AdminTheme.border)
                
                // Sidebar Options List
                List(selection: $selectedTab) {
                    Group {
                        NavigationLink(value: 0) {
                            sidebarRow(title: "Dashboard", icon: "gauge.with.needle", isSelected: selectedTab == 0)
                        }
                        .tag(0)
                        
                        NavigationLink(value: 1) {
                            sidebarRow(title: "Topics & Vocabulary", icon: "book.closed.fill", isSelected: selectedTab == 1)
                        }
                        .tag(1)
                        
                        NavigationLink(value: 2) {
                            sidebarRow(title: "Quizzes", icon: "list.clipboard.fill", isSelected: selectedTab == 2)
                        }
                        .tag(2)
                        
                        NavigationLink(value: 3) {
                            sidebarRow(title: "Students", systemImage: "person.2.fill", isSelected: selectedTab == 3)
                        }
                        .tag(3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .background(AdminTheme.sidebarBg)
                .scrollContentBackground(.hidden)
                
                Spacer()
                
                Divider()
                    .background(AdminTheme.border)
                
                // Sign out button
                Button(action: {
                    sessionManager.signOut()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Đăng xuất Hệ thống")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(AdminTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.02))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AdminTheme.sidebarBg)
            .navigationTitle("")
        } detail: {
            // DETAIL PANE (High-contrast pure white content background)
            ZStack {
                AdminTheme.bg
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.topics.isEmpty {
                    tableSkeletonView
                } else if let err = viewModel.errorMessage, viewModel.topics.isEmpty {
                    errorView(errorMsg: err)
                } else {
                    switch selectedTab ?? 1 {
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
                        adminUsersView
                    default:
                        topicsMainView
                    }
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar) // Completely hide system navigation bar to prevent light title bar duplicates
        }
        .task {
            await viewModel.loadAllData()
        }
        .sheet(isPresented: $showingTopicSheet) {
            topicFormSheet
        }
        .sheet(isPresented: $showingWordSheet) {
            wordFormSheet
        }
        .sheet(isPresented: $showingImportSheet) {
            importWizardSheet
        }
        .alert(isPresented: $showingDeleteTopicAlert) {
            deleteTopicAlert
        }
        .alert(isPresented: $showingDeleteWordAlert) {
            deleteWordAlert
        }
    }
    
    // MARK: - Sidebar Row Builder
    private func sidebarRow(title: String, icon: String? = nil, systemImage: String? = nil, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            if let sysImg = systemImage ?? icon {
                Image(systemName: sysImg)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? AdminTheme.primary : AdminTheme.textMuted)
            }
            
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? AdminTheme.textDark : AdminTheme.textMuted)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color(hex: "E2E8F0") : Color.clear)
        .cornerRadius(8)
    }
    
    // MARK: - Table Skeleton View
    private var tableSkeletonView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Đang tải dữ liệu...")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AdminTheme.textMuted)
            
            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E2E8F0"))
                            .frame(width: 40, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E2E8F0"))
                            .frame(width: 120, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E2E8F0"))
                            .frame(maxWidth: .infinity)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E2E8F0"))
                            .frame(width: 60, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E2E8F0"))
                            .frame(width: 100, height: 20)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(24)
    }
    
    // MARK: - Error View
    private func errorView(errorMsg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 48))
                .foregroundColor(AdminTheme.danger)
            
            Text("Không thể tải dữ liệu")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AdminTheme.textDark)
            
            Text("Đã xảy ra lỗi khi kết nối với Firestore.\n\(errorMsg)")
                .font(.system(size: 13))
                .foregroundColor(AdminTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                Task {
                    await viewModel.loadAllData()
                }
            }) {
                Text("Thử lại")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AdminTheme.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(32)
    }
    
    // MARK: - Subview: Dashboard
    private var adminDashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header Title Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bảng điều khiển Tổng quan")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Trung tâm điều hành và giám sát toàn bộ dữ liệu học tập hệ thống.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AdminTheme.textMuted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Header Alert Warnings
                if let err = viewModel.errorMessage {
                    HStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AdminTheme.warning)
                            .font(.system(size: 20))
                        Text(err)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AdminTheme.textDark)
                        Spacer()
                    }
                    .padding(16)
                    .background(AdminTheme.warning.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AdminTheme.warning.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
                
                // SECTION 1: Stat cards Grid (Bigger cards, interactive with actions!)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Số liệu thống kê")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        AdminDashboardCard(
                            title: "Chủ đề học tập",
                            count: "\(viewModel.topics.count)",
                            icon: "folder.fill",
                            color: AdminTheme.primary,
                            subtitle: "Quản lý danh mục giáo trình",
                            action: { selectedTab = 1; selectedTopicForWords = nil }
                        )
                        
                        AdminDashboardCard(
                            title: "Từ vựng hệ thống",
                            count: "\(viewModel.words.count)",
                            icon: "character.book.closed.fill",
                            color: AdminTheme.info,
                            subtitle: "Kho từ vựng & phiên âm",
                            action: { selectedTab = 1 }
                        )
                        
                        AdminDashboardCard(
                            title: "Câu hỏi trắc nghiệm",
                            count: "\(viewModel.quizzes.count)",
                            icon: "list.clipboard.fill",
                            color: AdminTheme.success,
                            subtitle: "Bộ đề kiểm tra & ôn tập",
                            action: { selectedTab = 2 }
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        AdminDashboardCard(
                            title: "Tài khoản học viên",
                            count: "\(viewModel.users.count)",
                            icon: "person.2.fill",
                            color: AdminTheme.danger,
                            subtitle: "Danh sách học viên đăng ký",
                            action: { selectedTab = 3 }
                        )
                        
                        AdminDashboardCard(
                            title: "Tích luỹ trung bình",
                            count: "\(averageXP) XP",
                            icon: "bolt.fill",
                            color: .orange,
                            subtitle: "Điểm kinh nghiệm / Học viên"
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                // SECTION 2: Quick Actions Toolbar (Thao tác nhanh)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thao tác nhanh")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        quickActionButton(
                            title: "Tạo Chủ đề",
                            subtitle: "Thêm Topic mới",
                            icon: "folder.badge.plus",
                            color: AdminTheme.primary
                        ) {
                            editingTopic = nil
                            topicName = ""
                            topicDesc = ""
                            topicImage = "folder.fill"
                            showingTopicSheet = true
                        }
                        
                        quickActionButton(
                            title: "Thêm Từ vựng",
                            subtitle: "Soạn từ vào chủ đề",
                            icon: "plus.square.fill",
                            color: AdminTheme.info
                        ) {
                            selectedTab = 1
                        }
                        
                        quickActionButton(
                            title: "Import File",
                            subtitle: "Nạp từ CSV / JSON",
                            icon: "square.and.arrow.down.fill",
                            color: AdminTheme.success
                        ) {
                            if let firstTopic = viewModel.topics.first {
                                selectedTopicForWords = firstTopic
                            }
                            importText = ""
                            importStep = 1
                            showingImportSheet = true
                        }
                        
                        quickActionButton(
                            title: "Đồng bộ",
                            subtitle: "Làm mới dữ liệu",
                            icon: "arrow.clockwise.circle.fill",
                            color: .orange
                        ) {
                            Task {
                                await viewModel.loadAllData()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // SECTION 3: System Overview & Guide Panels
                HStack(alignment: .top, spacing: 20) {
                    // System Connection Status Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trạng thái Kết nối")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AdminTheme.textDark)
                        
                        VStack(spacing: 12) {
                            statusRow(title: "Cloud Firestore", status: "Hoạt động", color: AdminTheme.success)
                            statusRow(title: "Firebase Authentication", status: "Sẵn sàng", color: AdminTheme.success)
                            statusRow(title: "Đồng bộ Dữ liệu", status: "Thời gian thực", color: AdminTheme.info)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AdminTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AdminTheme.border, lineWidth: 1.5)
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.015), radius: 6, x: 0, y: 3)
                    
                    // Guide Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cẩm nang Quản trị viên")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AdminTheme.textDark)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Nhấn trực tiếp vào các thẻ số liệu để chuyển nhanh sang màn hình tương ứng.", systemImage: "hand.tap.fill")
                            Label("Khi sửa từ vựng đổi chủ đề, Firestore sẽ tự cập nhật lại số lượng từ cho cả 2 chủ đề.", systemImage: "arrow.triangle.2.circlepath")
                            Label("Tính năng Import cho phép dán và duyệt trước (preview) dữ liệu CSV/JSON an toàn.", systemImage: "checkmark.seal.fill")
                        }
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AdminTheme.textMuted)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AdminTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AdminTheme.border, lineWidth: 1.5)
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.015), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 16)
        }
    }
    
    private func quickActionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(AdminTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AdminTheme.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AdminTheme.border, lineWidth: 1.2)
            )
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.015), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusRow(title: String, status: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AdminTheme.textDark)
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(status)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.08))
            .cornerRadius(6)
        }
    }
    
    private var averageXP: Int {
        guard !viewModel.users.isEmpty else { return 0 }
        let total = viewModel.users.reduce(0) { $0 + $1.xp }
        return total / viewModel.users.count
    }
    
    // MARK: - Subview: Topics Main View
    private var topicsMainView: some View {
        VStack(spacing: 0) {
            // Header Section (Rich High-Contrast Slate Texts)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Topics")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Quản lý các chủ đề học tiếng Anh và nội dung từ vựng")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                }
                
                Spacer()
                
                Button(action: {
                    editingTopic = nil
                    topicName = ""
                    topicDesc = ""
                    topicImage = "folder.fill"
                    showingTopicSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Thêm chủ đề")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AdminTheme.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            
            // Toolbar Search & Sort
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AdminTheme.textMuted)
                    TextField("Search topics...", text: $viewModel.topicSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(AdminTheme.textDark)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AdminTheme.border, lineWidth: 1)
                )
                .cornerRadius(8)
                .frame(width: 320)
                
                Spacer()
                
                Picker("Sắp xếp", selection: $viewModel.selectedTopicSort) {
                    Text("Tên A → Z").tag("A-Z")
                    Text("Tên Z → A").tag("Z-A")
                    Text("Nhiều từ nhất").tag("Most Words")
                    Text("Ít từ nhất").tag("Least Words")
                }
                .frame(width: 200)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider()
                .background(AdminTheme.border)
            
            // Content List Table
            if viewModel.filteredTopics.isEmpty {
                // Topic Empty State
                VStack(spacing: 16) {
                    Text("📚")
                        .font(.system(size: 48))
                    Text("Chưa có chủ đề")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Tạo chủ đề đầu tiên để bắt đầu quản lý nội dung học tập.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    Button(action: {
                        editingTopic = nil
                        topicName = ""
                        topicDesc = ""
                        topicImage = "folder.fill"
                        showingTopicSheet = true
                    }) {
                        Text("+ Thêm chủ đề")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AdminTheme.primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxHeight: .infinity)
            } else {
                // macOS Table Layout
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        Text("Icon").frame(width: 80, alignment: .leading)
                        Text("Topic").frame(width: 160, alignment: .leading)
                        Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Words").frame(width: 100, alignment: .trailing)
                        Text("Actions").frame(width: 240, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AdminTheme.textMuted)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "F8FAFC"))
                    
                    Divider()
                        .background(AdminTheme.border)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.filteredTopics) { topic in
                                HStack(spacing: 0) {
                                    // Symbol Preview
                                    Image(systemName: topic.image.isEmpty ? "folder.fill" : topic.image)
                                        .font(.system(size: 16))
                                        .foregroundColor(AdminTheme.primary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    // Name
                                    Text(topic.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AdminTheme.textDark)
                                        .frame(width: 160, alignment: .leading)
                                    
                                    // Description
                                    Text(topic.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(AdminTheme.textMuted)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Words
                                    Text("\(topic.totalWords)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AdminTheme.textDark)
                                        .frame(width: 100, alignment: .trailing)
                                    
                                    // Actions
                                    HStack(spacing: 12) {
                                        Button("Xem từ vựng") {
                                            selectedTopicForWords = topic
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundColor(AdminTheme.primary)
                                        
                                        Button("Sửa") {
                                            editingTopic = topic
                                            topicName = topic.name
                                            topicDesc = topic.description
                                            topicImage = topic.image
                                            showingTopicSheet = true
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundColor(AdminTheme.textMuted)
                                        
                                        Button("Xóa") {
                                            topicToDelete = topic
                                            showingDeleteTopicAlert = true
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundColor(AdminTheme.danger)
                                    }
                                    .frame(width: 240, alignment: .trailing)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                
                                Divider()
                                    .background(AdminTheme.border)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subview: Vocabulary Detail View
    private func vocabularyDetailView(topic: Topic) -> some View {
        VStack(spacing: 0) {
            // Breadcrumbs Navigation Bar
            HStack(spacing: 6) {
                Button("Topics") {
                    selectedTopicForWords = nil
                }
                .foregroundColor(AdminTheme.primary)
                .bold()
                .buttonStyle(PlainButtonStyle())
                
                Text("/")
                    .foregroundColor(AdminTheme.textMuted)
                
                Text(topic.name)
                    .foregroundColor(AdminTheme.textMuted)
                
                Text("/")
                    .foregroundColor(AdminTheme.textMuted)
                
                Text("Vocabulary")
                    .foregroundColor(AdminTheme.textDark)
                    .bold()
                
                Spacer()
            }
            .font(.system(size: 12))
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Từ vựng thuộc chủ đề \(topic.name)")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        importText = ""
                        importStep = 1
                        showingImportSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AdminTheme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AdminTheme.primary, lineWidth: 1)
                        )
                        .cornerRadius(8)
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
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Thêm từ vựng")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AdminTheme.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Subtitle words count
            HStack {
                Text("\(topic.totalWords) từ vựng")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AdminTheme.textDark)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Toolbar Search & Filter & Sort
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AdminTheme.textMuted)
                    TextField("Search vocabulary...", text: $viewModel.wordSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(AdminTheme.textDark)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AdminTheme.border, lineWidth: 1)
                )
                .cornerRadius(8)
                .frame(width: 240)
                
                Picker("Level", selection: $viewModel.selectedLevelFilter) {
                    Text("Level: All").tag("All")
                    Text("Beginner").tag("Beginner")
                    Text("Intermediate").tag("Intermediate")
                    Text("Advanced").tag("Advanced")
                }
                .frame(width: 160)
                
                Picker("Sắp xếp", selection: $viewModel.selectedWordSort) {
                    Text("Sắp xếp: A → Z").tag("A-Z")
                    Text("Sắp xếp: Z → A").tag("Z-A")
                    Text("Mới nhất").tag("Newest")
                    Text("Cũ nhất").tag("Oldest")
                }
                .frame(width: 180)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider()
                .background(AdminTheme.border)
            
            // Vocabulary Table View
            let topicWords = viewModel.filteredWords(for: topic.id)
            
            if topicWords.isEmpty {
                // Topic Vocabulary Empty State
                VStack(spacing: 16) {
                    Text("📖")
                        .font(.system(size: 48))
                    Text("Chưa có từ vựng")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Topic này chưa có từ vựng.")
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textMuted)
                    
                    HStack(spacing: 12) {
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
                            Text("+ Thêm từ vựng")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AdminTheme.primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            importText = ""
                            importStep = 1
                            showingImportSheet = true
                        }) {
                            Text("Import")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AdminTheme.primary, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        Text("Word").frame(width: 140, alignment: .leading)
                        Text("Phonetic").frame(width: 120, alignment: .leading)
                        Text("Meaning").frame(width: 180, alignment: .leading)
                        Text("Level").frame(width: 110, alignment: .leading)
                        Text("Example").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Actions").frame(width: 100, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AdminTheme.textMuted)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "F8FAFC"))
                    
                    Divider()
                        .background(AdminTheme.border)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(topicWords) { word in
                                HStack(spacing: 0) {
                                    // Word
                                    Text(word.word)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AdminTheme.textDark)
                                        .frame(width: 140, alignment: .leading)
                                    
                                    // Phonetic
                                    Text(word.phonetic)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AdminTheme.textMuted)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    // Meaning
                                    Text(word.meaning)
                                        .font(.system(size: 13))
                                        .foregroundColor(AdminTheme.textDark)
                                        .frame(width: 180, alignment: .leading)
                                    
                                    // Level Badge
                                    Text(word.level)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(levelColor(word.level))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(levelColor(word.level).opacity(0.08))
                                        .cornerRadius(4)
                                        .frame(width: 110, alignment: .leading)
                                    
                                    // Example
                                    Text(word.example)
                                        .font(.system(size: 12))
                                        .foregroundColor(AdminTheme.textMuted)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Actions
                                    HStack(spacing: 12) {
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
                                                .foregroundColor(AdminTheme.primary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            wordToDelete = word
                                            showingDeleteWordAlert = true
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(AdminTheme.danger)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .frame(width: 100, alignment: .trailing)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                
                                Divider()
                                    .background(AdminTheme.border)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func levelColor(_ lvl: String) -> Color {
        switch lvl.lowercased() {
        case "beginner": return AdminTheme.success
        case "intermediate": return AdminTheme.info
        case "advanced": return AdminTheme.danger
        default: return AdminTheme.textMuted
        }
    }
    
    // MARK: - Subview: Quizzes List
    private var adminQuizzesView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quizzes")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Kho câu hỏi trắc nghiệm hệ thống (\(viewModel.quizzes.count) câu hỏi)")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textMuted)
                }
                Spacer()
            }
            .padding(24)
            Divider()
                .background(AdminTheme.border)
            
            // Simple Quizzes Placeholder
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.quizzes) { quiz in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(quiz.question)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AdminTheme.textDark)
                            ForEach(quiz.answers, id: \.self) { ans in
                                HStack {
                                    Image(systemName: ans == quiz.correctAnswer ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(ans == quiz.correctAnswer ? AdminTheme.success : AdminTheme.textMuted)
                                    Text(ans)
                                        .font(.system(size: 13))
                                        .foregroundColor(ans == quiz.correctAnswer ? AdminTheme.success : AdminTheme.textDark)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Subview: Users List
    private var adminUsersView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Students")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AdminTheme.textDark)
                    Text("Danh sách học viên đăng ký trên hệ thống (\(viewModel.users.count) tài khoản)")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textMuted)
                }
                Spacer()
            }
            .padding(24)
            Divider()
                .background(AdminTheme.border)
            
            // Simple Users Placeholder
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.users) { user in
                        HStack {
                            Text(user.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AdminTheme.textDark)
                            Spacer()
                            Text("\(user.xp) XP")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AdminTheme.success)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Delete Alert builders
    private var deleteTopicAlert: Alert {
        guard let topic = topicToDelete else {
            return Alert(title: Text("Lỗi"))
        }
        
        if topic.totalWords > 0 {
            return Alert(
                title: Text("Xóa chủ đề?"),
                message: Text("“\(topic.name)” hiện đang có \(topic.totalWords) từ vựng. Bạn cần xử lý các từ vựng thuộc chủ đề này trước khi xóa chủ đề."),
                primaryButton: .default(Text("Xem từ vựng")) {
                    selectedTopicForWords = topic
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        } else {
            return Alert(
                title: Text("Xóa chủ đề?"),
                message: Text("Bạn có chắc muốn xóa “\(topic.name)” không? Hành động này không thể hoàn tác."),
                primaryButton: .destructive(Text("Xóa")) {
                    Task {
                        await viewModel.deleteTopic(topicId: topic.id)
                    }
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
    
    private var deleteWordAlert: Alert {
        guard let word = wordToDelete else {
            return Alert(title: Text("Lỗi"))
        }
        return Alert(
            title: Text("Xóa từ vựng?"),
            message: Text("Bạn có chắc muốn xóa “\(word.word)” không? Hành động này không thể hoàn tác."),
            primaryButton: .destructive(Text("Xóa")) {
                Task {
                    await viewModel.deleteWord(wordId: word.id, topicId: word.topicId)
                }
            },
            secondaryButton: .cancel(Text("Hủy"))
        )
    }
    
    // MARK: - Topic Form Sheet Builder
    private var topicFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin Chủ đề")) {
                    TextField("Tên chủ đề", text: $topicName)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mô tả")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                        TextEditor(text: $topicDesc)
                            .frame(height: 100)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AdminTheme.border, lineWidth: 1))
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        TextField("SF Symbol", text: $topicImage)
                        
                        // Icon Preview
                        Image(systemName: topicImage.isEmpty ? "folder.fill" : topicImage)
                            .font(.system(size: 18))
                            .foregroundColor(AdminTheme.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "F1F5F9"))
                            .cornerRadius(6)
                    }
                }
                
                Section(header: Text("Dữ liệu tự động")) {
                    HStack {
                        Text("Total Words:")
                        Spacer()
                        Text("\(editingTopic?.totalWords ?? 0) words")
                            .foregroundColor(AdminTheme.textMuted)
                    }
                    .font(.system(size: 13))
                    
                    Text("Total Words được tự động tính từ số Vocabulary thuộc Topic này.")
                        .font(.system(size: 11))
                        .foregroundColor(AdminTheme.textMuted)
                }
            }
            .navigationTitle(editingTopic == nil ? "Thêm chủ đề" : "Chỉnh sửa chủ đề")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { showingTopicSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTopic == nil ? "Tạo chủ đề" : "Lưu thay đổi") {
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
    
    // MARK: - Word Form Sheet Builder
    private var wordFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Từ vựng")) {
                    TextField("Từ tiếng Anh", text: $wordText)
                    TextField("Phiên âm", text: $wordPhonetic)
                    TextField("Định nghĩa tiếng Việt", text: $wordMeaning)
                    TextField("Ví dụ", text: $wordExample)
                    
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
                
                Section(header: Text("Phương tiện")) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Đường dẫn Ảnh (Image URL)", text: $wordImage)
                        if !wordImage.isEmpty, let url = URL(string: wordImage) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(6)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Đường dẫn Âm thanh (Audio URL)", text: $wordAudio)
                        
                        AudioPreviewButton(audioUrlString: wordAudio)
                    }
                }
            }
            .navigationTitle(editingWord == nil ? "Thêm từ vựng" : "Chỉnh sửa từ vựng")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { showingWordSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingWord == nil ? "Thêm từ vựng" : "Lưu thay đổi") {
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
    
    // MARK: - Import Wizard Sheet Builder
    private var importWizardSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wizard Breadcrumbs Header
                HStack(spacing: 12) {
                    stepIndicator(step: 1, label: "Upload", isActive: importStep >= 1)
                    lineIndicator(isActive: importStep >= 2)
                    stepIndicator(step: 2, label: "Preview", isActive: importStep >= 2)
                    lineIndicator(isActive: importStep >= 3)
                    stepIndicator(step: 3, label: "Success", isActive: importStep >= 3)
                }
                .padding()
                .background(Color(hex: "F1F5F9"))
                
                Divider()
                    .background(AdminTheme.border)
                
                // Switch Content Step
                if importStep == 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Dữ liệu nhập:")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AdminTheme.textDark)
                            
                            Spacer()
                            
                            Toggle(isOn: $isImportJSON) {
                                Text("Sử dụng định dạng JSON")
                                    .font(.system(size: 12))
                                    .foregroundColor(AdminTheme.textDark)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dán mã CSV hoặc JSON vào khung bên dưới:")
                                .font(.system(size: 12))
                                .foregroundColor(AdminTheme.textMuted)
                            
                            TextEditor(text: $importText)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(AdminTheme.textDark)
                                .frame(height: 240)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Button(action: {
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
                            }) {
                                Text("Xem mẫu template")
                                    .font(.system(size: 12))
                                    .foregroundColor(AdminTheme.primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Divider()
                            .background(AdminTheme.border)
                        
                        HStack {
                            Button("Hủy") { showingImportSheet = false }
                                .keyboardShortcut(.escape, modifiers: [])
                            
                            Spacer()
                            
                            Button("Next / Preview") {
                                if let topic = selectedTopicForWords {
                                    viewModel.parseImportData(text: importText, isJSON: isImportJSON, currentTopicId: topic.id)
                                    importStep = 2
                                }
                            }
                            .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                    }
                } else if importStep == 2 {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            statBadge(count: viewModel.importStats.validCount, label: "Valid", color: AdminTheme.success, icon: "checkmark.circle.fill")
                            statBadge(count: viewModel.importStats.duplicateCount, label: "Duplicate", color: AdminTheme.warning, icon: "exclamationmark.triangle.fill")
                            statBadge(count: viewModel.importStats.invalidCount, label: "Invalid", color: AdminTheme.danger, icon: "xmark.circle.fill")
                        }
                        .padding(.top)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Status").frame(width: 80, alignment: .leading)
                                Text("Word").frame(width: 120, alignment: .leading)
                                Text("Meaning").frame(width: 140, alignment: .leading)
                                Text("Level").frame(width: 80, alignment: .leading)
                                Text("Reason").frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(hex: "F1F5F9"))
                            
                            Divider()
                                .background(AdminTheme.border)
                            
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.parsedImportRecords) { record in
                                        HStack {
                                            HStack(spacing: 4) {
                                                Image(systemName: record.status == .valid ? "checkmark" : (record.status == .duplicate ? "exclamationmark" : "xmark"))
                                                    .font(.system(size: 9, weight: .bold))
                                                Text(record.status.rawValue)
                                            }
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(record.status == .valid ? AdminTheme.success : (record.status == .duplicate ? AdminTheme.warning : AdminTheme.danger))
                                            .frame(width: 80, alignment: .leading)
                                            
                                            Text(record.word)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AdminTheme.textDark)
                                                .frame(width: 120, alignment: .leading)
                                            
                                            Text(record.meaning)
                                                .font(.system(size: 12))
                                                .foregroundColor(AdminTheme.textDark)
                                                .frame(width: 140, alignment: .leading)
                                            
                                            Text(record.level)
                                                .font(.system(size: 10))
                                                .foregroundColor(levelColor(record.level))
                                                .frame(width: 80, alignment: .leading)
                                            
                                            Text(record.statusReason)
                                                .font(.system(size: 11))
                                                .foregroundColor(AdminTheme.textMuted)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        Divider()
                                            .background(AdminTheme.border)
                                    }
                                }
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Divider()
                            .background(AdminTheme.border)
                        
                        HStack {
                            Button("Quay lại") { importStep = 1 }
                            
                            Spacer()
                            
                            Button("Import \(viewModel.importStats.validCount) Words") {
                                Task {
                                    await viewModel.commitImportedRecords()
                                    importStep = 3
                                }
                            }
                            .disabled(viewModel.importStats.validCount == 0)
                        }
                        .padding()
                    }
                } else if importStep == 3 {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AdminTheme.success)
                        
                        Text("✓ Import completed")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AdminTheme.textDark)
                        
                        Text("Từ vựng đã được thêm vào Firestore và đồng bộ thành công.")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Spacer()
                        
                        Divider()
                            .background(AdminTheme.border)
                        
                        Button("Xong") {
                            showingImportSheet = false
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Import Vocabulary Wizard")
        }
    }
    
    private func stepIndicator(step: Int, label: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? AdminTheme.primary : Color(hex: "94A3B8"))
                    .frame(width: 22, height: 22)
                Text("\(step)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 12, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? AdminTheme.textDark : AdminTheme.textMuted)
        }
    }
    
    private func lineIndicator(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? AdminTheme.primary : Color(hex: "CBD5E1"))
            .frame(width: 40, height: 2)
    }
    
    private func statBadge(count: Int, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AdminTheme.textDark)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AdminTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Dashboard Card
struct AdminDashboardCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                        .padding(8)
                        .background(Color(hex: "F1F5F9"))
                        .clipShape(Circle())
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(count)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AdminTheme.textDark)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AdminTheme.textDark)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AdminTheme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(AdminTheme.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AdminTheme.border, lineWidth: 1.5)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
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
            HStack {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                Text(isPlaying ? "Stop" : "▶ Preview")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(audioUrlString.isEmpty ? AdminTheme.textMuted : AdminTheme.primary)
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
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
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
