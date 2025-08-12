//
//  ProfileGridArtistView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/30.
//

import SwiftUI

struct ProfileGridArtistView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    let artistInfo: [FavoriteArtist]
    
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(colorScheme == .dark ? Color.gray : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVGrid(columns: layout, spacing: 0) {
                    ForEach(Array(artistInfo.enumerated()), id: \.element.id) { index, artist in
                            Button {
                                openSpotifyArtistPage(uri: artist.uri)
                            } label: {
                                ArtistThumbnailView(artist: artist, geometry: geometry)
                            }
                            
                        }
                        
                    }
                }
            }
        }
    }
    
    private func openSpotifyArtistPage(uri: String) {
           // SpotifyアプリのURLスキーム
           let spotifyAppURL = URL(string: uri)!
           
           // WebページのURL（アプリが開けない場合のフォールバック）
           let spotifyWebURL = URL(string: "https://open.spotify.com/artist/\(uri.split(separator: ":").last!)")!
           
           // まずSpotifyアプリを開こうとする
           if UIApplication.shared.canOpenURL(spotifyAppURL) {
               UIApplication.shared.open(spotifyAppURL) { success in
                   if !success {
                       // アプリが開けない場合はWebページを開く
                       UIApplication.shared.open(spotifyWebURL)
                   }
               }
           } else {
               // Spotifyアプリがインストールされていない場合はWebページを開く
               UIApplication.shared.open(spotifyWebURL)
           }
       }
    
}
// サムネイル表示用のヘルパービュー
struct ArtistThumbnailView: View {
    let artist: FavoriteArtist
    let geometry: GeometryProxy
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            if let url = URL(string: artist.imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width / 2.5, height: geometry.size.width / 2.5)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width / 2.5, height: geometry.size.width / 2.5)
                        .clipShape(Circle())
                }
            } else {
                Text("画像取得エラー")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width / 2.5, height: geometry.size.width / 2.5)
            }
            
            Text(artist.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, 4)
            
            // ジャンルがあれば表示
            if !artist.genres.isEmpty {
                Text(artist.genres[0])
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
        .frame(width: geometry.size.width / 2)
        .padding(.bottom, 8)
    }
}

