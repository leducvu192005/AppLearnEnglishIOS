//
//  AuthService.swift
//  AppLearnEnglish
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    static let shared = AuthService()
    
    private init() {
        listenToAuthState()
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Listen to Authentication State changes
    func listenToAuthState() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - Sign In with Email & Password
    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Register with Email, Password and Name
    func signUp(email: String, password: String, name: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Create user in Auth
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            
            // Set display name in Auth profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Save user profile information in Firestore
            let userData: [String: Any] = [
                "uid": user.uid,
                "name": name,
                "email": email,
                "role": "user",
                "streak": 0,
                "level": "Beginner",
                "xp": 0,
                "dailyGoal": 20,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData)
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
