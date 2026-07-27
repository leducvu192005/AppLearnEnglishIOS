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
    
    private let db = Firestore.firestore()
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Initializer
    init() {
        Task {
            await loadProgress()
        }
    }
    
    // MARK: - Load Progress (Firestore with Fallback & Level Up Calc)
    @MainActor
    func loadProgress() async {
        guard let uid = userId else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let docRef = db.collection("users").document(uid).collection("progress").document("main")
            let document = try await docRef.getDocument()
            
            // Generate some mock study dates for calendar visual representation
            self.generateMockStudyHistory()
            
            if document.exists, let loadedProgress = try? document.data(as: ProgressModel.self) {
                self.progress = loadedProgress
            } else {
                // Fallback: build progress from the main user model attributes
                if let currentUser = SessionManager.shared.currentUserModel {
                    let calculatedLevel = max(1, (currentUser.xp / 100) + 1) // 100 XP per level
                    
                    let fallbackProgress = ProgressModel(
                        totalWords: currentUser.streak * 4, // Simulated words count
                        xp: currentUser.xp,
                        level: calculatedLevel,
                        streak: currentUser.streak,
                        dailyGoal: currentUser.dailyGoal,
                        lastStudyDate: Date()
                    )
                    
                    self.progress = fallbackProgress
                    
                    // Save to firestore progress subcollection so it exists next time
                    try? docRef.setData(from: fallbackProgress)
                }
            }
            self.isLoading = false
        } catch {
            print("Failed loading progress from Firestore: \(error.localizedDescription)")
            self.isLoading = false
        }
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
