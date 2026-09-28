//
//  AdminHomeView.swift
//  AppLearnEnglish
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = AdminViewModel()
    
    // Selected Sidebar Tab
    // 0: Dashboard, 1: Topics & Vocabulary, 2: Quizzes, 3: Listening, 4: Students, 5: Settings, 6: Activity Log
    @State private var selectedTab: Int? = 0
    
    // Quick Action Sheets from Dashboard
    @State private var showingNewTopicSheet = false
    @State private var showingVocabularyImportSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR (macOS Catalyst Native SaaS Style)
            AdminSidebarView(selectedTab: $selectedTab)
            
            // 1pt clean divider
            Rectangle()
                .fill(AdminTheme.border)
                .frame(width: 1)
                .ignoresSafeArea()
            
            // DETAIL PANE (High-density SaaS Canvas)
            ZStack {
                AdminTheme.appBackground
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.words.isEmpty {
                    AdminTableSkeletonView()
                } else if let err = viewModel.errorMessage, viewModel.words.isEmpty {
                    AdminErrorView(errorMsg: err) {
                        Task { await viewModel.loadAllData() }
                    }
                } else {
                    switch selectedTab ?? 0 {
                    case 0:
                        AdminOverviewView(
                            viewModel: viewModel,
                            selectedTab: $selectedTab,
                            showingNewTopicSheet: $showingNewTopicSheet,
                            showingVocabularyImportSheet: $showingVocabularyImportSheet
                        )
                    case 1:
                        AdminTopicsView(viewModel: viewModel)
                    case 2:
                        AdminQuizzesView(viewModel: viewModel)
                    case 3:
                        AdminListeningView(viewModel: viewModel)
                    case 4:
                        AdminUsersView(viewModel: viewModel)
                    case 5:
                        AdminNotificationsView(viewModel: viewModel)
                    case 6:
                        AdminSettingsView(viewModel: viewModel)
                    default:
                        AdminOverviewView(
                            viewModel: viewModel,
                            selectedTab: $selectedTab,
                            showingNewTopicSheet: $showingNewTopicSheet,
                            showingVocabularyImportSheet: $showingVocabularyImportSheet
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .background(AdminTheme.appBackground)
        .ignoresSafeArea()
        .task {
            await viewModel.loadAllData()
        }
        .sheet(isPresented: $showingNewTopicSheet) {
            WordFormSheet(
                viewModel: viewModel,
                defaultTopicId: "",
                editingWord: nil,
                isPresented: $showingNewTopicSheet
            )
        }
        .sheet(isPresented: $showingVocabularyImportSheet) {
            VocabularyImportSheet(
                viewModel: viewModel,
                topicId: "",
                isPresented: $showingVocabularyImportSheet
            )
        }
    }
}

#Preview {
    AdminHomeView()
        .environmentObject(SessionManager.shared)
}
