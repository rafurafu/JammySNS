//
//  ProfilePostView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/23.
//

import SwiftUI
import Firebase

struct ProfilePostView: View {
    var post: PostModel
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var playing: Bool = true
    @State private var progressMS: Int = 0
    @State private var isLiked: Bool = false
    @State var isComment: Bool = false
    @State var postUserInfo: UserProfile = UserProfile(name: "", bio: "", profileImageURL: "", uid: "")
    @State private var postLikeCount: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var isCommentDetailShown = false
    @State private var showDeleteAlert = false
    let favoritePostManager = FavoritePostManager()
    
    // キャッシュされた計算プロパティ
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                userInfoSection(geometry: geometry)
                // 画像がない場合のみ音楽カードを表示
                if post.imageURL == nil {
                    mainCard(geometry: geometry)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
    }
    
    // メインカードビュー
    private func mainCard(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            cardBackground(geometry: geometry)
            VStack(spacing: 10) {
                albumImage
                songInfo(geometry: geometry)
                controlButtons(geometry: geometry)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // カードの背景
    private func cardBackground(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
            .shadow(color: Color(red: 0.8, green: 0.8, blue: 0.8), radius: 5, x: 1, y: 1)
            .frame(width: geometry.size.width - 40.0, height: 440)
            .foregroundColor(cardBackgroundColor)
            .padding(.top, 20)
    }
    
    // アルバムイメージ
    private var albumImage: some View {
        Group {
            if let url = URL(string: post.albumImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250)
                } placeholder: {
                    ProgressView()
                        .frame(width: 250, height: 250)
                }
            } else {
                Text("画像を読み込めません")
                    .frame(width: 250, height: 250)
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 10)
    }
    
    // 曲情報
    private func songInfo(geometry: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(post.name)
                    .font(.system(size: 45, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.leading, 30)
                
                ShareLink(
                    item: "https://open.spotify.com/track/\(post.trackURI.split(separator: ":").last ?? "")",
                    subject: Text("Jammyからのシェア"),
                    message: Text("\(postUserInfo.name)さんの投稿"),
                    preview: SharePreview(post.name)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 30, height: 30)
                        .foregroundColor(secondaryTextColor)
                }
            }
            .frame(width: geometry.size.width - 40.0)
            
            Text(post.artists.first ?? "エラー")
                .font(.system(size: 35))
                .fontWeight(.medium)
                .foregroundColor(secondaryTextColor)
                .frame(width: geometry.size.width - 40.0)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
        }
        .frame(height: 60)
    }
    
    // コントロールボタン
    private func controlButtons(geometry: GeometryProxy) -> some View {
        HStack(spacing: 25) {
            commentButton
            skipBackwardButton
            playPauseButton
            skipForwardButton
            likeButton
        }
        .frame(width: geometry.size.width - 40.0)
        .padding(.vertical, 25)
    }
    
    // 各ボタンの実装
    private var commentButton: some View {
        Button {
            isComment = true
        } label: {
            Image(systemName: "message")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27)
                .foregroundColor(textColor)
                .padding(.leading, 30)
        }
//        .sheet(isPresented: $isComment) {
//            MainCommentView(post: post)
//                .presentationDetents([.large])
//        }
    }
    
    private func deletePost() {
        Task {
            do {
                // Firestoreから投稿を削除
                let db = Firestore.firestore()
                if let postId = post.id {
                    try await db.collection("posts").document(postId).delete()
                    // 必要に応じて追加の後処理を行う
                }
            } catch {
                print("Error deleting post: \(error)")
            }
        }
    }
    
    private var skipBackwardButton: some View {
        Button {
            if spotifyManager.isPreview == false {
                seek(by: -15000)
            }
        } label: {
            Image(systemName: "15.arrow.trianglehead.counterclockwise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27)
                .foregroundColor(spotifyManager.isPreview == false ? textColor : .gray)
        }
        .disabled(spotifyManager.isPreview == true)
    }
    
    private var playPauseButton: some View {
        Button {
            togglePlayPause()
        } label: {
            Image(systemName: playing ? "pause" : "play")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27)
                .foregroundColor(textColor)
        }
    }
    
    private var skipForwardButton: some View {
        Button {
            if spotifyManager.isPreview == false {
                seek(by: 15000)
            }
        } label: {
            Image(systemName: "15.arrow.trianglehead.clockwise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27)
                .foregroundColor(spotifyManager.isPreview == false ? textColor : .gray)
        }
        .disabled(spotifyManager.isPreview == true)

    }
    
    private var likeButton: some View {
        Button {
            toggleLike()
        } label: {
            HStack {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 27, height: 27)
                    .foregroundColor(isLiked ? .red : textColor)
                Text("\(postLikeCount)")
                    .foregroundColor(isLiked ? .red : textColor)
                    .frame(width: 20)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
            }
        }
    }
    
    // ユーザー情報セクション
    private func userInfoSection(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            AsyncImage(url: URL(string: postUserInfo.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: 70, height: 70)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 20) {
                    Text(postUserInfo.name)
                        .font(.system(size: 20, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text(formatDate(post.postTime))
                        .font(.system(size: 10))
                        .fontWeight(.light)
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                    
                    // 投稿者のみに削除ボタンを表示
                    if post.postUser == authViewModel.myUserID {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 20, height: 20)
                        }
                        .alert("投稿を削除", isPresented: $showDeleteAlert) {
                            Button("キャンセル", role: .cancel) { }
                            Button("削除", role: .destructive) {
                                deletePost()
                            }
                        } message: {
                            Text("この投稿を削除してもよろしいですか？")
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(post.postComment)
                        .font(.system(size: 15, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(3)
                        .onTapGesture {
                            withAnimation {
                                isCommentDetailShown = true
                            }
                        }
                    
                    // 投稿画像がある場合は表示（音楽プレイヤーをオーバーレイ）
                    if let imageURL = post.imageURL,
                       let url = URL(string: imageURL) {
                        ZStack(alignment: .bottom) {
                            // 背景画像
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 250)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                case .failure(_):
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay {
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                    .font(.title2)
                                                Text("画像を読み込めませんでした")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            // 音楽プレイヤーオーバーレイ（画像の下部に配置）
                            overlayMusicPlayer()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                        .onTapGesture {
                            // 画像をタップした時の処理（拡大表示など）を将来実装可能
                        }
                    }
                }
            }
            .padding(.top, 10)
            .sheet(isPresented: $isCommentDetailShown) {
                CommentDetailView(post: post, postUserInfo: postUserInfo)
            }
        }
        .padding([.top, .leading], 20)
        .frame(width: geometry.size.width - 40.0, alignment: .leading)
    }
    
    // 機能
    private func loadInitialData() async {
        do {
            // ユーザー情報を取得
            postUserInfo = try await postViewModel.getUserInfo(userId: post.postUser)
            
            postLikeCount = try await favoritePostManager.getFavoritePostCount(postId: post.id ?? "")   // いいね数取得
            guard let userId = authViewModel.myUserID,
                  let postId = post.id else { return }
            
            do {
                let favoritePosts = try await FavoritePostManager.shared.getFavoritePosts(userId: userId)
                await MainActor.run {
                    isLiked = favoritePosts.contains(postId)
                }
            } catch {
                print("Failed to check favorite status: \(error)")
            }
            startProgressUpdates()
            // 曲を再生
            try await spotifyManager.playTrack(
                accessToken: spotifyManager.accessToken,
                trackURI: post.trackURI,
                previewURL: post.previewURL,
                positionMs: 0
            )
        } catch {
            print("Error loading initial data: \(error)")
        }
    }
    
    private func startProgressUpdates() {
        Task {
            while playing && progressMS < post.trackDuration {
                progressMS += 1000
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
            }
        }
    }
    
    private func togglePlayPause() {
        Task {
            do {
                if playing {
                    progressMS = try await spotifyManager.getPlayerProgress() ?? 0
                    try await spotifyManager.stopTrack(accessToken: spotifyManager.accessToken)
                } else {
                    if spotifyManager.isPremiumUser ?? true {
                        try await spotifyManager.playTrack(
                            accessToken: spotifyManager.accessToken,
                            trackURI: post.trackURI,
                            previewURL: post.previewURL,
                            positionMs: progressMS
                        )
                        startProgressUpdates()
                    } else {
                        progressMS = try await spotifyManager.getPlayerProgress() ?? 0
                    }
                }
                playing.toggle()
            } catch {
                print("Error toggling playback: \(error)")
            }
        }
    }
    
    private func seek(by milliseconds: Int) {
        progressMS = max(0, progressMS + milliseconds)
        let url = URL(string: "https://api.spotify.com/v1/me/player/seek?position_ms=\(progressMS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(spotifyManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func toggleLike() {
        // UserIDの取得と検証
        guard let userId = authViewModel.myUserID else {
            authViewModel.getMyUserID()
            print("Error: Valid user ID not available")
            return
        }
        
        guard let postId = post.id, !postId.isEmpty else {
            print("Error: Valid post ID not available")
            return
        }
        
        // print("Attempting like toggle - UserID: \(userId), PostID: \(postId)")
        
        Task {
            guard let userId = authViewModel.myUserID,
                  let postId = post.id else { return }
            
            do {
                if isLiked {
                    try await FavoritePostManager.shared.removeFavoritePostWithCache(userId: userId, postId: postId)
                    // いいね数を更新
                    let count = try await favoritePostManager.getFavoritePostCount(postId: postId)
                    await MainActor.run {
                        postLikeCount = count
                    }
                } else {
                    try await FavoritePostManager.shared.saveFavoritePostWithCache(userId: userId, postId: postId)
                    // いいね数を更新
                    let count = try await favoritePostManager.getFavoritePostCount(postId: postId)
                    await MainActor.run {
                        postLikeCount = count
                    }
                }
                await MainActor.run {
                    isLiked.toggle()
                }
                
            } catch {
                print("Error toggling like: \(error.localizedDescription)")
                // エラー時のUI更新
                await MainActor.run {
                    // 状態を元に戻す
                    isLiked.toggle()
                }
            }
        }
    }
    
    // 画像上に重ねる音楽プレイヤー
    private func overlayMusicPlayer() -> some View {
        HStack(spacing: 20) {
            // Album artwork (元のサイズと同じ)
            AsyncImage(url: URL(string: post.albumImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 5) {
                Text(post.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(post.artists.first ?? "Unknown Artist")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play button
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // 半透明のブラー背景
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.3))
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ProfilePostView(post: PostModel(name: "Sign", trackURI: "spotify:track:5ZLkGLEYYDlgcDXK6A2vYO", artists: ["Mr.Children"], albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273354761925b7a53bf12c6e07c", postComment: "aaa", trackDuration: 243000, postTime: Date() - 1000, postUser: "zuIyF0BTmGdVDH8JcTycN6qjbVO2", likeCount: 12, previewURL: "", imageURL: nil))
}

