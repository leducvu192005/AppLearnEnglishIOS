//
//  NotificationManager.swift
//  AppLearnEnglish
//

import Foundation
import Combine
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Check Authorization
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Lỗi yêu cầu quyền thông báo: \(error.localizedDescription)")
            return false
        }
    }
    
    func requestAuthorization() {
        Task {
            _ = await requestPermission()
        }
    }
    
    // MARK: - Schedule Daily Study Reminder
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        // Cancel existing daily reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Giờ học Tiếng Anh đến rồi!"
        content.body = "Dành ra 5 phút mỗi ngày cùng AI chinh phục từ vựng mới nhé. Cố lên nào!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lỗi lên lịch nhắc nhở hàng ngày: \(error.localizedDescription)")
            } else {
                print("Đã lên lịch nhắc nhở hàng ngày thành công vào lúc \(hour):\(minute)")
            }
        }
    }
    
    // MARK: - Schedule Morning Word Of The Day alert
    func scheduleWordOfDayReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["word_of_the_day"])
        
        let content = UNMutableNotificationContent()
        content.title = "💡 Từ vựng hôm nay: Serendipity"
        content.body = "Ý nghĩa: Sự tình cờ may mắn. Hãy mở app để xem cách sử dụng từ này!"
        content.sound = .default
        
        // Schedule for 8:00 AM every morning
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "word_of_the_day", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Passive Learning Notifications (12 different Oxford words/day)
    func schedulePassiveLearningNotifications(words: [VocabularyWord]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Check current pending passive notifications
            let passiveRequests = requests.filter { $0.identifier.hasPrefix("PassiveLearning_") }
            
            // If we already have a healthy number of pending passive notifications (at least 24, which is 2 days),
            // we do NOT reschedule them to prevent resetting timers or repetition when opening the app.
            if passiveRequests.count >= 24 {
                print("Healthy amount of pending notifications (\(passiveRequests.count)). Skipping rescheduling.")
                return
            }
            
            // Clean up any old pending passive notifications to start fresh
            let identifiersToCancel = passiveRequests.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
            
            let notifiedIdsKey = "AppLearnEnglish_NotifiedWordIds"
            var notifiedIds = Set(UserDefaults.standard.stringArray(forKey: notifiedIdsKey) ?? [])
            
            // Filter words that haven't been notified yet
            var availableWords = words.filter { !notifiedIds.contains($0.id) }
            
            // If we run out of words, reset the cache to loop again
            if availableWords.isEmpty {
                notifiedIds.removeAll()
                availableWords = words
            }
            
            // We want to schedule for 5 days, 12 words per day. Total = 60 words.
            let targetWords = Array(availableWords.shuffled().prefix(60))
            if targetWords.isEmpty {
                return
            }
            
            let hours = [8, 9, 10, 11, 13, 14, 15, 16, 17, 19, 20, 21] // 12 designated study hours per day
            let calendar = Calendar.current
            let now = Date()
            
            var scheduledCount = 0
            var wordIndex = 0
            
            // Loop through the next 5 days (day 0 to day 4)
            for dayOffset in 0..<5 {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                
                for hour in hours {
                    guard wordIndex < targetWords.count else { break }
                    let word = targetWords[wordIndex]
                    
                    var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                    components.hour = hour
                    components.minute = 0
                    components.second = 0
                    
                    guard let triggerDate = calendar.date(from: components) else { continue }
                    
                    // Skip if the trigger date is in the past
                    if triggerDate <= now {
                        continue
                    }
                    
                    let content = UNMutableNotificationContent()
                    content.title = "Học từ vựng thụ động 🎧"
                    content.body = "\(word.word) [\(word.phonetic)] - Nghĩa: \(word.meaning)"
                    content.sound = .default
                    
                    // Pass word payload in userInfo to let user add it on tap
                    let payload: [String: Any] = [
                        "wordId": word.id,
                        "word": word.word,
                        "phonetic": word.phonetic,
                        "meaning": word.meaning,
                        "example": word.example,
                        "topicId": word.topicId,
                        "level": word.level
                    ]
                    content.userInfo = payload
                    
                    // Schedule with date matching components
                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                    
                    let request = UNNotificationRequest(
                        identifier: "PassiveLearning_\(word.id)",
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Failed to schedule notification for \(word.word): \(error.localizedDescription)")
                        }
                    }
                    
                    // Mark as notified/displayed to prevent duplicates
                    notifiedIds.insert(word.id)
                    wordIndex += 1
                    scheduledCount += 1
                }
            }
            
            UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedIdsKey)
            print("Successfully scheduled \(scheduledCount) passive notifications over the next 5 days.")
        }
    }
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Đã xoá toàn bộ lịch nhắc nhở thông báo.")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 [NotificationManager] Người dùng mở thông báo. Payload: \(userInfo)")
        
        // 1. Handle Local Word payload
        if let wordId = userInfo["wordId"] as? String,
           let word = userInfo["word"] as? String,
           let phonetic = userInfo["phonetic"] as? String,
           let meaning = userInfo["meaning"] as? String {
            
            let wordDict: [String: String] = [
                "id": wordId,
                "word": word,
                "phonetic": phonetic,
                "meaning": meaning,
                "example": userInfo["example"] as? String ?? "",
                "topicId": userInfo["topicId"] as? String ?? "custom",
                "level": userInfo["level"] as? String ?? "Beginner"
            ]
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddWordFromNotification"),
                    object: nil,
                    userInfo: ["word": wordDict]
                )
            }
        }
        
        // 2. Handle Remote FCM Deep Linking Payloads (screen, destination, topicId, etc.)
        if let targetScreen = (userInfo["screen"] as? String) ?? (userInfo["destination"] as? String) {
            print("🚀 [NotificationManager] Điều hướng tới màn hình: \(targetScreen)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("FCMNavigateToScreen"),
                    object: nil,
                    userInfo: ["screen": targetScreen, "data": userInfo]
                )
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("🔔 [NotificationManager] Nhận thông báo khi app đang ở foreground: \(userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
}
