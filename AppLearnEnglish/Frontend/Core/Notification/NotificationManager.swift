//
//  NotificationManager.swift
//  AppLearnEnglish
//

import Foundation
import Combine
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    private init() {
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
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Đã xoá toàn bộ lịch nhắc nhở thông báo.")
    }
}
