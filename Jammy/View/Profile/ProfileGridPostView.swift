import SwiftUI

struct ProfileGridPostView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    let postUserInfo: UserProfile
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State private var isComment = false
    @State var postLikeCount: Int = 0
    @State var isLiked: Bool = false
    var postCount: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    let layout = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // 投稿を時系列順にソートする computed property
    var sortedPosts: [PostModel] {
        postViewModel.posts.sorted { $0.postTime > $1.postTime }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(colorScheme == .dark ? Color.gray : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVGrid(columns: layout, spacing: 16) {
                        ForEach(sortedPosts, id: \.id) { post in
                            Button {
                                if navigationPath.count > 2 {
                                    navigationPath.removeLast()
                                }
                                navigationPath.append(AppNavigationDestination.post(post))
                            } label: {
                                PostThumbnailView(post: post, geometry: geometry)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    Task {
                        try await postViewModel.getUsersPost(for: postUserInfo.id)
                    }
                }
            }
        }
    }
}

struct PostThumbnailView: View {
    let post: PostModel
    let geometry: GeometryProxy
    @Environment(\.colorScheme) var colorScheme
    
    // 日付フォーマット関数
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        // 一週間以上前の場合は通常の日付表示に切り替える
        let oneWeek: TimeInterval = 7 * 24 * 60 * 60
        if Date().timeIntervalSince(date) > oneWeek {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP")
            dateFormatter.dateFormat = "MM/dd HH:mm"
            return dateFormatter.string(from: date)
        }
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // アルバムジャケット画像とタイムスタンプオーバーレイ
            if let url = URL(string: post.albumImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (geometry.size.width - 48) / 2, height: (geometry.size.width - 48) / 2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            // タイムスタンプオーバーレイ
                            Text(formatDate(post.postTime))
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(8),
                            alignment: .bottomTrailing
                        )
                } placeholder: {
                    ProgressView()
                        .frame(width: (geometry.size.width - 48) / 2, height: (geometry.size.width - 48) / 2)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // 曲情報とアーティスト情報
            VStack(alignment: .leading, spacing: 4) {
                // 曲名
                Text(post.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                
                // アーティスト名
                Text(post.artists.joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: (geometry.size.width - 48) / 2)
            .padding(.horizontal, 4)
        }
        .frame(width: (geometry.size.width - 48) / 2)
    }
}

#Preview {
    ProfileGridPostView(
        navigationPath: .constant(NavigationPath()),
        postUserInfo: UserProfile(
            name: "name", bio: "bio",
            profileImageURL: "https://firebasestorage.googleapis.com:443/v0/b/jammy-1ab3e.appspot.com/o/profile_images%2FFkDwejuh3sdrQ4THg49uZH2XEmH3.jpg?alt=media&token=3084adab-9584-4385-a438-2850af213f10",
            uid: "FkDwejuh3sdrQ4THg49uZH2XEmH3"
        )
    )
}
