//
//  MainPostView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/09/19.
//

import SwiftUI

struct MainPostView: View {
    var post: PostModel
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var postViewModel: PostViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var playing: Bool = true
    @State private var progressMS: Int = 0
    @State private var isLiked: Bool = false
    @Binding var isComment: Bool
    @Binding var postUserInfo: UserProfile
    @State private var postLikeCount: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @Binding var navigationPath: NavigationPath
    @State private var isCommentDetailShown = false
    @State private var showingActionSheet = false
    let favoritePostManager = FavoritePostManager()
    
    // キャッシュされた計算プロパティ
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
    }
    
    private var textColor: Color {  // メインテキストカラー
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color { // サブテキストカラー
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
            //.frame(height: geometry.size.height - 150)
            // .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            Task {
                //                 await loadInitialData()
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
        //.padding(.top, 70)
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
    @MainActor private var albumImage: some View {
        Group {
            if let url = URL(string: post.albumImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.clear
                            .overlay {
                                ProgressView()
                            }
                            .frame(width: 250, height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                    case .failure(_):
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .foregroundColor(.gray)
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
                    .font(.system(size: 45 , design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.leading, 30)  // 曲名を中央に調整
                    .frame(height: 35)
                
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
                .frame(height: 25)
        }
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
                .padding(.leading, 20)  // playPauseButtonを中央に調整
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
                    .foregroundColor(isLiked ? Color.red : textColor)
                    .frame(width: 20)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
            }
        }
    }
    
    // ユーザー情報セクション
    private func userInfoSection(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            userProfileImage
            userInfoContent
        }
        .padding([.top, .leading], 20)
        .frame(width: geometry.size.width - 40.0, alignment: .leading)
    }
    
    @MainActor private var userProfileImage: some View {
        Button {
            navigateToProfile()
        } label: {
            AsyncImage(url: URL(string: postUserInfo.profileImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Color.clear
                        .overlay {
                            ProgressView()
                        }
                        .frame(width: 70, height: 70)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)
                        .clipShape(Circle())
                case .failure(_):
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    private var userInfoContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 20) {
                Text(postUserInfo.name)
                    .font(.system(size: 20, design: .rounded))
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .foregroundColor(textColor)
                
                Text(formatDate(post.postTime))
                    .font(.system(size: 10))
                    .fontWeight(.light)
                    .foregroundColor(secondaryTextColor)
                
                //　通報・ブロックボタン
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(textColor)
                }
                .confirmationDialog("アクション", isPresented: $showingActionSheet, titleVisibility: .hidden) {
                    Button(action: {
                        Task {
                            try await blockViewModel.blockUser(post.postUser)
                            //print("ブロックしたユーザー: \(post.postUser)")
                        }
                    }) {
                        Text("このユーザーをブロック")
                            .foregroundColor(.black)
                    }
                    
                    Button("このユーザーを報告", role: .destructive) {
                        navigationPath.append(AppNavigationDestination.report(reportedUserId: post.postUser, postId: post.id))
                    }
                    Button("キャンセル", role: .cancel) {
                        
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
                        isCommentDetailShown = true
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
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                            .font(.title)
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
                        // 画像をタップしたときに拡大表示などの処理を追加可能
                    }
                }
            }
        }
        .padding(.top, 10)
        .sheet(isPresented: $isCommentDetailShown) {
            CommentDetailView(post: post, postUserInfo: postUserInfo)
        }
    }
    
    /*
     機能
     */
    private func loadInitialData() async {
        do {
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
        } catch {
            print("Error loading initial data: \(error)")
        }
    }
    
    private func startProgressUpdates() {
        // 再生中の場合のみ進捗を更新
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
                    try await spotifyManager.playTrack(
                        accessToken: spotifyManager.accessToken,
                        trackURI: post.trackURI,
                        previewURL: post.previewURL,
                        positionMs: progressMS
                    )
                    startProgressUpdates()
                }
                playing.toggle()
            } catch {
                print("Error toggling playback: \(error)")
            }
        }
    }
    
    private func seek(by milliseconds: Int) {
        progressMS = max(0, progressMS + milliseconds)
        Task {
            try? await spotifyManager.seek(to: progressMS)
        }
    }
    
    private func toggleLike() {
        // UserIDの取得と検証
        guard let userId = authViewModel.myUserID else {
            authViewModel.getMyUserID() // idを取得
            print("Error: Valid user ID not available")
            return
        }
        
        guard let postId = post.id, !postId.isEmpty else {
            print("Error: Valid post ID not available")
            return
        }
        
        // print("Attempting like toggle - UserID: \(userId), PostID: \(postId)")
        
        Task{
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
                print("Failed to toggle favorite: \(error)")
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
    
    private func navigateToProfile() {
        if postUserInfo.id == "" {
            let alert = ShowAlert()
            alert.showOKAlert(title: "不明なユーザーです", message: "")
        } else {
            navigationPath = NavigationPath()
            navigationPath.append(AppNavigationDestination.profile(postUserInfo))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - CommentDetailView
struct CommentDetailView: View {
    let post: PostModel
    let postUserInfo: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        AsyncImage(url: URL(string: postUserInfo.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40)
                        }
                        .padding(.leading, 30)
                        
                        VStack(alignment: .leading) {
                            Text(postUserInfo.name)
                                .font(.headline)
                            Text(formatDate(post.postTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text(post.postComment)
                            .font(.body)
                            .padding(.leading, 30)
                            .multilineTextAlignment(.leading)
                        
                        // 投稿画像がある場合は表示
                        if let imageURL = post.imageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay {
                                            ProgressView()
                                        }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                case .failure(_):
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                                .font(.title)
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("投稿コメント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
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


#Preview {
    MainPostView(post: PostModel(name: "Sign", trackURI: "spotify:track:5ZLkGLEYYDlgcDXK6A2vYO", artists: ["Mr.Children"], albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273354761925b7a53bf12c6e07c", postComment: "aaa", trackDuration: 243000, postTime: Date() - 1000, postUser: "zuIyF0BTmGdVDH8JcTycN6qjbVO2", likeCount: 12, previewURL: "", imageURL: nil),
                 isComment: .constant(false),
                 postUserInfo: .constant(UserProfile(name: "name", bio: "こんちゃっちゃ", profileImageURL: "gs://jammy-1ab3e.appspot.com/profile_images/zuIyF0BTmGdVDH8JcTycN6qjbVO2.jpg", uid: "zuIyF0BTmGdVDH8JcTycN6qjbVO2")),
                 navigationPath: .constant(NavigationPath())
    )
    .environmentObject(SpotifyMusicManager())
}
