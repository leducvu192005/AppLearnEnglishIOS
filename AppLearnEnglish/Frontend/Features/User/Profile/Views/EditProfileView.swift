//
//  EditProfileView.swift
//  AppLearnEnglish
//

import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Chọn ảnh đại diện")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.avatarPresets, id: \.self) { avatar in
                            let isSelected = viewModel.selectedAvatar == avatar
                            
                            Button(action: { viewModel.selectedAvatar = avatar }) {
                                Text(avatar)
                                    .font(.system(size: 44))
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? AppTheme.primaryMint.opacity(0.15) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? AppTheme.primaryMint : Color.black.opacity(0.05), lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Thông tin cá nhân")) {
                TextField("Họ và tên", text: $viewModel.name)
                    .font(.system(size: 15, design: .rounded))
                    .padding(.vertical, 4)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                Button(action: {
                    Task {
                        await viewModel.saveProfileChanges()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }) {
                    Text("Lưu thay đổi")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(AppTheme.primaryMint)
            }
        }
        .background(AppTheme.bgGradientStart)
        .navigationTitle("Chỉnh sửa hồ sơ")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Alert(title: Text("Lỗi"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("Đồng ý")))
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
