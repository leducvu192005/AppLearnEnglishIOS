//
//  ListeningFormSheet.swift
//  AppLearnEnglish
//

import SwiftUI

struct ListeningFormSheet: View {
    @ObservedObject var viewModel: AdminViewModel
    let editingListening: ListeningExercise?
    let defaultTopicId: String?
    @Binding var isPresented: Bool
    
    @State private var listeningSentence = ""
    @State private var listeningTranslation = ""
    @State private var listeningTopicId = "travel"
    @State private var listeningLevel = "Beginner"
    @State private var listeningHint = ""
    @State private var listeningAudioUrl = ""
    
    init(viewModel: AdminViewModel, editingListening: ListeningExercise?, defaultTopicId: String? = nil, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.editingListening = editingListening
        self.defaultTopicId = defaultTopicId
        self._isPresented = isPresented
        
        _listeningSentence = State(initialValue: editingListening?.sentence ?? "")
        _listeningTranslation = State(initialValue: editingListening?.translation ?? "")
        _listeningTopicId = State(initialValue: editingListening?.topicId ?? (defaultTopicId ?? viewModel.listeningTopics.first?.id ?? "travel"))
        _listeningLevel = State(initialValue: editingListening?.level ?? "Beginner")
        _listeningHint = State(initialValue: editingListening?.hint ?? "")
        _listeningAudioUrl = State(initialValue: editingListening?.audioUrl ?? "")
    }
    
    var body: some View {
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
                        ForEach(viewModel.listeningTopics) { topic in
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
                    
                    CloudinaryMediaPickerView(
                        title: "Custom Audio File / URL (Cloudinary)",
                        urlString: $listeningAudioUrl,
                        pickerType: .audio
                    )
                }
            }
            .navigationTitle(editingListening == nil ? "Thêm bài nghe" : "Sửa bài nghe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { isPresented = false }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingListening == nil ? "Thêm câu nghe" : "Lưu thay đổi") {
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
                            isPresented = false
                        }
                    }
                    .disabled(listeningSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || listeningTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 460)
    }
}
