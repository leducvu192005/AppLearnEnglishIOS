//
//  AdminComponents.swift
//  AppLearnEnglish
//

import SwiftUI
import AVFoundation

// MARK: - Pronunciation Speech Helper
class AdminSpeechHelper {
    static let shared = AdminSpeechHelper()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
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

// MARK: - Skeleton Loading View
struct AdminTableSkeletonView: View {
    var body: some View {
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
}

// MARK: - Error View
struct AdminErrorView: View {
    let errorMsg: String
    let onRetry: () -> Void
    
    var body: some View {
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
                onRetry()
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
}

// MARK: - Helper to parse a single CSV line with smart delimiter detection and quote escaping support
func parseAdminCSVRow(_ row: String) -> [String] {
    let trimmedRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedRow.isEmpty else { return [] }
    
    // Auto-detect delimiter: comma, semicolon, or tab
    var commaCount = 0
    var semicolonCount = 0
    var tabCount = 0
    var inQuotesScan = false
    
    for char in trimmedRow {
        if char == "\"" {
            inQuotesScan.toggle()
        } else if !inQuotesScan {
            if char == "," { commaCount += 1 }
            else if char == ";" { semicolonCount += 1 }
            else if char == "\t" { tabCount += 1 }
        }
    }
    
    let delimiter: Character
    if tabCount > 0 && tabCount >= commaCount && tabCount >= semicolonCount {
        delimiter = "\t"
    } else if semicolonCount > 0 && semicolonCount >= commaCount {
        delimiter = ";"
    } else {
        delimiter = ","
    }
    
    var results: [String] = []
    var current = ""
    var insideQuotes = false
    let chars = Array(trimmedRow)
    var i = 0
    
    while i < chars.count {
        let char = chars[i]
        
        if char == "\"" {
            if insideQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                // Escaped quote: "" -> "
                current.append("\"")
                i += 1
            } else {
                insideQuotes.toggle()
            }
        } else if char == delimiter && !insideQuotes {
            var val = current.trimmingCharacters(in: .whitespaces)
            if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
                val = String(val.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            }
            results.append(val)
            current = ""
        } else {
            current.append(char)
        }
        i += 1
    }
    
    var val = current.trimmingCharacters(in: .whitespaces)
    if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
        val = String(val.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
    }
    results.append(val)
    
    return results
}

// MARK: - Helper to resolve or auto-create Quiz Topic (/quizzes)
func resolveQuizTopicId(
    topicMode: String,
    selectedTopicId: String,
    newTopicName: String,
    newTopicDesc: String,
    newTopicImage: String? = nil,
    viewModel: AdminViewModel
) async -> String {
    if topicMode == "existing" && !selectedTopicId.isEmpty {
        if let customImg = newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines), !customImg.isEmpty {
            if let existing = viewModel.quizTopics.first(where: { $0.id == selectedTopicId }) {
                await viewModel.saveQuizTopic(id: existing.id, name: existing.name, description: existing.description, image: customImg)
            }
        }
        return selectedTopicId
    }
    
    let trimmedName = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
        return selectedTopicId.isEmpty ? (viewModel.quizTopics.first?.id ?? "general") : selectedTopicId
    }
    
    var slug = trimmedName.lowercased()
        .folding(options: .diacriticInsensitive, locale: .current)
        .replacingOccurrences(of: "đ", with: "d")
        .replacingOccurrences(of: "Đ", with: "d")
        .replacingOccurrences(of: " ", with: "_")
        .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    
    if slug.isEmpty {
        slug = "quiz_\(Int(Date().timeIntervalSince1970))"
    }
    
    let img = (newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? newTopicImage!.trimmingCharacters(in: .whitespacesAndNewlines)
        : "questionmark.folder.fill"
    
    if !viewModel.quizTopics.contains(where: { $0.id == slug }) {
        let desc = newTopicDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Bộ câu hỏi \(trimmedName)"
            : newTopicDesc
        await viewModel.saveQuizTopic(id: slug, name: trimmedName, description: desc, image: img)
    } else if let customImg = newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines), !customImg.isEmpty {
        if let existing = viewModel.quizTopics.first(where: { $0.id == slug }) {
            await viewModel.saveQuizTopic(id: slug, name: existing.name, description: existing.description, image: customImg)
        }
    }
    
    return slug
}

// MARK: - Helper to resolve or auto-create Listening Topic (/listening_exercises)
func resolveListeningTopicId(
    topicMode: String,
    selectedTopicId: String,
    newTopicName: String,
    newTopicDesc: String,
    newTopicImage: String? = nil,
    viewModel: AdminViewModel
) async -> String {
    if topicMode == "existing" && !selectedTopicId.isEmpty {
        if let customImg = newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines), !customImg.isEmpty {
            if let existing = viewModel.listeningTopics.first(where: { $0.id == selectedTopicId }) {
                await viewModel.saveListeningTopic(id: existing.id, name: existing.name, description: existing.description, image: customImg)
            }
        }
        return selectedTopicId
    }
    
    let trimmedName = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
        return selectedTopicId.isEmpty ? (viewModel.listeningTopics.first?.id ?? "general") : selectedTopicId
    }
    
    var slug = trimmedName.lowercased()
        .folding(options: .diacriticInsensitive, locale: .current)
        .replacingOccurrences(of: "đ", with: "d")
        .replacingOccurrences(of: "Đ", with: "d")
        .replacingOccurrences(of: " ", with: "_")
        .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    
    if slug.isEmpty {
        slug = "listening_\(Int(Date().timeIntervalSince1970))"
    }
    
    let img = (newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? newTopicImage!.trimmingCharacters(in: .whitespacesAndNewlines)
        : "headphones"
    
    if !viewModel.listeningTopics.contains(where: { $0.id == slug }) {
        let desc = newTopicDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Bộ bài nghe \(trimmedName)"
            : newTopicDesc
        await viewModel.saveListeningTopic(id: slug, name: trimmedName, description: desc, image: img)
    } else if let customImg = newTopicImage?.trimmingCharacters(in: .whitespacesAndNewlines), !customImg.isEmpty {
        if let existing = viewModel.listeningTopics.first(where: { $0.id == slug }) {
            await viewModel.saveListeningTopic(id: slug, name: existing.name, description: existing.description, image: customImg)
        }
    }
    
    return slug
}

