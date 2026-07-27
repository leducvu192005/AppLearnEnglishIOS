//
//  ProfileView.swift
//  AppLearnEnglish
//

import SwiftUI

struct ProfileViewModule: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isDarkMode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Profile Avatar Panel
                VStack(spacing: 12) {
                    Text(sessionManager.currentUserModel?.name.contains("Admin") ?? false ? "🦁" : "🦉")
                        .font(.system(size: 80))
                        .padding(16)
                        .background(AppTheme.primaryMint.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(sessionManager.currentUserModel?.name ?? "Học viên")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text(sessionManager.currentUserModel?.email ?? "")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.top, 24)
                
                // Stats Card Grid
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("🏅")
                            .font(.system(size: 20))
                        Text("\(max(1, ((sessionManager.currentUserModel?.xp ?? 0) / 100) + 1))")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        Text("Cấp độ")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cuteCardStyle()
                    
                    VStack(spacing: 4) {
                        Text("⚡️")
                            .font(.system(size: 20))
                        Text("\(sessionManager.currentUserModel?.xp ?? 0) XP")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.pastelSky)
                        Text("Kinh nghiệm")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cuteCardStyle()
                    
                    VStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 20))
                        Text("\(sessionManager.currentUserModel?.streak ?? 0) ngày")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.primaryCoral)
                        Text("Chuỗi học")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .cuteCardStyle()
                }
                .padding(.horizontal)
                
                // Settings Section List
                VStack(spacing: 14) {
                    // Item 1: Edit Profile
                    NavigationLink(destination: EditProfileView()) {
                        ProfileSettingRow(icon: "pencil", color: AppTheme.primaryMint, title: "Chỉnh sửa hồ sơ")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 2: Progress Dashboard
                    NavigationLink(destination: ProgressViewModule()) {
                        ProfileSettingRow(icon: "chart.bar.xaxis", color: AppTheme.pastelSky, title: "Tiến độ học tập")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 3: Notification settings
                    NavigationLink(destination: NotificationSettingView()) {
                        ProfileSettingRow(icon: "bell.fill", color: AppTheme.pastelYellow, title: "Cài đặt nhắc nhở")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 4: Dark Mode switch
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.pastelLavender.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "moon.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.pastelLavender)
                        }
                        
                        Text("Chế độ tối (Dark Mode)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                            .tint(AppTheme.primaryMint)
                    }
                    .padding(14)
                    .cuteCardStyle()
                    
                    // Item 5: Log out Button
                    Button(action: { sessionManager.signOut() }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.primaryCoral.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "power")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.primaryCoral)
                            }
                            
                            Text("Đăng xuất")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryCoral)
                            
                            Spacer()
                        }
                        .padding(14)
                        .cuteCardStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Hồ sơ học viên")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileSettingRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textDark)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textLight)
        }
        .padding(14)
        .cuteCardStyle()
    }
}

#Preview {
    NavigationStack {
        ProfileViewModule()
            .environmentObject(SessionManager.shared)
    }
}
