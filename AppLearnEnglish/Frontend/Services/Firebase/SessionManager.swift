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
    @Published var isPreviewingAsStudent: Bool = false
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
                    self.isPreviewingAsStudent = false
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
                    
                    if !userModel.isAccountActive && userModel.role != "admin" {
                        await MainActor.run {
                            self.currentUserModel = nil
                            self.isLoggedIn = false
                            self.userRole = nil
                            self.isLoading = false
                            self.errorMessage = "Tài khoản của bạn đã bị tạm dừng hoạt động. Vui lòng liên hệ ban quản trị để được hỗ trợ."
                        }
                        try? Auth.auth().signOut()
                        return
                    }
                    
                    await MainActor.run {
                        self.currentUserModel = userModel
                        self.isLoggedIn = true
                        self.userRole = userModel.role
                        self.isLoading = false
                    }
                    
                    // Sync FCM Token to Firestore
                    FCMService.shared.syncCurrentTokenToFirestore()
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
                    
                    // Sync FCM Token to Firestore
                    FCMService.shared.syncCurrentTokenToFirestore()
                }
            }
        }
    }
    
    // MARK: - Reload User Profile on demand
    @MainActor
    func reloadUserProfile() async {
        guard let uid = currentUserModel?.uid else { return }
        do {
            let userModel = try await self.userService.fetchUser(uid: uid)
            if !userModel.isAccountActive && userModel.role != "admin" {
                self.currentUserModel = nil
                self.isLoggedIn = false
                self.userRole = nil
                self.errorMessage = "Tài khoản của bạn đã bị tạm dừng hoạt động. Vui lòng liên hệ ban quản trị để được hỗ trợ."
                try? Auth.auth().signOut()
                return
            }
            self.currentUserModel = userModel
            self.isLoggedIn = true
            self.userRole = userModel.role
            print("Successfully reloaded user profile details. XP: \(userModel.xp)")
        } catch {
            print("Failed to reload user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        self.isPreviewingAsStudent = false
        do {
            try Auth.auth().signOut()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
