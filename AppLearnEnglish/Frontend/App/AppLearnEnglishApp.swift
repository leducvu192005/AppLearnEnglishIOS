//
//  AppLearnEnglishApp.swift
//  AppLearnEnglish
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Request Local Notification Authorization
        NotificationManager.shared.requestAuthorization()
        
        return true
    }
}

@main
struct AppLearnEnglishApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(SessionManager.shared)
                .environmentObject(AuthService.shared)
        }
    }
}
