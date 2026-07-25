//
//  AppLearnEnglishApp.swift
//  AppLearnEnglish
//

import SwiftUI
import FirebaseCore

@main
struct AppLearnEnglishApp: App {
    // Initialize Firebase
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthService.shared)
        }
    }
}
