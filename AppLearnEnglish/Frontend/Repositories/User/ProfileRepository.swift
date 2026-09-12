//
//  ProfileRepository.swift
//  AppLearnEnglish
//

import Foundation

protocol ProfileRepositoryProtocol {
    func updateProfile(uid: String, name: String, avatar: String) async throws
}

final class ProfileRepository: ProfileRepositoryProtocol {
    private let firestoreService: FirestoreService
    
    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }
    
    func updateProfile(uid: String, name: String, avatar: String) async throws {
        // Update both name and avatar in Firestore using the unified FirestoreService
        try await firestoreService.updateUserProfile(uid: uid, name: name, avatar: avatar)
        
        // Reload user session details
        await SessionManager.shared.reloadUserProfile()
    }
}
