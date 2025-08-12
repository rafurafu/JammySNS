import SwiftUI

// FollowContainerView
struct FollowContainerView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = OtherProfileViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // タブセレクター
                Picker("Follow Type", selection: $selectedTab) {
                    Text("フォロワー").tag(0)
                    Text("フォロー中").tag(1)
                }
                .frame(height: 100)
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                
                // 選択されたタブに応じて表示を切り替え
                if selectedTab == 0 {
                    FollowersView()
                        .frame(width: geometry.size.width, height: geometry.size.height - 130)
                } else {
                    FollowingView()
                        .frame(width: geometry.size.width, height: geometry.size.height - 130)
                }
            }
            .navigationTitle(selectedTab == 0 ? "フォロワー" : "フォロー中")
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// ProfileImageView
struct ProfileImageView: View {
    let imageURL: String?
    
    var body: some View {
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 45, height: 45)
            .clipShape(Circle())
            .shadow(radius: 2)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 45, height: 45)
                .foregroundColor(.gray)
        }
    }
}

// UserInfoView
struct UserInfoView: View {
    let name: String
    let bio: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(bio)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// FollowButton
struct FollowButton: View {
    @Binding var isFollowing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "フォロー中" : "フォローする")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isFollowing ? .gray : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(minWidth: 86)
                .background(isFollowing ? Color.gray.opacity(0.2) : Color.blue)
                .cornerRadius(16)
        }
    }
}

// UserRowView
struct UserRowView: View {
    let user: UserProfile
    @StateObject private var viewModel = OtherProfileViewModel()
    let showFollowButton: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ProfileImageView(imageURL: user.profileImageURL)
            
            UserInfoView(name: user.name, bio: user.bio)
                .frame(maxWidth: .infinity)
            
            if showFollowButton {
                FollowButton(isFollowing: Binding(
                    get: { viewModel.isFollowing },
                    set: { _ in }
                )) {
                    Task {
                        await handleFollowAction()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .task {
            await checkFollowStatus()
        }
    }
    
    private func checkFollowStatus() async {
        await viewModel.loadFollowData(for: user.id)
    }
    
    private func handleFollowAction() async {
        await viewModel.toggleFollow(for: user.id)
    }
}

// Preview
#Preview {
    NavigationView {
        FollowContainerView()
    }
}
