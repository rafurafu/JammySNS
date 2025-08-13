//
//  MainView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/06/12.
//

import SwiftUI

struct MainView: View {
    //ポスト
    @State var isComment: Bool = false
    @State var isPlaylist: Bool = false
    @State var isJammyReco: Bool = false
    @State var postUserInfo: UserProfile = UserProfile(name: "", bio: "", profileImageURL: "", uid: "")
    @State var currentPost: PostModel = PostModel(id: "", name: "", trackURI: "", artists: [""], albumImageUrl: "", postComment: "", trackDuration: 0, postTime: Date(), postUser: "", likeCount: 0, previewURL: "")
    
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var scrollToTop: Bool = false
    @State private var indicatorOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    @Binding var navigationPath: NavigationPath
    @State private var playlistSheetData: PlaylistSheetData?
    @State private var userPlaylists: [PlaylistModel] = []
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    let spotifyColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.11, green: 0.73, blue: 0.33),
            Color(red: 0.13, green: 0.83, blue: 0.38),
            Color(red: 0.0, green: 0.55, blue: 0.25)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // ヘッダー
                VStack {
                    HStack {
                        Button(action: {
                            scrollToTop = true
                        }) {
                            Text("Jammy")
                                .font(.system(size: 40))
                                .fontWeight(.bold)
                                .padding(.top, 60)
                                .padding(.leading, 20)
                                .foregroundColor(.clear)
                                .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
                                .overlay(
                                    fontColor.mask(
                                        Text("Jammy")
                                            .font(.system(size: 40))
                                            .fontWeight(.bold)
                                            .padding(.top, 60)
                                            .padding(.leading, 20)
                                    )
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                do {
                                    // プレイリストを取得
                                    let playlists = try await spotifyManager.getPlaylist(accessToken: spotifyManager.accessToken)
                                    await MainActor.run {
                                        userPlaylists = playlists
                                        playlistSheetData = PlaylistSheetData(
                                            playlists: playlists,
                                            currentTrack: currentPost
                                        )
                                    }
                                } catch {
                                    // エラーハンドリング
                                    let alert = ShowAlert()
                                    alert.showOKAlert(
                                        title: "プレイリストの取得に失敗しました",
                                        message: "Spotifyとの接続を確認してください。"
                                    )
                                }
                            }
                        }) {
                            Image("SpotifyIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 35)
                                .foregroundStyle(spotifyColor)
                                .padding(8)
                                .background(
                                    colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white
                                )
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                                .padding(.top, 60)
                                .padding(.trailing, 40)
                        }
                        .sheet(item: $playlistSheetData) { data in
                            MainPlaylistView(
                                playlists: data.playlists,
                                currentTrack: data.currentTrack
                            )
                            .presentationDetents([.fraction(0.7)])
                            .presentationDragIndicator(.visible)
                        }
                    }
                    .frame(height: 110)
                    
                    pageIndicatorView(width: geometry.size.width)
                        .padding(.bottom, 10)
                }
                .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
                .frame(height: 150)
                .zIndex(1000)
                
                TabView(selection: $selectedTab) {
                    MainSnsView(navigationPath: $navigationPath)
                        .environmentObject(blockViewModel)
                        .environmentObject(spotifyManager)
                        .frame(width: geometry.size.width, height: geometry.size.height - 150)
                        .tag(0)
                    
                    MainFollowingView()
                        .environmentObject(blockViewModel)
                        .environmentObject(spotifyManager)
                        .frame(width: geometry.size.width, height: geometry.size.height - 150)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .onChange(of: selectedTab) { newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    indicatorOffset = CGFloat(newValue) * (geometry.size.width / 2)
                }
            }
            .ignoresSafeArea(.all)
            .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        }
    }
    
    private func pageIndicatorView(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = 0
                    }
                } label: {
                    Text("トレンド")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == 0 ?
                            (colorScheme == .dark ? Color.white : Color.black) :
                            Color.gray)
                        .frame(width: width / 2, height: 44)
                }
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = 1
                    }
                } label: {
                    Text("フォロー中")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == 1 ?
                            (colorScheme == .dark ? Color.white : Color.black) :
                            Color.gray)
                        .frame(width: width / 2, height: 44)
                }
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(Color(red: 0.07, green: 0.6, blue: 0.9))
                    .frame(width: width / 2, height: 3)
                    .offset(x: indicatorOffset)
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
    }
}

struct PlaylistSheetData: Identifiable {
    let id = UUID()
    let playlists: [PlaylistModel]
    let currentTrack: PostModel
}
