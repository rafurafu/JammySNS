//
//  MainPlaylistView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/06/04.
//

import SwiftUI

struct MainPlaylistView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State var playlists: [PlaylistModel]
    @State private var selectedPlaylists: Set<String> = []
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    var currentTrack: PostModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("保存するプレイリストを選択")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.leading, 20)
                
                Spacer()
                
                // 保存ボタン
                Button(action: {
                    Task {
                        do {
                            for playlistId in selectedPlaylists {
                                try await spotifyManager.saveTrackToPlaylist(
                                    trackUri: currentTrack.trackURI,
                                    playlistId: playlistId
                                )
                            }
                            dismiss()
                        } catch {
                            print("Failed to add track: \(error)")
                        }
                    }
                }) {
                    Text("保存")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 36)
                        .background(fontColor)
                        .cornerRadius(18)
                }
                .padding(.trailing, 20)
            }
            .frame(height: 60)
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // プレイリストリスト
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(playlists) { playlist in
                        PlaylistRowView(
                            playlist: playlist,
                            isSelected: selectedPlaylists.contains(playlist.id),
                            onTap: {
                                if selectedPlaylists.contains(playlist.id) {
                                    selectedPlaylists.remove(playlist.id)
                                } else {
                                    selectedPlaylists.insert(playlist.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct PlaylistRowView: View {
    let playlist: PlaylistModel
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // プレイリストアートワーク
                if let imageUrl = playlist.images.first?.url,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                }
                
                // プレイリスト情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text("Spotify プレイリスト")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // チェックボックス
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(12)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

