//
//  MainJammyVerticalView.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/26.
//

import SwiftUI
import FirebaseAuth

struct MainSnsVerticalView: View {
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @Binding var isComment: Bool
    @Binding var isPlaylist: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var currentIndex: Int? = 0
    @Binding var navigationPath: NavigationPath
    @Binding var recommendSettings: RecommendSettings
    @State private var showUpdateMessage: Bool = false
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var lastPlayedIndex: Int? = nil
    let tracks: [TrackInfo.Track]
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    
                    LazyVStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.1.uri) { index, track in
                            MainSnsView(
                                playing: .constant(false),
                                post: createPostModel(from: track),
                                isComment: $isComment
                            )
                            .frame(height: screenHeight + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                            .id(index)
                            .onAppear {
                                handlePostAppear(index: index, track: track)
                            }
                        }
                        
                        if tracks.isEmpty {
                            emptyStateView
                        }
                    }
                }
                .scrollTargetLayout()
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentIndex)
                .onChange(of: currentIndex) { oldValue, newValue in
                    handleScrollPositionChange(oldValue: oldValue, newValue: newValue)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("おすすめの曲が見つかりませんでした")
                .font(.headline)
                .foregroundColor(.gray)
            Text("別の条件で試してみてください")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func handlePostAppear(index: Int, track: TrackInfo.Track) {
        // 前の曲を停止し、新しい曲を再生
        if lastPlayedIndex != index {
            Task {
                do {
                    if lastPlayedIndex != nil {
                        try await spotifyManager.stopTrack(accessToken: spotifyManager.accessToken)
                    }
                    
                    try await spotifyManager.playTrack(
                        accessToken: spotifyManager.accessToken,
                        trackURI: track.uri,
                        previewURL: track.preview_url,
                        positionMs: 0
                    )
                    
                    await MainActor.run {
                        lastPlayedIndex = index
                    }
                } catch {
                    print("Failed to play track: \(error)")
                }
            }
        }
    }
    
    private func handleScrollPositionChange(oldValue: Int?, newValue: Int?) {
        if let index = newValue,
           index < tracks.count,
           oldValue != newValue {
            Task {
                do {
                    // 前の曲を停止
                    if oldValue != nil {
                        try await spotifyManager.stopTrack(accessToken: spotifyManager.accessToken)
                    }
                    
                    // 新しい曲を再生
                    let track = tracks[index]
                    try await spotifyManager.playTrack(
                        accessToken: spotifyManager.accessToken,
                        trackURI: track.uri,
                        previewURL: track.preview_url,
                        positionMs: 0
                    )
                    
                    await MainActor.run {
                        lastPlayedIndex = index
                    }
                } catch {
                    print("Failed to handle scroll position change: \(error)")
                }
            }
        }
    }
}

private func createPostModel(from track: TrackInfo.Track) -> PostModel {
    PostModel(
        name: track.name,
        trackURI: track.uri,
        artists: track.artists.map { $0.name },
        albumImageUrl: track.album.images.first?.url ?? "",
        postComment: "Jammyのおすすめ曲です！",
        trackDuration: Int(track.duration_ms),
        postTime: Date(),
        postUser: "Jammy",
        likeCount: 0,
        previewURL: track.preview_url ?? ""
    )
}
