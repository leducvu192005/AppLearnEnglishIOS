//
//  NotificationSettingView.swift
//  AppLearnEnglish
//

import SwiftUI

struct NotificationSettingView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var enableReminder: Bool = true
    @State private var reminderTime: Date = Date()
    @State private var enableWordOfDay: Bool = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Nhắc nhở học tập")) {
                Toggle(isOn: $enableReminder) {
                    HStack {
                        Text("🔔 Nhắc nhở hàng ngày")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                    }
                }
                .onChange(of: enableReminder) { _, isEnabled in
                    if isEnabled {
                        requestNotificationAccess()
                    } else {
                        notificationManager.cancelAllNotifications()
                    }
                }
                
                if enableReminder {
                    DatePicker(
                        "Chọn thời gian nhắc",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: reminderTime) { _, newTime in
                        scheduleDailyAlert(newTime)
                    }
                }
            }
            
            Section(header: Text("Tính năng bổ sung")) {
                Toggle("💡 Từ vựng mỗi sáng (8:00)", isOn: $enableWordOfDay)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .onChange(of: enableWordOfDay) { _, isEnabled in
                        if isEnabled {
                            notificationManager.scheduleWordOfDayReminder()
                        } else {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["word_of_the_day"])
                        }
                    }
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Cài đặt thông báo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.checkAuthorizationStatus()
            // Default load times from user preferences if saved, or just use current
            if !notificationManager.isAuthorized {
                enableReminder = false
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thông báo"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã hiểu"))
            )
        }
    }
    
    private func requestNotificationAccess() {
        Task {
            let granted = await notificationManager.requestPermission()
            await MainActor.run {
                if granted {
                    scheduleDailyAlert(reminderTime)
                    if enableWordOfDay {
                        notificationManager.scheduleWordOfDayReminder()
                    }
                } else {
                    enableReminder = false
                    alertMessage = "Vui lòng cho phép quyền thông báo trong Cài đặt iPhone để sử dụng chức năng này."
                    showAlert = true
                }
            }
        }
    }
    
    private func scheduleDailyAlert(_ time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        notificationManager.scheduleDailyReminder(at: hour, minute: minute)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingView()
    }
}
