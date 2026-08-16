//
//  VocabularyView.swift
//  AppLearnEnglish
//

import SwiftUI

struct VocabularyView: View {
    @EnvironmentObject var viewModel: VocabularyViewModel
    @State private var showAddTopicSheet = false
    
    let filterOptions = ["Tất cả", "Đời sống", "Du lịch", "Công sở", "Công nghệ", "Cá nhân"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - 1. HEADER: Title & Search Bar
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Học Từ Vựng 📚")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        
                        Text("Tra cứu chủ đề hoặc xây dựng bộ từ vựng của riêng bạn")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Cute Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        
                        TextField("Tìm kiếm bộ từ vựng...", text: $viewModel.searchText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(18)
                    .padding(.horizontal)
                }
                
                // MARK: - 2. SUB-HEADER: Filters Bar (Thanh lọc bộ từ vựng)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filterOptions, id: \.self) { filter in
                            let isSelected = viewModel.selectedFilter == filter
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    viewModel.selectedFilter = filter
                                }
                            }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : AppTheme.textMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? AppTheme.primaryMint : Color.black.opacity(0.04))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - 3. BODY: Topics Grid
                if viewModel.isLoading && viewModel.topics.isEmpty {
                    VStack {
                        ProgressView()
                            .tint(AppTheme.primaryMint)
                        Text("Đang tải danh sách chủ đề...")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                } else {
                    let filtered = viewModel.filteredTopics
                    
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Text("🔍")
                                .font(.system(size: 32))
                            Text("Không tìm thấy bộ từ vựng nào phù hợp.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Display Filtered list
                        LazyVStack(spacing: 16) {
                            ForEach(filtered) { topic in
                                NavigationLink(destination: TopicDetailView(topic: topic, viewModel: viewModel)) {
                                    TopicCard(topic: topic)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // MARK: - 4. FOOTER: Create Custom Vocabulary Set Section
                VStack(alignment: .leading, spacing: 14) {
                    Divider()
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    Text("Bộ Từ Vựng Cá Nhân 📋")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal)
                    
                    // Create New Topic Button Card
                    Button(action: { showAddTopicSheet = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.primaryCoral.opacity(0.15))
                                    .frame(width: 54, height: 54)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(AppTheme.primaryCoral)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tạo bộ từ vựng mới")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(AppTheme.textDark)
                                
                                Text("Tự thêm từ mới của riêng bạn để ghi nhớ và ôn tập")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textLight)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cuteCardStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Từ vựng")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadUserPreferences()
            }
        }
        .sheet(isPresented: $showAddTopicSheet) {
            AddTopicSheet(viewModel: viewModel)
        }
    }
}

// MARK: - AddTopicSheet

struct AddTopicSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VocabularyViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "book.closed.circle.fill"
    
    let icons = [
        "book.closed.circle.fill", 
        "pencil.circle.fill", 
        "graduationcap.circle.fill", 
        "briefcase.circle.fill", 
        "cpu.circle.fill", 
        "heart.circle.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin bộ từ vựng")) {
                    TextField("Tên bộ từ vựng (ví dụ: Từ vựng TOEFL)", text: $name)
                    TextField("Mô tả ngắn gọn", text: $description)
                }
                
                Section(header: Text("Biểu tượng đại diện")) {
                    Picker("Chọn biểu tượng", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(AppTheme.primaryMint)
                                Text(icon.replacingOccurrences(of: ".circle.fill", with: "").capitalized)
                            }
                            .tag(icon)
                        }
                    }
                }
            }
            .navigationTitle("Tạo bộ từ vựng mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tạo") {
                        if !name.isEmpty {
                            viewModel.addCustomTopic(name: name, description: description, icon: selectedIcon)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VocabularyView()
            .environmentObject(VocabularyViewModel())
    }
}
