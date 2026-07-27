//
//  AdminHomeView.swift
//  AppLearnEnglish
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Admin Header Panel
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("🛡️ Trực Ban Quản Trị")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryCoral)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.primaryCoral.opacity(0.15))
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: {
                                sessionManager.signOut()
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.forward")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(sessionManager.currentUserModel?.name ?? "Administrator")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                        
                        Text("Email: \(sessionManager.currentUserModel?.email ?? "")")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Admin Stats Panel
                    HStack(spacing: 16) {
                        AdminStatCard(title: "Bài Học", count: "128", icon: "book.fill", color: AppTheme.primaryMint)
                        AdminStatCard(title: "Quizzes", count: "48", icon: "checkmark.seal.fill", color: AppTheme.pastelSky)
                        AdminStatCard(title: "Học Viên", count: "1,240", icon: "person.3.fill", color: AppTheme.pastelLavender)
                    }
                    .padding(.horizontal)
                    
                    // Management Actions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Công cụ Quản trị viên")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textDark)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            NavigationLink(destination: Text("Quản lý từ vựng - Đang hoàn thiện")) {
                                AdminActionRow(title: "Quản lý Từ vựng", subtitle: "Thêm, sửa, xoá từ vựng và chủ đề học", icon: "character.book.closed.fill", color: AppTheme.primaryMint)
                            }
                            
                            NavigationLink(destination: Text("Quản lý bài kiểm tra - Đang hoàn thiện")) {
                                AdminActionRow(title: "Quản lý Bài tập & Quizzes", subtitle: "Tạo câu hỏi trắc nghiệm, bài nghe viết", icon: "list.clipboard.fill", color: AppTheme.pastelSky)
                            }
                            
                            NavigationLink(destination: Text("Quản lý người dùng - Đang hoàn thiện")) {
                                AdminActionRow(title: "Quản lý Học viên", subtitle: "Xem tiến độ học tập, chỉnh sửa cấp độ", icon: "person.text.rectangle.fill", color: AppTheme.pastelLavender)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .background(AppTheme.bgGradientStart)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct AdminStatCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(count)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textDark)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cuteCardStyle()
    }
}

struct AdminActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textDark)
                
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textLight)
        }
        .padding(14)
        .cuteCardStyle()
    }
}

#Preview {
    AdminHomeView()
        .environmentObject(SessionManager.shared)
}
