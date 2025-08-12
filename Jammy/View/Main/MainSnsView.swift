//
//  Main2Postview.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/21.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainSnsView: View {
    @StateObject private var postViewModel = PostViewModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var userProfiles: [String: UserProfile] = [:]
    @State private var likes: [String: Bool] = [:]
    @State private var likeCounts: [String: Int] = [:]
    @State private var showCommentSheet = false
    @State private var selectedPost: PostModel?
    @State private var isLiking = false
    @State private var showError = false
    @State private var playing: Bool = true
    @State private var errorMessage = ""
    @Binding var navigationPath: NavigationPath  // @Bindingとして修正
    @Environment(\.colorScheme) var colorScheme
    private let favoritePostManager = FavoritePostManager()

    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(postViewModel.posts) { post in
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
                                    .multilineTextAlignment(.leading) // テキストの行揃えも左に
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // アクションボタン
                        actionButtons(for: post)
                    }
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear {
                        loadLikeState(for: post)
                        Task {
                            await fetchUserProfile(for: post.postUser)
                        }
                        
                        // 無限スクロール
                        if post.id == postViewModel.posts.last?.id {
                            Task {
                                try? await postViewModel.loadMoreTrendPosts(blockedUsers: blockViewModel.blockedUsers)
                            }
                        }
                    }
                }
                
                if postViewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            Task {
                try? await postViewModel.refreshTrendPosts(blockedUsers: blockViewModel.blockedUsers)
            }
        }
        .task {
            do {
                try await postViewModel.getInitialTrendPosts(blockedUsers: blockViewModel.blockedUsers)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Components
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
        HStack(spacing: 12) {
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                Text(post.artists.first ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
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
                    .foregroundColor(.purple)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
                selectedPost = post
                showCommentSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("コメント")
                        .font(.system(size: 14))
                }
                .foregroundColor(.gray)
            }
            .sheet(isPresented: $showCommentSheet) {
                NavigationView {
                    if let selectedPost = selectedPost {
                        MainCommentView(post: selectedPost)
                            .navigationTitle("コメント")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("閉じる") {
                                        showCommentSheet = false
                                    }
                                }
                            }
                    }
                }
                .presentationDetents([.large])
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
}
