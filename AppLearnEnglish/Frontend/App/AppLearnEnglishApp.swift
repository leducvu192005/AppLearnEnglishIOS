//
//  AppLearnEnglishApp.swift
//  AppLearnEnglish
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Firebase Cloud Messaging
        FCMService.shared.configure()
        
        // Request Local & Remote Notification Authorization
        NotificationManager.shared.requestAuthorization()
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Forward APNs device token to Firebase Messaging
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📱 [APNs] Đăng ký thành công APNs Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] Đăng ký Remote Notifications thất bại: \(error.localizedDescription)")
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
