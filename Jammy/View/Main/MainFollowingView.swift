//
//  MainFollowingView.swift
//  Jammy
//
//  フォロー中のユーザーの投稿を表示するビュー
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainFollowingView: View {
    @StateObject private var postViewModel = PostViewModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var userProfiles: [String: UserProfile] = [:]
    @State private var likes: [String: Bool] = [:]
    @State private var likeCounts: [String: Int] = [:]
    @State private var commentSheetPost: PostModel?
    @State private var isLiking = false
    @State private var showError = false
    @State private var playing: Bool = true
    @State private var errorMessage = ""
    @Binding var navigationPath: NavigationPath
    @Environment(\.colorScheme) var colorScheme
    private let favoritePostManager = FavoritePostManager()

    // MARK: - Body
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("Coming Soon")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("フォロー中のユーザーの投稿表示機能は\n近日公開予定です")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
    }
    
    // MARK: - Components
    private func postCell(for post: PostModel, index: Int) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // ユーザー情報ヘッダー
                postHeader(for: post)
                
                // 音楽プレイヤーカード
                musicPlayerCard(for: post)
                
                // 投稿コメント
                if !post.postComment.isEmpty {
                    HStack(alignment: .top) {
                        Text(post.postComment)
                            .font(.system(size: 15))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // アクションボタン
                actionButtons(for: post)
            }
            .padding(.vertical, 16)
            .background(Color.clear)
            .padding(.horizontal, 16)
            
            // 薄い線を追加（最後の投稿以外）
            if index < postViewModel.posts.count - 1 {
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private func postHeader(for post: PostModel) -> some View {
        HStack(spacing: 12) {
            // プロフィール画像とユーザー情報
            if let userProfile = userProfiles[post.postUser] {
                Button {
                    navigateToProfile(for: userProfile)
                } label: {
                    AsyncImage(url: URL(string: userProfile.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfile.name)
                        .font(.headline)
                    Text(formatDate(post.postTime))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ProgressView()
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // More options button
            Menu {
                if let userProfile = userProfiles[post.postUser] {
                    if post.postUser != Auth.auth().currentUser?.uid {
                        // 他のユーザーの投稿の場合
                        Button(role: .destructive) {
                            Task {
                                try? await blockViewModel.blockUser(post.postUser)
                            }
                        } label: {
                            Label("ブロック", systemImage: "person.fill.xmark")
                        }
                        
                        Button(role: .destructive) {
                            navigationPath.append(AppNavigationDestination.report(reportedUserId: post.postUser, postId: post.id))
                        } label: {
                            Label("報告", systemImage: "exclamationmark.triangle")
                        }
                    } else {
                        // 自分の投稿の場合
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await postViewModel.deletePost(postId: post.id)
                                } catch {
                                    print("Error deleting post: \(error)")
                                }
                            }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.horizontal)
    }
    
    private func musicPlayerCard(for post: PostModel) -> some View {
        let trackId = extractTrackId(from: post.trackURI)
        let dominantColor = spotifyManager.getAlbumDominantColor(for: trackId, imageURL: post.albumImageUrl)
        
        return HStack(spacing: 12) {
            // Album artwork
            AsyncImage(url: URL(string: post.albumImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(post.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(post.artists.first ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play button
            Button {
                playTrack(post: post)
            } label: {
                Image(systemName: playing ? "play.circle.fill" : "play")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    dominantColor.opacity(0.8),
                    dominantColor.opacity(0.6)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func actionButtons(for post: PostModel) -> some View {
        HStack(spacing: 24) {
            // Like button
            Button {
                handleLike(post: post)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: likes[post.id ?? ""] ?? false ? "heart.fill" : "heart")
                        .foregroundColor(likes[post.id ?? ""] ?? false ? .red : .gray)
                    Text("\(likeCounts[post.id ?? ""] ?? post.likeCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .disabled(isLiking)
            
            // Comment button
            Button {
                print("Comment button pressed for post: \(post.id ?? "unknown")")
                print("Post name: \(post.name)")
                commentSheetPost = post
                print("Comment sheet post set: \(commentSheetPost?.id ?? "unknown")")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("コメント")
                        .font(.system(size: 14))
                }
                .foregroundColor(.gray)
            }
            .sheet(item: $commentSheetPost) { post in
                NavigationView {
                    MainCommentView(post: post)
                        .navigationTitle("コメント")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") {
                                    commentSheetPost = nil
                                }
                            }
                        }
                }
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
                .onAppear {
                    print("Comment sheet appeared for post: \(post.id ?? "unknown")")
                }
            }
            
            Spacer()
            
            // Share button
            ShareLink(
                item: "https://open.spotify.com/track/\(post.trackURI.split(separator: ":").last ?? "")",
                subject: Text("Jammyからのシェア"),
                message: Text("\(userProfiles[post.postUser]?.name ?? "")さんの投稿"),
                preview: SharePreview(post.name)
            ) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    private func loadLikeState(for post: PostModel) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let isLiked = try await FavoritePostManager.shared.checkFavoriteStatus(
                    userId: userId,
                    postId: postId
                )
                let likeCount = try await FavoritePostManager.shared.getFavoritePostCount(
                    postId: postId
                )
                
                await MainActor.run {
                    likes[postId] = isLiked
                    likeCounts[postId] = likeCount
                }
            } catch {
                print("Error loading like state: \(error)")
            }
        }
    }
    
    private func navigateToProfile(for userProfile: UserProfile) {
        print("ナビゲートボタンが押されたよ")
        if userProfile.id == "" {
            let alert = ShowAlert()
            alert.showOKAlert(title: "不明なユーザーです", message: "")
        } else {
            print("ユーザー情報: \(userProfile)")
            navigationPath = NavigationPath()
            navigationPath.append(AppNavigationDestination.profile(userProfile))
        }
    }
    
    private func handleLike(post: PostModel) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        guard !isLiking else { return }
        isLiking = true
        
        Task {
            do {
                let currentLikeState = likes[postId] ?? false
                
                if currentLikeState {
                    try await FavoritePostManager.shared.removeFavoritePost(
                        userId: userId,
                        postId: postId
                    )
                } else {
                    try await FavoritePostManager.shared.saveFavoritePost(
                        userId: userId,
                        postId: postId
                    )
                }
                
                let newCount = try await FavoritePostManager.shared.getFavoritePostCount(
                    postId: postId
                )
                
                await MainActor.run {
                    likes[postId] = !currentLikeState
                    likeCounts[postId] = newCount
                    isLiking = false
                }
            } catch {
                print("Error handling like: \(error)")
                await MainActor.run {
                    isLiking = false
                    showError = true
                    errorMessage = "いいねの処理に失敗しました"
                }
            }
        }
    }
    
    private func playTrack(post: PostModel) {
        Task {
            do {
                try await spotifyManager.playTrack(
                    accessToken: spotifyManager.accessToken,
                    trackURI: post.trackURI,
                    previewURL: post.previewURL,
                    positionMs: 0
                )
            } catch {
                showError = true
                errorMessage = "再生に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchUserProfile(for userId: String) async {
        if userProfiles[userId] == nil {
            do {
                let profile = try await postViewModel.getUserInfo(userId: userId)
                await MainActor.run {
                    userProfiles[userId] = profile
                }
            } catch {
                print("Error fetching user profile: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - 色関連のヘルパー関数
    
    private func extractTrackId(from trackURI: String) -> String {
        return String(trackURI.split(separator: ":").last ?? "")
    }
}