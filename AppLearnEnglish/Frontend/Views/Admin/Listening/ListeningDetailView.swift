//
//  ListeningDetailView.swift
//  AppLearnEnglish
//

import SwiftUI

struct ListeningDetailView: View {
    let topic: Topic
    @ObservedObject var viewModel: AdminViewModel
    let onBack: () -> Void
    
    @State private var searchSentenceText = ""
    @State private var selectedLevelFilter = "All"
    
    // Sheet states
    @State private var showingAddListeningSheet = false
    @State private var editingListening: ListeningExercise? = nil
    @State private var showingImportSheet = false
    @State private var showingEditTopicSheet = false
    
    // Detail Inspector Drawer State
    @State private var selectedListeningForInspector: ListeningExercise? = nil
    @State private var hoveredRowId: String? = nil
    
    // Delete alert
    @State private var listeningToDelete: ListeningExercise? = nil
    @State private var showingDeleteAlert = false
    @State private var showingDeleteTopicAlert = false
    
    // Dynamic topic reference to reflect immediate edits
    private var currentTopic: Topic {
        viewModel.listeningTopics.first(where: { $0.id == topic.id }) ?? topic
    }
    
    var topicExercises: [ListeningExercise] {
        var list = viewModel.listeningExercises.filter { $0.topicId == currentTopic.id }
        
        let query = searchSentenceText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                $0.sentence.lowercased().contains(query) ||
                $0.translation.lowercased().contains(query) ||
                ($0.hint?.lowercased().contains(query) ?? false)
            }
        }
        
        if selectedLevelFilter != "All" {
            list = list.filter { ($0.level).lowercased() == selectedLevelFilter.lowercased() }
        }
        
        return list
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // MARK: - Header with Back Button & Breadcrumbs
                HStack(alignment: .center) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                            Text("Quay lại danh sách bộ nghe")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AdminTheme.primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("/")
                        .foregroundColor(AdminTheme.textMuted)
                        .font(.system(size: 13))
                    
                    HStack(spacing: 12) {
                        // Topic Cover Image or Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AdminTheme.surface)
                                .frame(width: 44, height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                            
                            if (currentTopic.image.hasPrefix("http://") || currentTopic.image.hasPrefix("https://")), let url = URL(string: currentTopic.image) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    default:
                                        ProgressView().scaleEffect(0.6)
                                    }
                                }
                            } else {
                                Image(systemName: currentTopic.image.isEmpty ? "headphones" : currentTopic.image)
                                    .font(.system(size: 20))
                                    .foregroundColor(AdminTheme.primary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(currentTopic.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AdminTheme.textPrimary)
                                
                                Text("\(viewModel.listeningExercises.filter { $0.topicId == currentTopic.id }.count) câu nghe")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AdminTheme.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AdminTheme.primaryLight)
                                    .cornerRadius(10)
                            }
                            
                            if !currentTopic.description.isEmpty {
                                Text(currentTopic.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(AdminTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 8) {
                        // Edit Set Meta
                        Button(action: {
                            showingEditTopicSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Sửa thông tin bộ")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete Set
                        Button(action: {
                            showingDeleteTopicAlert = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Xóa bộ nghe")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AdminTheme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AdminTheme.dangerBg)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Import into this Set
                        Button(action: {
                            showingImportSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Import vào bộ này")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(AdminTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add Single Sentence
                        Button(action: {
                            editingListening = nil
                            showingAddListeningSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Thêm câu nghe")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
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
                
                // MARK: - Search & Level Filter Toolbar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        TextField("Tìm kiếm câu tiếng Anh, bản dịch, gợi ý...", text: $searchSentenceText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AdminTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                    .cornerRadius(6)
                    .frame(maxWidth: 320)
                    
                    Picker("Level", selection: $selectedLevelFilter) {
                        Text("Tất cả cấp độ").tag("All")
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                    
                    Spacer()
                    
                    Text("Hiển thị \(topicExercises.count) câu nghe")
                        .font(.system(size: 12))
                        .foregroundColor(AdminTheme.textMuted)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(AdminTheme.surfaceHover)
                
                Divider().background(AdminTheme.border)
                
                // MARK: - Questions / Sentences Table
                if topicExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "headphones")
                            .font(.system(size: 44))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Text("Bộ bài nghe này chưa có câu luyện tập nào")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AdminTheme.textPrimary)
                        
                        Text("Nhấn 'Thêm câu nghe' hoặc 'Import vào bộ này' để bổ sung nội dung.")
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(topicExercises) { item in
                                let isSelected = selectedListeningForInspector?.id == item.id
                                
                                HStack(alignment: .center, spacing: 14) {
                                    // Audio play button
                                    Button(action: {
                                        AdminSpeechHelper.shared.speak(item.sentence)
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(AdminTheme.primaryLight)
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(AdminTheme.primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Sentence and Translation
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.sentence)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AdminTheme.textPrimary)
                                        
                                        Text(item.translation)
                                            .font(.system(size: 12))
                                            .foregroundColor(AdminTheme.textSecondary)
                                        
                                        if let hint = item.hint, !hint.isEmpty {
                                            Text("Gợi ý: \(hint)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(AdminTheme.warning)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Cloudinary Stream Badge (if custom audio)
                                    if let audio = item.audioUrl, !audio.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "waveform")
                                                .font(.system(size: 10))
                                            Text("Audio CDN")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(AdminTheme.accentBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AdminTheme.accentBlue.opacity(0.12))
                                        .cornerRadius(4)
                                    }
                                    
                                    // Level badge
                                    levelBadgeView(level: item.level)
                                    
                                    // Action buttons
                                    HStack(spacing: 6) {
                                        Button(action: {
                                            editingListening = item
                                            showingAddListeningSheet = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AdminTheme.textSecondary)
                                                .padding(6)
                                                .background(AdminTheme.surfaceHover)
                                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AdminTheme.border, lineWidth: 1))
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            listeningToDelete = item
                                            showingDeleteAlert = true
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                                .foregroundColor(AdminTheme.danger)
                                                .padding(6)
                                                .background(AdminTheme.dangerBg)
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                if selectedListeningForInspector?.id == item.id {
                                                    selectedListeningForInspector = nil
                                                } else {
                                                    selectedListeningForInspector = item
                                                }
                                            }
                                        }) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 12))
                                                .foregroundColor(isSelected ? AdminTheme.primary : AdminTheme.textMuted)
                                                .padding(6)
                                                .background(isSelected ? AdminTheme.primaryLight : AdminTheme.surfaceHover)
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(isSelected ? AdminTheme.primaryLight.opacity(0.4) : (hoveredRowId == item.id ? AdminTheme.surfaceHover : AdminTheme.surface))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? AdminTheme.primary : AdminTheme.border, lineWidth: 1)
                                )
                                .cornerRadius(8)
                                .onHover { isHovered in
                                    hoveredRowId = isHovered ? item.id : nil
                                }
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.vertical, 16)
                    }
                }
            }
            
            // MARK: - Inspector Panel Drawer
            if let exercise = selectedListeningForInspector {
                Rectangle()
                    .fill(AdminTheme.border)
                    .frame(width: 1)
                    .ignoresSafeArea()
                
                listeningInspectorPanel(exercise: exercise)
                    .frame(width: 320)
                    .background(AdminTheme.surface)
                    .transition(.move(edge: .trailing))
            }
        }
        .sheet(isPresented: $showingAddListeningSheet) {
            ListeningFormSheet(
                viewModel: viewModel,
                editingListening: editingListening,
                defaultTopicId: currentTopic.id,
                isPresented: $showingAddListeningSheet
            )
        }
        .sheet(isPresented: $showingImportSheet) {
            ListeningImportSheet(
                viewModel: viewModel,
                defaultTopicId: currentTopic.id,
                isPresented: $showingImportSheet
            )
        }
        .sheet(isPresented: $showingEditTopicSheet) {
            ListeningTopicFormSheet(
                viewModel: viewModel,
                editingTopic: currentTopic,
                isPresented: $showingEditTopicSheet
            )
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Xóa bài nghe này?"),
                message: Text("Hành động này sẽ xóa vĩnh viễn câu luyện nghe trên cơ sở dữ liệu."),
                primaryButton: .destructive(Text("Xóa")) {
                    if let item = listeningToDelete {
                        Task {
                            await viewModel.deleteListeningExercise(exerciseId: item.id, topicId: item.topicId)
                            if selectedListeningForInspector?.id == item.id {
                                selectedListeningForInspector = nil
                            }
                        }
                    }
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
        .alert(isPresented: $showingDeleteTopicAlert) {
            let count = viewModel.listeningExercises.filter { $0.topicId == currentTopic.id }.count
            return Alert(
                title: Text("Xóa bộ bài nghe “\(currentTopic.name)”?"),
                message: Text("Hành động này sẽ xóa bộ bài nghe cùng tất cả \(count) câu luyện tập bên trong trên Firestore và không thể hoàn tác."),
                primaryButton: .destructive(Text("Xóa bộ bài nghe")) {
                    Task {
                        await viewModel.deleteListeningTopic(topicId: currentTopic.id)
                        onBack()
                    }
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
    
    // MARK: - Inspector Drawer Panel
    private func listeningInspectorPanel(exercise: ListeningExercise) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("CHI TIẾT BÀI NGHE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AdminTheme.textMuted)
                        .tracking(0.8)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedListeningForInspector = nil
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AdminTheme.textMuted)
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Audio Player Card
                VStack(spacing: 12) {
                    Button(action: {
                        AdminSpeechHelper.shared.speak(exercise.sentence)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Nghe phát âm chuẩn (TTS)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AdminTheme.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let audio = exercise.audioUrl, !audio.isEmpty {
                        Text("Cloudinary Audio Stream Active")
                            .font(.system(size: 11))
                            .foregroundColor(AdminTheme.accentBlue)
                    }
                }
                .padding(14)
                .background(AdminTheme.surfaceHover)
                .cornerRadius(10)
                
                // Content Section
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CÂU TIẾNG ANH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Text(exercise.sentence)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AdminTheme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BẢN DỊCH TIẾNG VIỆT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AdminTheme.textMuted)
                        
                        Text(exercise.translation)
                            .font(.system(size: 13))
                            .foregroundColor(AdminTheme.textSecondary)
                    }
                    
                    if let hint = exercise.hint, !hint.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GỢI Ý / TỪ KHÓA")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AdminTheme.textMuted)
                            
                            Text(hint)
                                .font(.system(size: 12))
                                .foregroundColor(AdminTheme.warning)
                                .padding(10)
                                .background(AdminTheme.warningBg)
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CẤP ĐỘ")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AdminTheme.textMuted)
                            
                            levelBadgeView(level: exercise.level)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider().background(AdminTheme.border)
                
                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: {
                        editingListening = exercise
                        showingAddListeningSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Chỉnh sửa bài nghe")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AdminTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AdminTheme.surfaceHover)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        listeningToDelete = exercise
                        showingDeleteAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Xóa câu này")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AdminTheme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(AdminTheme.dangerBg)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(18)
        }
    }
    
    // MARK: - Level Badge View
    private func levelBadgeView(level: String) -> some View {
        let (bg, fg): (Color, Color) = {
            switch level.lowercased() {
            case "beginner":
                return (AdminTheme.successBg, AdminTheme.success)
            case "intermediate":
                return (AdminTheme.warningBg, AdminTheme.warning)
            case "advanced":
                return (AdminTheme.dangerBg, AdminTheme.danger)
            default:
                return (AdminTheme.surfaceHover, AdminTheme.textSecondary)
            }
        }()
        
        return Text(level)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(bg)
            .cornerRadius(4)
    }
}
