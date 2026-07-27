//
//  ProfileViewModel.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore
import Combine

class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var selectedAvatar: String = "🦉"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveSuccess: Bool = false
    
    // Beautiful avatar presets
    let avatarPresets = ["🦉", "🦁", "🐼", "🐨", "🦊", "🐻", "🐸", "🐱", "🐰"]
    
    private let db = Firestore.firestore()
    private var userId: String? {
        SessionManager.shared.currentUserModel?.uid
    }
    
    // MARK: - Initializer
    init() {
        if let currentUser = SessionManager.shared.currentUserModel {
            self.name = currentUser.name
            // Fallback default avatar preset
            self.selectedAvatar = currentUser.name.contains("Admin") ? "🦁" : "🦉"
        }
    }
    
    // MARK: - Save Changes to Firestore
    @MainActor
    func saveProfileChanges() async {
        guard let uid = userId else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            self.errorMessage = "Tên không được để trống."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.saveSuccess = false
        
        do {
            try await db.collection("users").document(uid).updateData([
                "name": trimmedName
            ])
            
            // Reload user session details
            SessionManager.shared.listenToAuthChanges()
            self.saveSuccess = true
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
