//
//  AdminHomeView.swift
//  AppLearnEnglish
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = AdminViewModel()
    
    // Selected Sidebar Tab (0: Dashboard, 1: Vocabulary, 2: Quizzes, 3: Users)
    @State private var selectedTab: Int? = 0
    
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
    @State private var wordTopicId = ""
    @State private var wordLevel = "Beginner"
    
    // Add/Edit Quiz Sheet States
    @State private var showingQuizSheet = false
    @State private var editingQuiz: Quiz? = nil
    @State private var quizQuestion = ""
    @State private var quizAns1 = ""
    @State private var quizAns2 = ""
    @State private var quizAns3 = ""
    @State private var quizAns4 = ""
    @State private var quizCorrectAns = ""
    @State private var quizTopicId = ""
    @State private var quizType = "multiple_choice"
    
    // User Edit Popover States
    @State private var editingUser: UserModel? = nil
    @State private var userXPText = ""
    @State private var userLevel = "Beginner"
    
    // Topic detail selection in Vocab list
    @State private var selectedTopicForWords: Topic? = nil
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR
            VStack(alignment: .leading, spacing: 0) {
                // Admin Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🛡️ SYSTEM ADMIN")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryCoral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.primaryCoral.opacity(0.12))
                            .cornerRadius(6)
                        
                        Spacer()
                    }
                    
                    Text(sessionManager.currentUserModel?.name ?? "Administrator")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .lineLimit(1)
                    
                    Text(sessionManager.currentUserModel?.email ?? "")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(1)
                }
                .padding(20)
                .background(Color.white.opacity(0.4))
                
                Divider()
                
                // Sidebar Options List
                List(selection: $selectedTab) {
                    NavigationLink(value: 0) {
                        Label("Thống kê Tổng quan", systemImage: "chart.bar.xaxis")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.vertical, 4)
                    }
                    .tag(0)
                    
                    NavigationLink(value: 1) {
                        Label("Quản lý Từ vựng", systemImage: "character.book.closed.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.vertical, 4)
                    }
                    .tag(1)
                    
                    NavigationLink(value: 2) {
                        Label("Quản lý Đề kiểm tra", systemImage: "list.clipboard.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.vertical, 4)
                    }
                    .tag(2)
                    
                    NavigationLink(value: 3) {
                        Label("Quản lý Học viên", systemImage: "person.3.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.vertical, 4)
                    }
                    .tag(3)
                }
                .listStyle(SidebarListStyle())
                
                Spacer()
                
                Divider()
                
                // Sign out button
                Button(action: {
                    sessionManager.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.system(size: 14, weight: .bold))
                        Text("Đăng xuất Admin")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Trực Ban Admin")
        } detail: {
            // DETAIL PANE
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Đang tải dữ liệu hệ thống...")
                        .tint(AppTheme.primaryMint)
                } else {
                    switch selectedTab ?? 0 {
                    case 0:
                        adminDashboardView
                    case 1:
                        adminVocabularyView
                    case 2:
                        adminQuizzesView
                    case 3:
                        adminUsersView
                    default:
                        adminDashboardView
                    }
                }
            }
            .navigationTitle(detailTitle)
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
        .sheet(isPresented: $showingQuizSheet) {
            quizFormSheet
        }
        .sheet(item: $editingUser) { user in
            userEditSheet(user: user)
        }
    }
    
    // MARK: - Helper values
    private var detailTitle: String {
        switch selectedTab ?? 0 {
        case 0: return "Bảng điều khiển"
        case 1: return "Quản lý Từ vựng & Chủ đề"
        case 2: return "Quản lý Câu hỏi kiểm tra"
        case 3: return "Giám sát Học viên"
        default: return "Admin Portal"
        }
    }
    
    // MARK: - Subview: Dashboard
    private var adminDashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header Alert
                if let err = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(err)
                            .font(.system(size: 13, design: .rounded))
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Stat cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    AdminDashboardCard(title: "Chủ đề học", count: "\(viewModel.topics.count)", icon: "folder.fill", color: AppTheme.primaryMint)
                    AdminDashboardCard(title: "Từ vựng hệ thống", count: "\(viewModel.words.count)", icon: "character.book.closed.fill", color: AppTheme.pastelSky)
                    AdminDashboardCard(title: "Tổng số câu hỏi Quiz", count: "\(viewModel.quizzes.count)", icon: "list.clipboard.fill", color: AppTheme.pastelLavender)
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    AdminDashboardCard(title: "Tài khoản học viên", count: "\(viewModel.users.count)", icon: "person.3.fill", color: AppTheme.primaryCoral)
                    AdminDashboardCard(title: "Trung bình XP/Người", count: "\(averageXP)", icon: "sparkles", color: .yellow)
                }
                .padding(.horizontal)
                
                // Admin Guideline
                VStack(alignment: .leading, spacing: 14) {
                    Text("Hướng dẫn tác vụ Quản trị viên")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Sử dụng sidebar bên trái để duyệt nhanh qua các danh mục quản trị.", systemImage: "sidebar.left")
                        Label("Nhấn nút Thêm mới (+) ở các trang tương ứng để tạo nhanh từ mới, chủ đề mới hoặc câu hỏi trắc nghiệm.", systemImage: "plus.circle")
                        Label("Dữ liệu chỉnh sửa sẽ được lưu trực tiếp và đồng bộ ngay lập tức lên cơ sở dữ liệu Cloud Firestore.", systemImage: "cloud.fill")
                    }
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(20)
                    .designShadow()
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
    }
    
    private var averageXP: Int {
        guard !viewModel.users.isEmpty else { return 0 }
        let total = viewModel.users.reduce(0) { $0 + $1.xp }
        return total / viewModel.users.count
    }
    
    // MARK: - Subview: Vocabulary Management
    private var adminVocabularyView: some View {
        VStack(spacing: 0) {
            // Topics list & Action header
            HStack {
                Text("Danh sách Chủ đề (\(viewModel.topics.count))")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Spacer()
                
                Button(action: {
                    editingTopic = nil
                    topicName = ""
                    topicDesc = ""
                    topicImage = "folder.fill"
                    showingTopicSheet = true
                }) {
                    Label("Thêm Chủ đề", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.primaryMint)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            // Grid of Topics
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.topics) { topic in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppTheme.primaryMint.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: topic.image.isEmpty ? "folder.fill" : topic.image)
                                            .foregroundColor(AppTheme.primaryMint)
                                            .font(.system(size: 20))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(topic.name)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textDark)
                                        Text("\(topic.totalWords) từ vựng")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    // Actions Menu
                                    Menu {
                                        Button(action: {
                                            selectedTopicForWords = topic
                                        }) {
                                            Label("Xem từ vựng", systemImage: "list.bullet")
                                        }
                                        
                                        Button(action: {
                                            editingTopic = topic
                                            topicName = topic.name
                                            topicDesc = topic.description
                                            topicImage = topic.image
                                            showingTopicSheet = true
                                        }) {
                                            Label("Sửa chủ đề", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            Task {
                                                await viewModel.deleteTopic(topicId: topic.id)
                                            }
                                        }) {
                                            Label("Xoá chủ đề", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle.fill")
                                            .foregroundColor(AppTheme.textLight)
                                            .font(.system(size: 18))
                                    }
                                    .menuStyle(BorderlessButtonMenuStyle())
                                    .fixedSize()
                                }
                                
                                Text(topic.description)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(18)
                            .designShadow()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected Topic Words Section
                    if let selectedTopic = selectedTopicForWords {
                        Divider()
                            .padding(.vertical)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Từ vựng: \(selectedTopic.name)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(AppTheme.textDark)
                                Text("Các từ vựng có trong chủ đề hệ thống này")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editingWord = nil
                                wordText = ""
                                wordPhonetic = ""
                                wordMeaning = ""
                                wordExample = ""
                                wordTopicId = selectedTopic.id
                                wordLevel = "Beginner"
                                showingWordSheet = true
                            }) {
                                Label("Thêm Từ mới", systemImage: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.primaryMint)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        let topicWords = viewModel.words.filter { $0.topicId == selectedTopic.id }
                        
                        if topicWords.isEmpty {
                            VStack(spacing: 8) {
                                Text("📭")
                                    .font(.system(size: 32))
                                Text("Chưa có từ nào trong chủ đề này.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.vertical, 32)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(topicWords) { word in
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(word.word)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(AppTheme.textDark)
                                                Text(word.phonetic)
                                                    .font(.system(size: 12, design: .rounded))
                                                    .foregroundColor(AppTheme.textMuted)
                                                
                                                Text(word.level)
                                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(AppTheme.primaryMint)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Text(word.meaning)
                                                .font(.system(size: 13, design: .rounded))
                                                .foregroundColor(AppTheme.textDark)
                                            
                                            Text("Ví dụ: \(word.example)")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(AppTheme.textMuted)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                editingWord = word
                                                wordText = word.word
                                                wordPhonetic = word.phonetic
                                                wordMeaning = word.meaning
                                                wordExample = word.example
                                                wordTopicId = word.topicId
                                                wordLevel = word.level
                                                showingWordSheet = true
                                            }) {
                                                Image(systemName: "pencil")
                                                    .foregroundColor(AppTheme.primaryMint)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                Task {
                                                    await viewModel.deleteWord(wordId: word.id, topicId: word.topicId)
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(14)
                                    .designShadow()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Subview: Quiz Management
    private var adminQuizzesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bài tập kiểm tra (\(viewModel.quizzes.count))")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Spacer()
                
                Button(action: {
                    editingQuiz = nil
                    quizQuestion = ""
                    quizAns1 = ""
                    quizAns2 = ""
                    quizAns3 = ""
                    quizAns4 = ""
                    quizCorrectAns = ""
                    quizTopicId = viewModel.topics.first?.id ?? ""
                    quizType = "multiple_choice"
                    showingQuizSheet = true
                }) {
                    Label("Thêm Câu hỏi", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.pastelSky)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.quizzes) { quiz in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Chủ đề: \(topicName(for: quiz.topicId))")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.pastelSky)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.pastelSky.opacity(0.12))
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        editingQuiz = quiz
                                        quizQuestion = quiz.question
                                        quizAns1 = quiz.answers.indices.contains(0) ? quiz.answers[0] : ""
                                        quizAns2 = quiz.answers.indices.contains(1) ? quiz.answers[1] : ""
                                        quizAns3 = quiz.answers.indices.contains(2) ? quiz.answers[2] : ""
                                        quizAns4 = quiz.answers.indices.contains(3) ? quiz.answers[3] : ""
                                        quizCorrectAns = quiz.correctAnswer
                                        quizTopicId = quiz.topicId
                                        quizType = quiz.type
                                        showingQuizSheet = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(AppTheme.pastelSky)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        Task {
                                            await viewModel.deleteQuiz(quizId: quiz.id)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Text(quiz.question)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textDark)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(quiz.answers, id: \.self) { ans in
                                    HStack {
                                        Image(systemName: ans == quiz.correctAnswer ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(ans == quiz.correctAnswer ? AppTheme.primaryMint : AppTheme.textLight)
                                        Text(ans)
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(ans == quiz.correctAnswer ? AppTheme.primaryMint : AppTheme.textMuted)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(18)
                        .designShadow()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func topicName(for id: String) -> String {
        viewModel.topics.first(where: { $0.id == id })?.name ?? id
    }
    
    // MARK: - Subview: Users List
    private var adminUsersView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Học viên đăng ký (\(viewModel.users.count))")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                Spacer()
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.users) { user in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.pastelLavender.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Text(user.name.prefix(1).uppercased())
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(AppTheme.pastelLavender)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(user.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textDark)
                                    
                                    Text(user.role.uppercased())
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(user.role == "admin" ? AppTheme.primaryCoral : Color.blue)
                                        .cornerRadius(4)
                                }
                                
                                Text(user.email)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(user.xp) XP")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(AppTheme.primaryMint)
                                Text("Mức độ: \(user.level)")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            
                            Button(action: {
                                userXPText = "\(user.xp)"
                                userLevel = user.level
                                editingUser = user
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(AppTheme.pastelLavender)
                                    .font(.system(size: 24))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                        .designShadow()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Sheet Form: Topic Form
    private var topicFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin Chủ đề")) {
                    TextField("Tên chủ đề", text: $topicName)
                    TextField("Mô tả ngắn", text: $topicDesc)
                    TextField("Biểu tượng (SF Symbols name)", text: $topicImage)
                }
            }
            .navigationTitle(editingTopic == nil ? "Tạo Chủ đề" : "Sửa Chủ đề")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showingTopicSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        Task {
                            await viewModel.saveTopic(id: editingTopic?.id, name: topicName, description: topicDesc, image: topicImage)
                            showingTopicSheet = false
                        }
                    }
                    .disabled(topicName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Sheet Form: Word Form
    private var wordFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin Từ vựng")) {
                    TextField("Từ tiếng Anh", text: $wordText)
                    TextField("Phiên âm", text: $wordPhonetic)
                    TextField("Định nghĩa tiếng Việt", text: $wordMeaning)
                    TextField("Ví dụ minh hoạ", text: $wordExample)
                    
                    Picker("Mức độ", selection: $wordLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                }
            }
            .navigationTitle(editingWord == nil ? "Thêm từ mới" : "Chỉnh sửa từ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showingWordSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        Task {
                            await viewModel.saveWord(
                                id: editingWord?.id,
                                word: wordText,
                                phonetic: wordPhonetic,
                                meaning: wordMeaning,
                                example: wordExample,
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
    
    // MARK: - Sheet Form: Quiz Form
    private var quizFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Câu hỏi")) {
                    TextField("Câu hỏi kiểm tra", text: $quizQuestion)
                    
                    Picker("Chủ đề liên kết", selection: $quizTopicId) {
                        ForEach(viewModel.topics) { topic in
                            Text(topic.name).tag(topic.id)
                        }
                    }
                }
                
                Section(header: Text("4 Phương án Trả lời")) {
                    TextField("Đáp án A", text: $quizAns1)
                    TextField("Đáp án B", text: $quizAns2)
                    TextField("Đáp án C", text: $quizAns3)
                    TextField("Đáp án D", text: $quizAns4)
                }
                
                Section(header: Text("Đáp án đúng")) {
                    TextField("Phương án đúng chính xác", text: $quizCorrectAns)
                }
            }
            .navigationTitle(editingQuiz == nil ? "Thêm câu hỏi" : "Sửa câu hỏi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { showingQuizSheet = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        let answers = [quizAns1, quizAns2, quizAns3, quizAns4].filter { !$0.isEmpty }
                        if answers.count == 4 && !quizCorrectAns.isEmpty {
                            Task {
                                await viewModel.saveQuiz(
                                    id: editingQuiz?.id,
                                    question: quizQuestion,
                                    answers: answers,
                                    correctAnswer: quizCorrectAns,
                                    topicId: quizTopicId,
                                    type: quizType
                                )
                                showingQuizSheet = false
                            }
                        }
                    }
                    .disabled(quizQuestion.isEmpty || quizAns1.isEmpty || quizAns2.isEmpty || quizAns3.isEmpty || quizAns4.isEmpty || quizCorrectAns.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Sheet Form: User Edit Sheet
    private func userEditSheet(user: UserModel) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin học viên: \(user.name)")) {
                    TextField("Điểm XP tích luỹ", text: $userXPText)
                        .keyboardType(.numberPad)
                    
                    Picker("Cấp độ học tập", selection: $userLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                }
            }
            .navigationTitle("Thay đổi thông tin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { editingUser = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xác nhận") {
                        if let xpVal = Int(userXPText) {
                            Task {
                                await viewModel.updateUserXPAndLevel(uid: user.uid, xp: xpVal, level: userLevel)
                                editingUser = nil
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Dashboard Card
struct AdminDashboardCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(count)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(22)
        .designShadow()
    }
}

#Preview {
    AdminHomeView()
        .environmentObject(SessionManager.shared)
}
