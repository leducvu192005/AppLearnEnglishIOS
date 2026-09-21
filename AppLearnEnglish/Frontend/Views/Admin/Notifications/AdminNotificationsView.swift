//
//  AdminNotificationsView.swift
//  AppLearnEnglish
//

import SwiftUI
import UserNotifications

struct AdminNotificationsView: View {
    @ObservedObject var viewModel: AdminViewModel
    
    // Sub-tab selection: 0 = Soạn tin, 1 = Lịch sử, 2 = Mẫu sẵn, 3 = Thiết bị FCM
    @State private var selectedSubTab = 0
    
    // Compose Form States
    @State private var notifTitle = "⏰ Giờ học Tiếng Anh đến rồi, {user_name} ơi!"
    @State private var notifBody = "Dành 5 phút hoàn thành mục tiêu ngày để duy trì chuỗi Streak rực rỡ nhé! 🚀"
    @State private var notifTargetType = "all" // "all", "streak_risk", "srs_pending", "specific_user"
    @State private var notifSelectedUserId = ""
    @State private var notifCategory = "vocab" // "vocab", "quiz", "listening", "streak", "srs", "event", "system"
    @State private var notifDeepLink = "home" // "home", "vocabulary", "quizzes", "listening", "profile"
    @State private var notifImageUrl = ""
    
    // UI Feedback States
    @State private var isSending = false
    @State private var toastMessage: String? = nil
    @State private var showingDeleteAlert = false
    @State private var notifToDelete: AdminNotification? = nil
    @State private var historySearchText = ""
    @State private var historyCategoryFilter = "All"
    
    // Pre-built Production Templates
    private let defaultTemplates: [NotificationTemplate] = [
        NotificationTemplate(
            id: "tpl_morning",
            title: "🌅 Chào buổi sáng! Khởi động ngày mới với 5 từ vựng",
            body: "Nạp năng lượng tiếng Anh mỗi sáng giúp não bộ ghi nhớ sâu hơn gấp 2 lần. Bắt đầu ngay thôi!",
            category: "vocab",
            icon: "sun.max.fill",
            deepLink: "vocabulary",
            description: "Thích hợp gửi vào 07:30 - 08:30 sáng để tạo thói quen học tập."
        ),
        NotificationTemplate(
            id: "tpl_streak_save",
            title: "🔥 Đừng để vụt mất chuỗi {streak} ngày Streak!",
            body: "Chỉ còn vài tiếng nữa là hết ngày, hãy vào làm 1 bài Quiz ngắn để bảo vệ chuỗi học tập nhé.",
            category: "streak",
            icon: "flame.fill",
            deepLink: "quizzes",
            description: "Thích hợp gửi lúc 21:00 - 22:30 tối cho các học viên chưa hoàn thành mục tiêu ngày."
        ),
        NotificationTemplate(
            id: "tpl_srs_review",
            title: "🧠 Đã đến chu kỳ ôn tập Spaced Repetition (SRS)!",
            body: "Hệ thống phát hiện bạn có từ vựng cần ôn lại sau 1-3-7 ngày để tránh bị quên lãng. Xem ngay!",
            category: "srs",
            icon: "brain.head.profile",
            deepLink: "vocabulary",
            description: "Nhắc nhở học viên ôn lại từ vựng theo phương pháp lặp lại ngắt quãng chuẩn khoa học."
        ),
        NotificationTemplate(
            id: "tpl_weekend_event",
            title: "⚡️ Sự kiện Cuối Tuần: x2 XP Toàn Bộ Bài Luyện Tập!",
            body: "Nhân đôi điểm kinh nghiệm cho mọi câu trả lời đúng trên toàn hệ thống hôm nay. Bứt phá bảng xếp hạng!",
            category: "event",
            icon: "sparkles",
            deepLink: "quizzes",
            description: "Thích hợp phát vào sáng Thứ 7 hoặc Chủ Nhật để kích thích tinh thần đua top."
        ),
        NotificationTemplate(
            id: "tpl_listening_drop",
            title: "🎧 Bài nghe chép chính tả mới vừa cập nhật!",
            body: "Cùng luyện tai với các đoạn hội thoại thực tế chủ đề Sân bay và Du lịch quốc tế vừa được thêm.",
            category: "listening",
            icon: "headphones",
            deepLink: "listening",
            description: "Thông báo khi Admin vừa import thêm các bài nghe mới lên hệ thống."
        ),
        NotificationTemplate(
            id: "tpl_system_maintenance",
            title: "🛠 Thông báo bảo trì & Nâng cấp hệ thống AI",
            body: "Hệ thống máy chủ và trợ lý AI Gemini vừa được tối ưu hóa với tốc độ phản hồi nhanh hơn 30%.",
            category: "system",
            icon: "wrench.and.screwdriver.fill",
            deepLink: "home",
            description: "Thông báo kỹ thuật hoặc bảo trì định kỳ cho người dùng."
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - 1. Top Header
                headerView
                
                Divider().background(AdminTheme.border)
                
                // Toast Banner
                if let toast = toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.success)
                        Text(toast)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AdminTheme.textPrimary)
                        Spacer()
                        Button(action: { toastMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AdminTheme.textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AdminTheme.successBg)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.success.opacity(0.3), lineWidth: 1))
                    .cornerRadius(6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // MARK: - 2. Metrics Analytics Cards
                metricsOverviewSection
                
                // MARK: - 3. Navigation Sub-Tabs
                subTabsBar
                
                // MARK: - 4. Tab Content Switcher
                switch selectedSubTab {
                case 0:
                    composeAndPreviewSection
                case 1:
                    historySection
                case 2:
                    templatesSection
                case 3:
                    devicesAndTokensSection
                default:
                    composeAndPreviewSection
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
        }
        .background(AdminTheme.appBackground)
        .alert(isPresented: $showingDeleteAlert) {
            guard let notif = notifToDelete else { return Alert(title: Text("Error")) }
            return Alert(
                title: Text("Xóa thông báo đã gửi?"),
                message: Text("Hành động này sẽ gỡ thông báo \"\(notif.title)\" khỏi lịch sử hệ thống."),
                primaryButton: .destructive(Text("Xóa")) {
                    Task {
                        await viewModel.deleteNotification(id: notif.id)
                        toastMessage = "Đã xóa thông báo khỏi lịch sử!"
                    }
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
    
    // MARK: - 1. HEADER
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Quản Lý Thông Báo & Push Campaigns")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    
                    Text("FCM & SRS Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AdminTheme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AdminTheme.successBg)
                        .cornerRadius(5)
                }
                
                Text("Trung tâm phát thông báo đẩy, thiết lập chiến dịch giữ chân học viên và lịch sử thông báo.")
                    .font(.system(size: 13))
                    .foregroundColor(AdminTheme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {
                    Task {
                        await viewModel.loadAllData()
                        toastMessage = "Đã làm mới dữ liệu thông báo và học viên!"
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Làm mới")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AdminTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation { selectedSubTab = 0 }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Soạn Thông Báo (+)")
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
    }
    
    // MARK: - 2. METRICS OVERVIEW CARDS
    private var metricsOverviewSection: some View {
        HStack(spacing: 14) {
            metricCard(
                title: "Tổng Thông Báo Đã Phát",
                value: "\(viewModel.notifications.count)",
                icon: "bell.badge.fill",
                accentColor: Color(hex: "6366F1"),
                subText: "Chiến dịch lưu trên CSDL"
            )
            
            let fcmCount = viewModel.users.filter { $0.fcmToken != nil && !$0.fcmToken!.isEmpty }.count
            metricCard(
                title: "Thiết Bị Nhận Tin (FCM)",
                value: "\(fcmCount) / \(viewModel.users.count)",
                icon: "antenna.radiowaves.left.and.right",
                accentColor: Color(hex: "10B981"),
                subText: "\(viewModel.users.count > 0 ? Int(Double(fcmCount)/Double(viewModel.users.count)*100) : 100)% học viên sẵn sàng nhận"
            )
            
            metricCard(
                title: "Spaced Repetition (SRS)",
                value: "1 • 3 • 7 Ngày",
                icon: "brain.head.profile",
                accentColor: Color(hex: "F59E0B"),
                subText: "Tự động kích hoạt khi học từ"
            )
            
            let streakRiskCount = viewModel.users.filter { $0.streak > 0 }.count
            metricCard(
                title: "Học Viên Giữ Streak",
                value: "\(streakRiskCount)",
                icon: "flame.fill",
                accentColor: Color(hex: "EC4899"),
                subText: "Cần cứu Streak trước 23:00"
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, accentColor: Color, subText: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AdminTheme.textSecondary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AdminTheme.textPrimary)
            
            Text(subText)
                .font(.system(size: 10))
                .foregroundColor(AdminTheme.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AdminTheme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
        .cornerRadius(10)
    }
    
    // MARK: - 3. SUB-TABS BAR
    private var subTabsBar: some View {
        HStack(spacing: 8) {
            subTabButton(index: 0, title: "Soạn & Phát Thông Báo", icon: "paperplane.fill")
            subTabButton(index: 1, title: "Lịch Sử Chiến Dịch (\(viewModel.notifications.count))", icon: "clock.arrow.circlepath")
            subTabButton(index: 2, title: "Mẫu Sẵn & Tự Động (\(defaultTemplates.count))", icon: "sparkles")
            subTabButton(index: 3, title: "Thiết Bị & FCM Tokens (\(viewModel.users.count))", icon: "person.badge.shield.checkmark.fill")
            Spacer()
        }
        .padding(4)
        .background(AdminTheme.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
        .cornerRadius(8)
    }
    
    private func subTabButton(index: Int, title: String, icon: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedSubTab = index
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: selectedSubTab == index ? .bold : .medium))
                Text(title)
                    .font(.system(size: 12, weight: selectedSubTab == index ? .bold : .medium))
            }
            .foregroundColor(selectedSubTab == index ? .white : AdminTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedSubTab == index ? AdminTheme.primary : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 4. TAB 0: SOẠN & PHÁT THÔNG BÁO (WITH LIVE LOCKSCREEN PREVIEW)
    private var composeAndPreviewSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // LEFT FORM: CẤU HÌNH THÔNG BÁO
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AdminTheme.primary)
                    Text("SOẠN NỘI DUNG THÔNG BÁO ĐẨY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AdminTheme.textPrimary)
                        .tracking(0.5)
                    Spacer()
                }
                
                // 1. Target Audience Segmentation
                VStack(alignment: .leading, spacing: 6) {
                    Text("ĐỐI TƯỢNG NHẬN TIN (SEGMENTATION)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AdminTheme.textSecondary)
                    
                    Picker("Đối tượng", selection: $notifTargetType) {
                        Text("🌐 Tất cả học viên (Broadcast All)").tag("all")
                        Text("🔥 Học viên có nguy cơ mất Streak").tag("streak_risk")
                        Text("🧠 Học viên cần ôn tập SRS (1-3-7 ngày)").tag("srs_pending")
                        Text("👤 Gửi riêng cho 1 học viên cụ thể").tag("specific_user")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(AdminTheme.surfaceHover)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(6)
                    
                    if notifTargetType == "specific_user" {
                        Picker("Chọn học viên", selection: $notifSelectedUserId) {
                            Text("-- Chọn tài khoản nhận tin --").tag("")
                            ForEach(viewModel.users) { u in
                                Text("\(u.name) (\(u.email))").tag(u.uid)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                }
                
                // 2. Category & Deep Link
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOẠI THÔNG BÁO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        Picker("Thể loại", selection: $notifCategory) {
                            Text("📚 Từ Vựng Mới").tag("vocab")
                            Text("📝 Bài Quiz").tag("quiz")
                            Text("🎧 Luyện Nghe").tag("listening")
                            Text("🔥 Cứu Streak").tag("streak")
                            Text("🧠 Ôn Tập SRS").tag("srs")
                            Text("⚡️ Sự Kiện x2 XP").tag("event")
                            Text("🛠 Hệ Thống").tag("system")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ĐIỀU HƯỚNG KHI NHẤN (DEEP LINK)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textSecondary)
                        
                        Picker("Điều hướng", selection: $notifDeepLink) {
                            Text("🏠 Màn hình chính (Home)").tag("home")
                            Text("📖 Kho Từ Vựng (Vocabulary)").tag("vocabulary")
                            Text("🎯 Bài Kiểm Tra (Quiz)").tag("quizzes")
                            Text("🎧 Luyện Nghe (Listening)").tag("listening")
                            Text("👤 Hồ Sơ (Profile)").tag("profile")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                }
                
                // 3. Notification Title & Dynamic Chips
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("TIÊU ĐỀ THÔNG BÁO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textSecondary)
                        Spacer()
                        // Insert tag chips
                        HStack(spacing: 4) {
                            Text("Chèn thẻ:")
                                .font(.system(size: 9))
                                .foregroundColor(AdminTheme.textMuted)
                            Button("{user_name}") { notifTitle += " {user_name}" }
                                .buttonStyle(PlainButtonStyle())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                            Button("{streak}") { notifTitle += " {streak}" }
                                .buttonStyle(PlainButtonStyle())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                        }
                    }
                    
                    TextField("Nhập tiêu đề thông báo ngắn gọn, hấp dẫn...", text: $notifTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AdminTheme.textPrimary)
                        .padding(10)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                }
                
                // 4. Notification Body Message
                VStack(alignment: .leading, spacing: 6) {
                    Text("NỘI DUNG TIN NHẮN (BODY MESSAGE)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AdminTheme.textSecondary)
                    
                    TextEditor(text: $notifBody)
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(AdminTheme.surfaceHover)
                        .frame(height: 80)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                }
                
                // 5. Image Attachment (Cloudinary or URL)
                VStack(alignment: .leading, spacing: 6) {
                    Text("ẢNH ĐÍNH KÈM (CLOUDINARY / URL TÙY CHỌN)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AdminTheme.textSecondary)
                    
                    TextField("https://res.cloudinary.com/... hoặc để trống", text: $notifImageUrl)
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textPrimary)
                        .padding(10)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                }
                
                Divider().background(AdminTheme.border)
                
                // Action Buttons
                HStack {
                    Button(action: {
                        notifTitle = ""
                        notifBody = ""
                        notifImageUrl = ""
                    }) {
                        Text("Xóa trắng")
                            .font(.system(size: 12))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: executeSendNotification) {
                        HStack(spacing: 6) {
                            if isSending {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text("Phát Thông Báo Ngay (Send Now)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(isSendDisabled ? AdminTheme.border : AdminTheme.primary)
                        .cornerRadius(7)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSendDisabled)
                }
            }
            .padding(20)
            .background(AdminTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdminTheme.border, lineWidth: 1))
            .cornerRadius(12)
            
            // RIGHT PANE: LIVE MOBILE LOCKSCREEN MOCKUP PREVIEW
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "iphone.gen3")
                        .foregroundColor(AdminTheme.primary)
                    Text("MÔ PHỎNG MÀN HÌNH KHÓA (LIVE PREVIEW)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textPrimary)
                    Spacer()
                }
                
                // iPhone Lock Screen Frame Mockup
                VStack(spacing: 12) {
                    // Lockscreen Clock & Date Header
                    VStack(spacing: 2) {
                        Text("Thứ Năm, 18 tháng 9")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text("09:41")
                            .font(.system(size: 40, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 14)
                    
                    // The Push Notification Banner
                    VStack(alignment: .leading, spacing: 8) {
                        // App Info Top
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(AdminTheme.primary)
                                    .frame(width: 18, height: 18)
                                Image(systemName: "book.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("APP LEARN ENGLISH")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("vừa xong")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: categoryIcon(for: notifCategory))
                                .font(.system(size: 10))
                                .foregroundColor(categoryColor(for: notifCategory))
                        }
                        
                        // Title & Body
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(renderedTitle)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                
                                Text(renderedBody)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(3)
                            }
                            
                            Spacer()
                            
                            // Image Preview if provided
                            if !notifImageUrl.isEmpty, let url = URL(string: notifImageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill().frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 6))
                                    default:
                                        RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)).frame(width: 40, height: 40)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.15))
                    .background(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .cornerRadius(14)
                    .padding(.horizontal, 14)
                    
                    Spacer()
                    
                    // Bottom Lockscreen Bar
                    HStack {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 34, height: 34)
                            Image(systemName: "flashlight.on.fill").font(.system(size: 13)).foregroundColor(.white)
                        }
                        Spacer()
                        ZStack {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 34, height: 34)
                            Image(systemName: "camera.fill").font(.system(size: 13)).foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
                }
                .frame(width: 290, height: 380)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1E1B4B"), Color(hex: "0F172A"), Color(hex: "020617")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 2))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
            .frame(width: 340)
            .background(AdminTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdminTheme.border, lineWidth: 1))
            .cornerRadius(12)
        }
    }
    
    private var renderedTitle: String {
        let sampleName = notifTargetType == "specific_user" ? (viewModel.users.first(where: { $0.uid == notifSelectedUserId })?.name ?? "Học viên") : "Minh Quân"
        return notifTitle
            .replacingOccurrences(of: "{user_name}", with: sampleName)
            .replacingOccurrences(of: "{streak}", with: "7")
            .replacingOccurrences(of: "{app_name}", with: "AppLearnEnglish")
    }
    
    private var renderedBody: String {
        let sampleName = notifTargetType == "specific_user" ? (viewModel.users.first(where: { $0.uid == notifSelectedUserId })?.name ?? "Học viên") : "Minh Quân"
        return notifBody
            .replacingOccurrences(of: "{user_name}", with: sampleName)
            .replacingOccurrences(of: "{streak}", with: "7")
            .replacingOccurrences(of: "{app_name}", with: "AppLearnEnglish")
    }
    
    private var isSendDisabled: Bool {
        isSending || notifTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || notifBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (notifTargetType == "specific_user" && notifSelectedUserId.isEmpty)
    }
    
    private func executeSendNotification() {
        isSending = true
        
        let targetUserName = (notifTargetType == "specific_user")
            ? viewModel.users.first(where: { $0.uid == notifSelectedUserId })?.name
            : nil
        
        Task {
            // 1. Send Local Notification via UNUserNotificationCenter for instant test
            let content = UNMutableNotificationContent()
            content.title = renderedTitle
            content.body = renderedBody
            content.sound = .default
            content.userInfo = ["deepLink": notifDeepLink, "category": notifCategory]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let req = UNNotificationRequest(identifier: "admin_campaign_\(UUID().uuidString)", content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(req)
            
            // 2. Persist to Firestore /notifications_history
            let success = await viewModel.sendNotification(
                title: renderedTitle,
                body: renderedBody,
                targetType: notifTargetType,
                targetUserId: (notifTargetType == "specific_user") ? notifSelectedUserId : nil,
                targetUserName: targetUserName,
                category: notifCategory,
                deepLink: notifDeepLink,
                imageUrl: notifImageUrl.isEmpty ? nil : notifImageUrl
            )
            
            await MainActor.run {
                isSending = false
                if success {
                    toastMessage = "Đã phát thông báo thành công và lưu vào lịch sử chiến dịch!"
                }
            }
        }
    }
    
    // MARK: - 5. TAB 1: LỊCH SỬ THÔNG BÁO (HISTORY)
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Filter Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AdminTheme.textMuted)
                    TextField("Tìm kiếm thông báo theo tiêu đề hoặc nội dung...", text: $historySearchText)
                        .font(.system(size: 13))
                        .foregroundColor(AdminTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AdminTheme.surfaceHover)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(6)
                
                Picker("Phân loại", selection: $historyCategoryFilter) {
                    Text("Tất cả thể loại").tag("All")
                    Text("Từ Vựng").tag("vocab")
                    Text("Quiz").tag("quiz")
                    Text("Luyện Nghe").tag("listening")
                    Text("Cứu Streak").tag("streak")
                    Text("SRS").tag("srs")
                    Text("Sự Kiện").tag("event")
                    Text("Hệ Thống").tag("system")
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AdminTheme.surfaceHover)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(6)
            }
            
            if filteredHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 36))
                        .foregroundColor(AdminTheme.textMuted)
                    Text("Chưa có lịch sử thông báo nào")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                    Text("Các thông báo được gửi từ Tab Soạn tin sẽ tự động lưu lại tại đây.")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(AdminTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(10)
            } else {
                // Table
                VStack(spacing: 0) {
                    // Header Row
                    HStack {
                        Text("THỜI GIAN").frame(width: 110, alignment: .leading)
                        Text("TIÊU ĐỀ & NỘI DUNG").frame(maxWidth: .infinity, alignment: .leading)
                        Text("ĐỐI TƯỢNG").frame(width: 140, alignment: .leading)
                        Text("LOẠI TIN").frame(width: 100, alignment: .leading)
                        Text("ĐIỀU HƯỚNG").frame(width: 90, alignment: .leading)
                        Text("TRẠNG THÁI").frame(width: 90, alignment: .center)
                        Text("THAO TÁC").frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AdminTheme.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AdminTheme.surfaceHover)
                    
                    Divider().background(AdminTheme.border)
                    
                    ForEach(filteredHistory) { notif in
                        HStack {
                            Text(formatDate(notif.sentAt))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AdminTheme.textSecondary)
                                .frame(width: 110, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(notif.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .lineLimit(1)
                                Text(notif.body)
                                    .font(.system(size: 11))
                                    .foregroundColor(AdminTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                Image(systemName: targetIcon(for: notif.targetType))
                                    .font(.system(size: 9))
                                Text(targetLabel(for: notif.targetType, userName: notif.targetUserName))
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .frame(width: 140, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                Circle().fill(categoryColor(for: notif.category)).frame(width: 6, height: 6)
                                Text(categoryLabel(for: notif.category))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AdminTheme.textSecondary)
                            }
                            .frame(width: 100, alignment: .leading)
                            
                            Text(notif.deepLink ?? "home")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(AdminTheme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AdminTheme.primaryLight)
                                .cornerRadius(4)
                                .frame(width: 90, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(AdminTheme.success)
                                Text("Đã phát")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AdminTheme.success)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AdminTheme.successBg)
                            .cornerRadius(4)
                            .frame(width: 90, alignment: .center)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    notifToDelete = notif
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(AdminTheme.danger)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        Divider().background(AdminTheme.border)
                    }
                }
                .background(AdminTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
                .cornerRadius(10)
            }
        }
    }
    
    private var filteredHistory: [AdminNotification] {
        var list = viewModel.notifications
        let query = historySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { $0.title.lowercased().contains(query) || $0.body.lowercased().contains(query) }
        }
        if historyCategoryFilter != "All" {
            list = list.filter { $0.category.lowercased() == historyCategoryFilter.lowercased() }
        }
        return list
    }
    
    // MARK: - 6. TAB 2: MẪU THÔNG BÁO SẴN (TEMPLATES)
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MẪU THÔNG BÁO TỐI ƯU RETENTION CHO HỌC VIÊN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AdminTheme.textSecondary)
                .tracking(0.5)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(defaultTemplates) { tpl in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor(for: tpl.category).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: tpl.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(categoryColor(for: tpl.category))
                            }
                            
                            Text(categoryLabel(for: tpl.category))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(categoryColor(for: tpl.category))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(categoryColor(for: tpl.category).opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Button(action: {
                                applyTemplate(tpl)
                            }) {
                                HStack(spacing: 4) {
                                    Text("Sử dụng mẫu này")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AdminTheme.primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text(tpl.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AdminTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(tpl.body)
                            .font(.system(size: 12))
                            .foregroundColor(AdminTheme.textSecondary)
                            .lineLimit(2)
                        
                        Text("💡 \(tpl.description)")
                            .font(.system(size: 10))
                            .foregroundColor(AdminTheme.textMuted)
                            .lineLimit(1)
                    }
                    .padding(14)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private func applyTemplate(_ tpl: NotificationTemplate) {
        notifTitle = tpl.title
        notifBody = tpl.body
        notifCategory = tpl.category
        notifDeepLink = tpl.deepLink
        withAnimation {
            selectedSubTab = 0
            toastMessage = "Đã áp dụng mẫu thông báo \"\(tpl.title)\" vào khung soạn tin!"
        }
    }
    
    // MARK: - 7. TAB 3: THIẾT BỊ & TOKENS FCM
    private var devicesAndTokensSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("DANH SÁCH THIẾT BỊ & FCM SUBSCRIBERS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AdminTheme.textSecondary)
                Spacer()
                Text("Tổng \(viewModel.users.count) học viên")
                    .font(.system(size: 11))
                    .foregroundColor(AdminTheme.textMuted)
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("HỌC VIÊN").frame(width: 180, alignment: .leading)
                    Text("EMAIL").frame(width: 200, alignment: .leading)
                    Text("CHUỖI STREAK").frame(width: 100, alignment: .leading)
                    Text("FCM DEVICE TOKEN").frame(maxWidth: .infinity, alignment: .leading)
                    Text("TRẠNG THÁI").frame(width: 100, alignment: .center)
                    Text("HÀNH ĐỘNG").frame(width: 90, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AdminTheme.textMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AdminTheme.surfaceHover)
                
                Divider().background(AdminTheme.border)
                
                ForEach(viewModel.users) { user in
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle().fill(AdminTheme.primaryLight).frame(width: 26, height: 26)
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AdminTheme.primary)
                            }
                            Text(user.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AdminTheme.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(width: 180, alignment: .leading)
                        
                        Text(user.email)
                            .font(.system(size: 11))
                            .foregroundColor(AdminTheme.textSecondary)
                            .frame(width: 200, alignment: .leading)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(user.streak > 0 ? Color(hex: "F59E0B") : AdminTheme.textMuted)
                                .font(.system(size: 10))
                            Text("\(user.streak) ngày")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AdminTheme.textPrimary)
                        }
                        .frame(width: 100, alignment: .leading)
                        
                        if let token = user.fcmToken, !token.isEmpty {
                            Text("Token: \(token.prefix(18))...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(AdminTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                        } else {
                            Text("Chưa đăng ký Token")
                                .font(.system(size: 10))
                                .foregroundColor(AdminTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack(spacing: 4) {
                            Circle().fill(AdminTheme.success).frame(width: 6, height: 6)
                            Text("Sẵn sàng")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AdminTheme.success)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AdminTheme.successBg)
                        .cornerRadius(4)
                        .frame(width: 100, alignment: .center)
                        
                        Button(action: {
                            notifTargetType = "specific_user"
                            notifSelectedUserId = user.uid
                            notifTitle = "Chào \(user.name), cùng học bài mới nhé!"
                            withAnimation {
                                selectedSubTab = 0
                            }
                        }) {
                            Text("Gửi riêng")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AdminTheme.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 90, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    Divider().background(AdminTheme.border)
                }
            }
            .background(AdminTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminTheme.border, lineWidth: 1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm"
        return formatter.string(from: date)
    }
    
    private func categoryLabel(for cat: String) -> String {
        switch cat {
        case "vocab": return "Từ Vựng"
        case "quiz": return "Quiz"
        case "listening": return "Luyện Nghe"
        case "streak": return "Cứu Streak"
        case "srs": return "Ôn Tập SRS"
        case "event": return "Sự Kiện"
        case "system": return "Hệ Thống"
        default: return "Thông báo"
        }
    }
    
    private func categoryColor(for cat: String) -> Color {
        switch cat {
        case "vocab": return Color(hex: "6366F1")
        case "quiz": return Color(hex: "F59E0B")
        case "listening": return Color(hex: "06B6D4")
        case "streak": return Color(hex: "EF4444")
        case "srs": return Color(hex: "10B981")
        case "event": return Color(hex: "EC4899")
        case "system": return Color(hex: "64748B")
        default: return AdminTheme.primary
        }
    }
    
    private func categoryIcon(for cat: String) -> String {
        switch cat {
        case "vocab": return "book.closed.fill"
        case "quiz": return "checklist"
        case "listening": return "headphones"
        case "streak": return "flame.fill"
        case "srs": return "brain.head.profile"
        case "event": return "sparkles"
        case "system": return "wrench.and.screwdriver.fill"
        default: return "bell.fill"
        }
    }
    
    private func targetLabel(for target: String, userName: String?) -> String {
        switch target {
        case "all": return "Tất cả học viên"
        case "streak_risk": return "Học viên giữ Streak"
        case "srs_pending": return "Cần ôn SRS"
        case "specific_user": return userName ?? "1 Học viên"
        default: return "Học viên"
        }
    }
    
    private func targetIcon(for target: String) -> String {
        switch target {
        case "all": return "globe"
        case "streak_risk": return "flame.fill"
        case "srs_pending": return "brain.head.profile"
        case "specific_user": return "person.fill"
        default: return "person.2.fill"
        }
    }
}
