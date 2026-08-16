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
            VStack(spacing: DesignSystem.Spacing.large) {
                
                // MARK: - 1. PROFILE AVATAR PANEL
                VStack(spacing: 12) {
                    // Profile Mascot Avatar
                    OwlMascot(state: .celebrating, size: 100)
                        .padding(.top, 12)
                    
                    Text(sessionManager.currentUserModel?.name ?? "Học viên")
                        .fontHeading()
                        .foregroundColor(DesignSystem.Colors.darkNavy)
                    
                    Text(sessionManager.currentUserModel?.email ?? "")
                        .fontBodySecondary()
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.top, 12)
                
                // MARK: - 2. STATS CARD GRID (3-Column Layout)
                HStack(spacing: 12) {
                    // Level
                    SoftCard(padding: 12) {
                        VStack(spacing: 4) {
                            Text("🏅")
                                .font(.system(size: 20))
                            Text(sessionManager.currentUserModel?.level ?? "Beginner")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                                .lineLimit(1)
                            Text("Trình độ")
                                .fontCaption()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Experience
                    SoftCard(padding: 12) {
                        VStack(spacing: 4) {
                            Text("⚡️")
                                .font(.system(size: 20))
                            Text("\(sessionManager.currentUserModel?.xp ?? 0) XP")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Kinh nghiệm")
                                .fontCaption()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Streak
                    SoftCard(padding: 12) {
                        VStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 20))
                            Text("\(sessionManager.currentUserModel?.streak ?? 0) ngày")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.accentPink)
                            Text("Chuỗi học")
                                .fontCaption()
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: - 3. SETTINGS ROW LIST
                VStack(spacing: 12) {
                    // Item 1: Edit Profile
                    NavigationLink(destination: EditProfileView()) {
                        ProfileSettingRow(icon: "pencil", color: DesignSystem.Colors.primary, title: "Chỉnh sửa hồ sơ")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 2: Progress Dashboard
                    NavigationLink(destination: ProgressViewModule()) {
                        ProfileSettingRow(icon: "chart.bar.xaxis", color: DesignSystem.Colors.primary, title: "Tiến độ học tập")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 3: Notification settings
                    NavigationLink(destination: NotificationSettingView()) {
                        ProfileSettingRow(icon: "bell.fill", color: DesignSystem.Colors.warning, title: "Cài đặt nhắc nhở")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Item 4: Dark Mode switch
                    SoftCard(padding: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DesignSystem.Colors.primaryLight)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            Text("Chế độ tối (Dark Mode)")
                                .fontBody()
                                .foregroundColor(DesignSystem.Colors.darkNavy)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isDarkMode)
                                .labelsHidden()
                                .tint(DesignSystem.Colors.primary)
                        }
                    }
                    
                    // Item 5: Log out Button
                    Button(action: { sessionManager.signOut() }) {
                        SoftCard(padding: 14) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.accentPink.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "power")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(DesignSystem.Colors.accentPink)
                                }
                                
                                Text("Đăng xuất")
                                    .fontBody()
                                    .foregroundColor(DesignSystem.Colors.accentPink)
                                
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Hồ sơ học viên")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileSettingRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        SoftCard(padding: 14) {
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
                    .fontBody()
                    .foregroundColor(DesignSystem.Colors.darkNavy)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileViewModule()
            .environmentObject(SessionManager.shared)
    }
}
