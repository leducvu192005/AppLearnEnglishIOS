//
//  ProgressViewModel.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore
import Combine

class ProgressViewModel: ObservableObject {
    @Published var progress: ProgressModel = .defaultValue
    @Published var studyHistoryDates: [Date] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init() {
        self.isLoading = true
        // Observe SessionManager's currentUserModel to keep progress in sync in real-time
        SessionManager.shared.$currentUserModel
            .sink { [weak self] userOpt in
                guard let self = self else { return }
                if let currentUser = userOpt {
                    let calculatedLevel = max(1, (currentUser.xp / 100) + 1)
                    
                    self.progress = ProgressModel(
                        totalWords: currentUser.streak * 4, // Simulated words count
                        xp: currentUser.xp,
                        level: calculatedLevel,
                        streak: currentUser.streak,
                        dailyGoal: currentUser.dailyGoal,
                        lastStudyDate: Date()
                    )
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
            
        self.generateMockStudyHistory()
    }
    
    // Helper to generate active days for calendar widget
    private func generateMockStudyHistory() {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        // Add random dates in the last 7 days representing study sessions
        for dayOffset in 0..<7 {
            if dayOffset != 2 && dayOffset != 5 { // Mock study on these days
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    dates.append(date)
                }
            }
        }
        self.studyHistoryDates = dates
    }
}
