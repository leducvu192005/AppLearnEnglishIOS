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
    
    // MARK: - Schedule Morning Word Of The Day alert (Dynamic from Firebase words)
    func scheduleWordOfDayReminder(words: [VocabularyWord]? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["word_of_the_day"])
        
        let randomWord = words?.randomElement()
        let wordTitle = randomWord != nil ? "💡 Từ vựng hôm nay: \(randomWord!.word)" : "💡 Từ vựng hôm nay: Serendipity"
        let wordBody = randomWord != nil ? "[\(randomWord!.phonetic)] - Nghĩa: \(randomWord!.meaning). Mở app để luyện tập ngay!" : "Ý nghĩa: Sự tình cờ may mắn. Hãy mở app để xem cách sử dụng từ này!"
        
        let content = UNMutableNotificationContent()
        content.title = wordTitle
        content.body = wordBody
        content.sound = .default
        
        if let word = randomWord {
            content.userInfo = [
                "wordId": word.id,
                "word": word.word,
                "phonetic": word.phonetic,
                "meaning": word.meaning,
                "example": word.example,
                "topicId": word.topicId,
                "level": word.level
            ]
        }
        
        // Schedule for 8:00 AM every morning
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "word_of_the_day", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Spaced Repetition (SRS) Review for Learned Words
    /// Lên lịch ôn tập ngắt quãng: Sau 1 ngày (Day 1), sau 3 ngày (Day 3), và sau 1 tuần (Day 7)
    func scheduleSRSReview(for word: VocabularyWord, learnedDate: Date = Date()) {
        let isSRSEnabled = UserDefaults.standard.object(forKey: "AppLearnEnglish_EnableSRS") != nil
            ? UserDefaults.standard.bool(forKey: "AppLearnEnglish_EnableSRS")
            : true
        guard isSRSEnabled else { return }
        
        let calendar = Calendar.current
        
        // Cấu hình 3 giai đoạn: Day 1, Day 3, Day 7
        let stages: [(stage: Int, dayOffset: Int, title: String, body: String)] = [
            (
                stage: 1,
                dayOffset: 1,
                title: "🧠 Ôn tập từ vựng (Lần 1): \(word.word)",
                body: "Bạn còn nhớ nghĩa của \"\(word.word) [\(word.phonetic)]\" không? Hãy ôn lại ngay để củng cố trí nhớ!"
            ),
            (
                stage: 2,
                dayOffset: 3,
                title: "🔥 Ôn tập củng cố (Lần 2): \(word.word)",
                body: "Đã 3 ngày kể từ khi học \"\(word.word)\". Hãy ôn lại để đưa từ này vào trí nhớ dài hạn nhé!"
            ),
            (
                stage: 3,
                dayOffset: 7,
                title: "🏆 Hoàn thành ghi nhớ vĩnh viễn: \(word.word)",
                body: "Chúc mừng bạn! Ôn lại lần cuối từ \"\(word.word) [\(word.phonetic)]\" để làm chủ từ vựng này hoàn toàn."
            )
        ]
        
        for item in stages {
            guard let targetDate = calendar.date(byAdding: .day, value: item.dayOffset, to: learnedDate) else { continue }
            
            // Đặt giờ thông báo lúc 19:30 tối để người dùng thuận tiện ôn bài
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = 19
            components.minute = 30
            components.second = 0
            
            guard let triggerDate = calendar.date(from: components), triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            
            let payload: [String: Any] = [
                "wordId": word.id,
                "word": word.word,
                "phonetic": word.phonetic,
                "meaning": word.meaning,
                "example": word.example,
                "topicId": word.topicId,
                "level": word.level,
                "srsStage": item.stage,
                "isSRSReview": true
            ]
            content.userInfo = payload
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "SRSReview_\(word.id)_Stage\(item.stage)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [SRS] Lỗi lên lịch ôn tập cho \(word.word) (Stage \(item.stage)): \(error.localizedDescription)")
                } else {
                    print("✅ [SRS] Đã lên lịch ôn tập cho '\(word.word)' Stage \(item.stage) vào: \(triggerDate)")
                }
            }
        }
    }
    
    // MARK: - Cancel SRS Review for a word
    func cancelSRSReview(for wordId: String) {
        let identifiers = [
            "SRSReview_\(wordId)_Stage1",
            "SRSReview_\(wordId)_Stage2",
            "SRSReview_\(wordId)_Stage3"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ [SRS] Đã hủy lịch ôn tập cho wordId: \(wordId)")
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
        // 1. Handle Local Word or SRS Review payload
        if let wordId = userInfo["wordId"] as? String,
           let word = userInfo["word"] as? String,
           let phonetic = userInfo["phonetic"] as? String,
           let meaning = userInfo["meaning"] as? String {
            
            let isSRS = userInfo["isSRSReview"] as? Bool ?? false
            let stage = userInfo["srsStage"] as? Int ?? 1
            
            var wordDict: [String: Any] = [
                "id": wordId,
                "word": word,
                "phonetic": phonetic,
                "meaning": meaning,
                "example": userInfo["example"] as? String ?? "",
                "topicId": userInfo["topicId"] as? String ?? "custom",
                "level": userInfo["level"] as? String ?? "Beginner",
                "isSRSReview": isSRS,
                "srsStage": stage
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
