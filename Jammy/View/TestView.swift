//
//  TestView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/24.
//

import SwiftUI

struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String
}

struct PlaylistView: View {
    let playlists: [Playlist] = [
        Playlist(title: "お気に入りの曲", imageName: "heart.fill", description: "プレイリスト・79曲"),
        Playlist(title: "らふあるばむ", imageName: "person.crop.square", description: "プレイリスト・らふ"),
        Playlist(title: "さいきんお気に", imageName: "person.crop.square", description: "プレイリスト・らふ"),
        Playlist(title: "カラオケ", imageName: "person.crop.square", description: "プレイリスト・らふ"),
        Playlist(title: "K pop", imageName: "person.crop.square", description: "プレイリスト・らふ"),
        Playlist(title: "うにゃあ〜", imageName: "dog", description: "プレイリスト・ぱあー！"),
        Playlist(title: "歌える曲", imageName: "music.note.list", description: "プレイリスト・らふ"),
        Playlist(title: "ヨルシカ", imageName: "cloud.moon", description: "プレイリスト・らふ")
    ]
    
    var body: some View {
        NavigationView {
            List(playlists) { playlist in
                PlaylistRow(playlist: playlist)
            }
            .listStyle(PlainListStyle())
            .background(Color.black)
            .navigationTitle("プレイリスト")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: playlist.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(playlist.description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.black)
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
