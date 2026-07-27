//
//  SessionManager.swift
//  AppLearnEnglish
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class SessionManager: ObservableObject {
    @Published var currentUserModel: UserModel? = nil
    @Published var isLoggedIn: Bool = false
    @Published var userRole: String? = nil
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil
    
    static let shared = SessionManager()
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let userService = UserService.shared
    
    private init() {
        listenToAuthChanges()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Monitor Authentication & Fetch User Profile from Firestore
    func listenToAuthChanges() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            guard let authenticatedUser = user else {
                // User logged out
                DispatchQueue.main.async {
                    self.currentUserModel = nil
                    self.isLoggedIn = false
                    self.userRole = nil
                    self.isLoading = false
                }
                return
            }
            
            // User logged in: fetch profile details
            Task {
                await MainActor.run {
                    self.isLoading = true
                    self.errorMessage = nil
                }
                
                do {
                    // Try fetching user from Firestore
                    let userModel = try await self.userService.fetchUser(uid: authenticatedUser.uid)
                    
                    await MainActor.run {
                        self.currentUserModel = userModel
                        self.isLoggedIn = true
                        self.userRole = userModel.role
                        self.isLoading = false
                    }
                } catch {
                    print("Error loading user profile: \(error.localizedDescription)")
                    
                    // Fallback to locally initialized model if Firestore profile is missing or offline
                    let fallbackModel = UserModel(
                        uid: authenticatedUser.uid,
                        name: authenticatedUser.displayName ?? "Học viên mới",
                        email: authenticatedUser.email ?? "",
                        role: "user",
                        streak: 0,
                        level: "Beginner",
                        xp: 0,
                        dailyGoal: 20,
                        createdAt: Date()
                    )
                    
                    await MainActor.run {
                        self.currentUserModel = fallbackModel
                        self.isLoggedIn = true
                        self.userRole = "user"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
