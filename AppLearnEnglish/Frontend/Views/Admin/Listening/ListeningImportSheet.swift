//
//  ListeningImportSheet.swift
//  AppLearnEnglish
//

import SwiftUI

struct ListeningImportSheet: View {
    @ObservedObject var viewModel: AdminViewModel
    @Binding var isPresented: Bool
    let defaultTopicId: String?
    
    @State private var listeningImportText = ""
    @State private var isListeningImportJSON = true
    @State private var listeningImportTopicMode = "new" // "existing" or "new"
    @State private var listeningImportSelectedTopicId = "travel"
    @State private var listeningImportNewTopicName = ""
    @State private var listeningImportNewTopicDesc = ""
    @State private var listeningImportNewTopicImage = "https://res.cloudinary.com/dzmnki3sy/image/upload/v1788873266/tmbxh3wm3viajuoocnmp.jpg"
    
    init(viewModel: AdminViewModel, defaultTopicId: String? = nil, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.defaultTopicId = defaultTopicId
        self._isPresented = isPresented
        
        if let dId = defaultTopicId, !dId.isEmpty {
            _listeningImportTopicMode = State(initialValue: "existing")
            _listeningImportSelectedTopicId = State(initialValue: dId)
        } else {
            _listeningImportTopicMode = State(initialValue: "new")
            _listeningImportSelectedTopicId = State(initialValue: viewModel.listeningTopics.first?.id ?? "travel")
        }
    }
    
    // Processing state
    @State private var isImporting = false
    
    // Parsed preview record
    struct ParsedListeningItem: Identifiable {
        let id = UUID()
        let sentence: String
        let translation: String
        let level: String
        let hint: String?
        let audioUrl: String?
        let isValid: Bool
        let errorReason: String?
    }
    
    struct LooseListening: Decodable {
        let sentence: String?
        let translation: String?
        let level: String?
        let hint: String?
        let audioUrl: String?
        let audio: String?
    }
    
    struct FullListeningTopicPackage: Decodable {
        let topicName: String?
        let name: String?
        let title: String?
        let topicDescription: String?
        let description: String?
        let desc: String?
        let imageUrl: String?
        let image: String?
        let topicImage: String?
        let coverImage: String?
        let icon: String?
        let sentences: [LooseListening]?
        let exercises: [LooseListening]?
        let items: [LooseListening]?
        let listening: [LooseListening]?
    }
    
    private var parsedItems: [ParsedListeningItem] {
        let trimmed = listeningImportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var list: [ParsedListeningItem] = []
        
        if isListeningImportJSON {
            if let data = trimmed.data(using: .utf8) {
                // Try 1: Decoded as full topic package object
                if let package = try? JSONDecoder().decode(FullListeningTopicPackage.self, from: data) {
                    let items = package.sentences ?? package.exercises ?? package.items ?? package.listening ?? []
                    for item in items {
                        list.append(parseLooseListening(item))
                    }
                }
                // Try 2: Decoded as array of listening exercises
                else if let items = try? JSONDecoder().decode([LooseListening].self, from: data) {
                    for item in items {
                        list.append(parseLooseListening(item))
                    }
                }
            }
        } else {
            let lines = trimmed.components(separatedBy: .newlines)
            var startIndex = 0
            if lines.indices.contains(0) && (lines[0].lowercased().contains("sentence") || lines[0].lowercased().contains("tiếng anh")) {
                startIndex = 1
            }
            
            for i in startIndex..<lines.count {
                let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty { continue }
                
                let fields = parseAdminCSVRow(line)
                if fields.count >= 2 {
                    let s = fields[0]
                    let tr = fields[1]
                    
                    var lvl = "Beginner"
                    var hint: String? = nil
                    var audioUrl: String? = nil
                    
                    if fields.count >= 5 {
                        // sentence, translation, level, hint, audioUrl
                        lvl = fields[2].isEmpty ? "Beginner" : fields[2]
                        hint = fields[3].isEmpty ? nil : fields[3]
                        audioUrl = fields[4].isEmpty ? nil : fields[4]
                    } else if fields.count == 4 {
                        let f2 = fields[2]
                        if ["beginner", "intermediate", "advanced"].contains(f2.lowercased()) {
                            lvl = f2.capitalized
                            if fields[3].hasPrefix("http") {
                                audioUrl = fields[3]
                            } else {
                                hint = fields[3].isEmpty ? nil : fields[3]
                            }
                        } else {
                            hint = f2
                            audioUrl = fields[3].hasPrefix("http") ? fields[3] : nil
                        }
                    } else if fields.count == 3 {
                        let f2 = fields[2]
                        if ["beginner", "intermediate", "advanced"].contains(f2.lowercased()) {
                            lvl = f2.capitalized
                        } else if f2.hasPrefix("http") {
                            audioUrl = f2
                        } else {
                            hint = f2
                        }
                    }
                    
                    if s.isEmpty {
                        list.append(ParsedListeningItem(sentence: "(Trống)", translation: tr, level: lvl, hint: hint, audioUrl: audioUrl, isValid: false, errorReason: "Thiếu câu tiếng Anh"))
                    } else if tr.isEmpty {
                        list.append(ParsedListeningItem(sentence: s, translation: "(Trống)", level: lvl, hint: hint, audioUrl: audioUrl, isValid: false, errorReason: "Thiếu bản dịch tiếng Việt"))
                    } else {
                        list.append(ParsedListeningItem(sentence: s, translation: tr, level: lvl, hint: hint, audioUrl: audioUrl, isValid: true, errorReason: nil))
                    }
                } else {
                    list.append(ParsedListeningItem(
                        sentence: line,
                        translation: "",
                        level: "Beginner",
                        hint: nil,
                        audioUrl: nil,
                        isValid: false,
                        errorReason: "Dòng không đủ 2 cột (sentence, translation)"
                    ))
                }
            }
        }
        
        return list
    }
    
    private func parseLooseListening(_ item: LooseListening) -> ParsedListeningItem {
        let s = item.sentence?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tr = item.translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lvl = item.level?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Beginner"
        let hint = item.hint?.trimmingCharacters(in: .whitespacesAndNewlines)
        let audio = item.audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? item.audio?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if s.isEmpty {
            return ParsedListeningItem(sentence: "(Trống)", translation: tr, level: lvl, hint: hint, audioUrl: audio, isValid: false, errorReason: "Thiếu câu tiếng Anh")
        } else if tr.isEmpty {
            return ParsedListeningItem(sentence: s, translation: "(Trống)", level: lvl, hint: hint, audioUrl: audio, isValid: false, errorReason: "Thiếu bản dịch tiếng Việt")
        } else {
            return ParsedListeningItem(sentence: s, translation: tr, level: lvl, hint: hint, audioUrl: (audio?.isEmpty == false) ? audio : nil, isValid: true, errorReason: nil)
        }
    }
    
    private var validItemsCount: Int {
        parsedItems.filter { $0.isValid }.count
    }
    
    private var invalidItemsCount: Int {
        parsedItems.filter { !$0.isValid }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AdminTheme.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Section 1: Chọn hoặc Tạo Bộ Dữ Liệu
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AdminTheme.primary)
                                Text("1. CHỌN HOẶC TẠO BỘ DỮ LIỆU (CHỦ ĐỀ & ẢNH BÌA)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .tracking(0.5)
                            }
                            
                            Picker("Bộ dữ liệu", selection: $listeningImportTopicMode) {
                                Text("Tạo bộ mới (+)").tag("new")
                                Text("Chọn bộ có sẵn").tag("existing")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 320)
                            
                            if listeningImportTopicMode == "existing" {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Bộ dữ liệu đích")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AdminTheme.textSecondary)
                                        Text("Chọn chủ đề để thêm câu nghe chép vào")
                                            .font(.system(size: 12))
                                            .foregroundColor(AdminTheme.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    Picker("Chủ đề", selection: $listeningImportSelectedTopicId) {
                                        ForEach(viewModel.listeningTopics) { t in
                                            Text(t.name).tag(t.id)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding(14)
                                .background(AdminTheme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                .cornerRadius(8)
                            } else {
                                // Form tạo bộ mới kèm ảnh bìa
                                VStack(alignment: .leading, spacing: 14) {
                                    // Ô 1: Tên bộ dữ liệu mới
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 4) {
                                            Text("TÊN BỘ BÀI NGHE MỚI")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AdminTheme.textPrimary)
                                            Text("*")
                                                .foregroundColor(AdminTheme.danger)
                                        }
                                        
                                        TextField("Nhập tên bộ bài nghe (ví dụ: Luyện nghe Sân bay & Du lịch...)", text: $listeningImportNewTopicName)
                                            .font(.system(size: 13))
                                            .foregroundColor(AdminTheme.textPrimary)
                                            .padding(10)
                                            .background(AdminTheme.surfaceHover)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Ô 2: Mô tả bộ dữ liệu
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("MÔ TẢ BỘ BÀI NGHE (TÙY CHỌN)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AdminTheme.textSecondary)
                                        
                                        TextField("Mô tả ngắn (ví dụ: Luyện nghe và chép chính tả các câu giao tiếp thông dụng)", text: $listeningImportNewTopicDesc)
                                            .font(.system(size: 13))
                                            .foregroundColor(AdminTheme.textPrimary)
                                            .padding(10)
                                            .background(AdminTheme.surfaceHover)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Ô 3: Ảnh bìa bộ bài nghe
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "photo.fill")
                                                .foregroundColor(AdminTheme.primary)
                                            Text("ẢNH BÌA BỘ BÀI NGHE (URL / CLOUDINARY / ICON)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AdminTheme.textPrimary)
                                        }
                                        
                                        HStack(alignment: .center, spacing: 12) {
                                            // Thumbnail Preview Box
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(AdminTheme.surface)
                                                    .frame(width: 54, height: 54)
                                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                                
                                                if (listeningImportNewTopicImage.hasPrefix("http://") || listeningImportNewTopicImage.hasPrefix("https://")), let url = URL(string: listeningImportNewTopicImage) {
                                                    AsyncImage(url: url) { phase in
                                                        switch phase {
                                                        case .success(let img):
                                                            img.resizable().scaledToFill().frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 8))
                                                        default:
                                                            ProgressView().scaleEffect(0.6)
                                                        }
                                                    }
                                                } else {
                                                    Image(systemName: listeningImportNewTopicImage.isEmpty ? "headphones" : listeningImportNewTopicImage)
                                                        .font(.system(size: 22))
                                                        .foregroundColor(AdminTheme.primary)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                CloudinaryMediaPickerView(
                                                    title: "Chọn từ Cloudinary hoặc nhập link ảnh bìa",
                                                    urlString: $listeningImportNewTopicImage,
                                                    pickerType: .image
                                                )
                                                
                                                // Quick SF Symbol presets
                                                HStack(spacing: 6) {
                                                    Text("Hoặc icon nhanh:")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(AdminTheme.textMuted)
                                                    
                                                    ForEach(["headphones", "speaker.wave.3.fill", "waveform", "mic.fill", "music.note", "book.closed.fill", "globe", "airplane"], id: \.self) { sym in
                                                        Button(action: {
                                                            listeningImportNewTopicImage = sym
                                                        }) {
                                                            Image(systemName: sym)
                                                                .font(.system(size: 10))
                                                                .foregroundColor(listeningImportNewTopicImage == sym ? .white : AdminTheme.primary)
                                                                .frame(width: 22, height: 22)
                                                                .background(listeningImportNewTopicImage == sym ? AdminTheme.primary : AdminTheme.surface)
                                                                .cornerRadius(4)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                                .background(AdminTheme.surfaceHover.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(18)
                        .background(AdminTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(12)
                        
                        // MARK: - Section 2: Nhập Dữ Liệu
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "headphones")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AdminTheme.primary)
                                    Text("2. DỮ LIỆU CÂU NGHE & CHÉP")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AdminTheme.textPrimary)
                                        .tracking(0.5)
                                }
                                
                                Spacer()
                                
                                Picker("Format", selection: $isListeningImportJSON) {
                                    Text("CSV").tag(false)
                                    Text("JSON").tag(true)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 140)
                            }
                            
                            Text(isListeningImportJSON
                                 ? "Hỗ trợ cả JSON Trọn bộ (gồm topicName, topicImage, sentences) hoặc mảng câu [{\"sentence\": \"...\", \"translation\": \"...\", \"level\": \"Beginner\", \"hint\": \"...\", \"audioUrl\": \"https://...\"}]."
                                 : "CSV Format: sentence,translation,level,hint,audioUrl")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AdminTheme.textSecondary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AdminTheme.surfaceHover)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                .cornerRadius(6)
                            
                            // Sample Template Action Buttons
                            HStack(spacing: 8) {
                                Button(action: {
                                    isListeningImportJSON = true
                                    loadFullPackageSample()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                        Text("Mẫu Trọn Bộ Bài Nghe (Kèm Ảnh Bìa)")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AdminTheme.primary)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    isListeningImportJSON = true
                                    loadSentencesOnlySample()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 11))
                                        Text("Mẫu Chỉ Danh Sách Câu")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AdminTheme.surfaceHover)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    isListeningImportJSON = false
                                    loadCSVSample()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "tablecells")
                                            .font(.system(size: 11))
                                        Text("Mẫu CSV")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(AdminTheme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AdminTheme.surfaceHover)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NỘI DUNG DỮ LIỆU DÁN VÀO:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AdminTheme.textSecondary)
                                
                                TextEditor(text: $listeningImportText)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(AdminTheme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .background(AdminTheme.surfaceHover)
                                    .frame(minHeight: 180)
                                    .padding(10)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AdminTheme.border, lineWidth: 1))
                                    .cornerRadius(8)
                                    .onChange(of: listeningImportText) { newValue in
                                        autoDetectPackageMetadata(from: newValue)
                                    }
                            }
                        }
                        .padding(18)
                        .background(AdminTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdminTheme.border, lineWidth: 1))
                        .cornerRadius(12)
                        
                        // MARK: - Section 3: Live Preview & Validation
                        if !listeningImportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AdminTheme.primary)
                                        Text("3. KẾT QUẢ KIỂM TRA (PREVIEW)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AdminTheme.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Status Badges
                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Circle().fill(AdminTheme.success).frame(width: 8, height: 8)
                                            Text("\(validItemsCount) Hợp lệ")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AdminTheme.success)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AdminTheme.successBg)
                                        .cornerRadius(6)
                                        
                                        if invalidItemsCount > 0 {
                                            HStack(spacing: 4) {
                                                Circle().fill(AdminTheme.danger).frame(width: 8, height: 8)
                                                Text("\(invalidItemsCount) Lỗi")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(AdminTheme.danger)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AdminTheme.dangerBg)
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                                
                                // Sample parsed exercises list
                                VStack(spacing: 8) {
                                    ForEach(parsedItems.prefix(3)) { item in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: item.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                                .foregroundColor(item.isValid ? AdminTheme.success : AdminTheme.danger)
                                                .font(.system(size: 14))
                                                .padding(.top, 2)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.sentence)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(AdminTheme.textPrimary)
                                                    .lineLimit(1)
                                                
                                                if item.isValid {
                                                    HStack(spacing: 6) {
                                                        Text(item.translation)
                                                            .font(.system(size: 11))
                                                            .foregroundColor(AdminTheme.textSecondary)
                                                            .lineLimit(1)
                                                        
                                                        if let hint = item.hint, !hint.isEmpty {
                                                            Text("•")
                                                                .foregroundColor(AdminTheme.textMuted)
                                                            Text("Gợi ý: \(hint)")
                                                                .font(.system(size: 10, weight: .medium))
                                                                .foregroundColor(AdminTheme.warning)
                                                        }
                                                        
                                                        if let audio = item.audioUrl, !audio.isEmpty {
                                                            Text("•")
                                                                .foregroundColor(AdminTheme.textMuted)
                                                            HStack(spacing: 2) {
                                                                Image(systemName: "waveform")
                                                                    .font(.system(size: 9))
                                                                Text("Audio")
                                                                    .font(.system(size: 9, weight: .bold))
                                                            }
                                                            .foregroundColor(AdminTheme.accentBlue)
                                                        }
                                                        
                                                        Text("•")
                                                            .foregroundColor(AdminTheme.textMuted)
                                                        
                                                        Text(item.level)
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(AdminTheme.accentBlue)
                                                    }
                                                } else if let reason = item.errorReason {
                                                    Text("Lỗi: \(reason)")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(AdminTheme.danger)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(item.isValid ? AdminTheme.surfaceHover : AdminTheme.dangerBg.opacity(0.4))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(item.isValid ? AdminTheme.border : AdminTheme.danger.opacity(0.3), lineWidth: 1))
                                        .cornerRadius(6)
                                    }
                                    
                                    if parsedItems.count > 3 {
                                        Text("... và còn \(parsedItems.count - 3) câu khác")
                                            .font(.system(size: 11))
                                            .foregroundColor(AdminTheme.textMuted)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                            .padding(18)
                            .background(AdminTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdminTheme.border, lineWidth: 1))
                            .cornerRadius(12)
                        }
                        
                        // MARK: - Action Buttons & Loading
                        HStack {
                            Button("Xóa trắng") {
                                listeningImportText = ""
                            }
                            .foregroundColor(AdminTheme.textSecondary)
                            .disabled(isImporting)
                            
                            Spacer()
                            
                            if isImporting {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Đang lưu vào Firestore...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AdminTheme.textSecondary)
                                }
                                .padding(.trailing, 8)
                            }
                            
                            Button("Đóng") {
                                isPresented = false
                            }
                            .foregroundColor(AdminTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .disabled(isImporting)
                            
                            Button(action: {
                                Task {
                                    await executeImport()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 12))
                                    Text("Import \(validItemsCount > 0 ? "(\(validItemsCount) câu)" : "")")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(isButtonDisabled ? AdminTheme.border : AdminTheme.primary)
                                .foregroundColor(isButtonDisabled ? AdminTheme.textMuted : .white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isButtonDisabled)
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Import Listening & Ảnh Bìa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { isPresented = false }
                        .disabled(isImporting)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 600)
    }
    
    private var isButtonDisabled: Bool {
        isImporting || validItemsCount == 0 || (listeningImportTopicMode == "new" && listeningImportNewTopicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // Auto-detect root JSON metadata (e.g. topicName, topicImage, topicDescription)
    private func autoDetectPackageMetadata(from text: String) {
        guard isListeningImportJSON else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return }
        
        if let package = try? JSONDecoder().decode(FullListeningTopicPackage.self, from: data) {
            if let name = package.topicName ?? package.name ?? package.title, !name.isEmpty {
                listeningImportNewTopicName = name
                listeningImportTopicMode = "new"
            }
            if let desc = package.topicDescription ?? package.description ?? package.desc, !desc.isEmpty {
                listeningImportNewTopicDesc = desc
            }
            if let img = package.topicImage ?? package.imageUrl ?? package.coverImage ?? package.image ?? package.icon, !img.isEmpty {
                listeningImportNewTopicImage = img
            }
        }
    }
    
    private func loadFullPackageSample() {
        listeningImportTopicMode = "new"
        listeningImportNewTopicName = "Luyện nghe Sân bay & Khách sạn"
        listeningImportNewTopicDesc = "Luyện nghe chính tả các câu hội thoại du lịch thực tế"
        listeningImportNewTopicImage = "https://res.cloudinary.com/dzmnki3sy/image/upload/v1788873266/tmbxh3wm3viajuoocnmp.jpg"
        
        listeningImportText = """
        {
          "topicName": "Luyện nghe Sân bay & Khách sạn",
          "topicDescription": "Luyện nghe chính tả các câu hội thoại du lịch thực tế",
          "topicImage": "https://res.cloudinary.com/dzmnki3sy/image/upload/v1788873266/tmbxh3wm3viajuoocnmp.jpg",
          "sentences": [
            {
              "sentence": "I will meet you at the airport.",
              "translation": "Tôi sẽ đón bạn tại sân bay.",
              "level": "Beginner",
              "hint": "airport",
              "audioUrl": ""
            },
            {
              "sentence": "Please keep your passport in a safe place.",
              "translation": "Vui lòng giữ hộ chiếu của bạn ở nơi an toàn.",
              "level": "Beginner",
              "hint": "passport",
              "audioUrl": ""
            }
          ]
        }
        """
    }
    
    private func loadSentencesOnlySample() {
        listeningImportText = """
        [
          {
            "sentence": "Where is the baggage claim area?",
            "translation": "Khu vực nhận hành lý ở đâu?",
            "level": "Intermediate",
            "hint": "baggage",
            "audioUrl": ""
          }
        ]
        """
    }
    
    private func loadCSVSample() {
        listeningImportText = "sentence,translation,level,hint,audioUrl\nI will meet you at the airport.,Tôi sẽ đón bạn tại sân bay.,Beginner,airport,\nPlease keep your passport in a safe place.,Vui lòng giữ hộ chiếu của bạn ở nơi an toàn.,Beginner,passport,"
    }
    
    private func executeImport() async {
        isImporting = true
        
        let resolvedTopicId = await resolveListeningTopicId(
            topicMode: listeningImportTopicMode,
            selectedTopicId: listeningImportSelectedTopicId,
            newTopicName: listeningImportNewTopicName,
            newTopicDesc: listeningImportNewTopicDesc,
            newTopicImage: (listeningImportTopicMode == "new") ? listeningImportNewTopicImage : nil,
            viewModel: viewModel
        )
        
        let validParsed = parsedItems.filter { $0.isValid }
        guard !validParsed.isEmpty else {
            isImporting = false
            return
        }
        
        var exercisesToSave: [ListeningExercise] = []
        for item in validParsed {
            let exerciseId = "listen_\(UUID().uuidString.prefix(8).lowercased())"
            let ex = ListeningExercise(
                id: exerciseId,
                sentence: item.sentence,
                translation: item.translation,
                topicId: resolvedTopicId,
                level: item.level,
                audioUrl: item.audioUrl,
                hint: item.hint
            )
            exercisesToSave.append(ex)
        }
        
        // Batch write directly to Firestore
        await viewModel.saveListeningExercisesBatch(exercises: exercisesToSave, topicId: resolvedTopicId)
        
        // Reload all data to synchronize Admin state
        await viewModel.loadAllData()
        
        // Focus the UI filter on the imported Topic
        viewModel.selectedListeningTopicFilter = resolvedTopicId
        
        isImporting = false
        isPresented = false
    }
}

