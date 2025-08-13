//
//  MainVerticalView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/06/12.
//
import SwiftUI

struct MainVerticalView: View {
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var blockViewModel: BlockViewModel
    @Binding var isComment: Bool
    @Binding var isPlaylist: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // User profile management
    @State private var userProfiles: [String: UserProfile] = [:]
    
    // Navigation and content state
    @Binding var postUserInfo: UserProfile
    @Binding var navigationPath: NavigationPath
    @Binding var currentPost: PostModel
    @Binding var scrollToTop: Bool
    @State private var currentTask: Task<Void, Never>?
    
    // UI State management
    @State private var currentIndex: Int? = 0
    @State private var isLoading = false
    @State private var lastPlayedIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    
                    LazyVStack(spacing: 0) {
                        ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
                            MainPostView(
                                post: post,
                                isComment: $isComment,
                                postUserInfo: Binding(
                                    get: { userProfiles[post.postUser] ?? UserProfile(name: "不明なユーザーです", bio: "", profileImageURL: "https://www.shoshinsha-design.com/wp-content/uploads/2020/05/noimage-760x460.png", uid: "") },
                                    set: { _ in }
                                ),
                                navigationPath: $navigationPath
                            )
                            .environmentObject(authViewModel)
                            .frame(height: screenHeight + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                            .id(index)
                            .onAppear {
                                Task {
                                    currentTask?.cancel()
                                    currentTask = Task {
                                        await loadUserProfile(for: post.postUser)
                                        handlePostAppear(index: index, post: post)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollTargetLayout()
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentIndex)
                .onChange(of: currentIndex) { oldValue, newValue in
                    handleScrollPositionChange(oldValue: oldValue, newValue: newValue)
                }
                .onChange(of: scrollToTop) { oldValue, newValue in
                    if newValue {
                        Task {
                            // 音楽を停止
                            try? await spotifyManager.stopTrack(accessToken: spotifyManager.accessToken)
                            
                            // タイムアウト用のフラグ
                            var scrollSucceeded = false
                            
                            await MainActor.run {
                                // 状態をリセット
                                currentIndex = 0
                                lastPlayedIndex = nil
                                
                                // アニメーションでトップにスクロール
                                withAnimation(.spring()) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                                scrollSucceeded = true
                            }
                            
                            // 3秒待ってスクロールが成功していなければ強制更新
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            if !scrollSucceeded {
                                await MainActor.run {
                                    // 全データをクリアして再読み込み
                                    userProfiles.removeAll()
                                    postViewModel.posts.removeAll()
                                    currentIndex = nil
                                    lastPlayedIndex = nil
                                    scrollToTop = false
                                    
                                    // 再読み込み
                                    Task {
                                        await loadInitialData()
                                    }
                                }
                                return
                            }
                            
                            // 正常にスクロールできた場合の処理
                            await MainActor.run {
                                scrollToTop = false
                                if let initialPost = postViewModel.posts.first {
                                    Task {
                                        try? await spotifyManager.playTrack(
                                            accessToken: spotifyManager.accessToken,
                                            trackURI: initialPost.trackURI,
                                            previewURL: initialPost.previewURL,
                                            positionMs: 0
                                        )
                                        await MainActor.run {
                                            lastPlayedIndex = 0
                                            updateContent(for: initialPost)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
            }
        }
        .task {
            await loadInitialData()
        }
        .onDisappear {
            // 画面を離れる時のクリーンアップ
            currentTask?.cancel()
            userProfiles.removeAll()
            currentIndex = nil
            lastPlayedIndex = nil
            postViewModel.posts.removeAll()
            
            URLCache.shared.removeAllCachedResponses()
        }
    }
    
    private func loadUserProfile(for userId: String) async {
        do {
            let userInfo = try await postViewModel.getUserInfo(userId: userId)
            await MainActor.run {
                userProfiles[userId] = userInfo
            }
        } catch {
            print("Failed to load user profile for user \(userId): \(error)")
        }
    }
    
    private func handlePostAppear(index: Int, post: PostModel) {
        currentTask?.cancel()
        Task {
            await loadUserProfile(for: post.postUser)
            await postViewModel.loadMorePostsIfNeeded(currentIndex: index, blockedUsers: blockViewModel.blockedUsers)
        }
        
        if lastPlayedIndex != index {
            Task {
                do {
                    if lastPlayedIndex != nil {
                        try await spotifyManager.stopTrack(accessToken: spotifyManager.accessToken)
                    }
                    
                    try await spotifyManager.playTrack(
                        accessToken: spotifyManager.accessToken,
                        trackURI: post.trackURI,
                        previewURL: post.previewURL,
                        positionMs: 0
                    )
                    
                    await MainActor.run {
                        lastPlayedIndex = index
                        updateContent(for: post)
                    }
                } catch {
//                    let alert = ShowAlert()
//                    alert.showOKAlert(title: "音楽が再生できません。", message: "申し訳ありません。Preview用のURLが見当たらないため音楽が再生できませんでした。")
                    print("Failed to play track: \(error)")
                }
            }
        }
    }
    
    private func handleScrollPositionChange(oldValue: Int?, newValue: Int?) {
        if let index = newValue,
           index < postViewModel.posts.count,
           oldValue != newValue {
            let post = postViewModel.posts[index]
            updateContent(for: post)
        }
    }
    
    private func updateContent(for post: PostModel) {
        Task {
            await MainActor.run {
                currentPost = post
                if let userProfile = userProfiles[post.postUser] {
                    postUserInfo = userProfile
                }
            }
        }
    }
    
    private func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await postViewModel.getFollowingPosts(blockedUsers: blockViewModel.blockedUsers)
            if !postViewModel.posts.isEmpty {
                let initialPost = postViewModel.posts[0]
                await MainActor.run {
                    currentPost = initialPost
                    currentIndex = 0
                }
                
                // 初期ポストの音楽を再生
                try await spotifyManager.playTrack(
                    accessToken: spotifyManager.accessToken,
                    trackURI: initialPost.trackURI,
                    previewURL: initialPost.previewURL,
                    positionMs: 0
                )
                
                await MainActor.run {
                    lastPlayedIndex = 0
                }
                
                await loadUserProfile(for: initialPost.postUser)
            }
        } catch {
            print("Initial data load error: \(error)")
        }
    }
}
