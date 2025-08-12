//
//  SwiftUIView.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/12/16.
//
//(その週/月のトップアーティストやトップソングを表示)


import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedSegment = 0
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    
    private let segments = ["トラック", "アーティスト", "プレイリスト", "ユーザー"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // トレンドセクション
                    VStack(alignment: .leading, spacing: 20) {
                        // 今週のトップアーティスト
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今週のトップアーティスト")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(0..<10) { _ in
                                        WeeklyTopArtistCard()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 今週のトップソング
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今週のトップソング")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(0..<10) { _ in
                                        WeeklyTopSongCard()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // セグメントコントロール
                    Picker("検索カテゴリー", selection: $selectedSegment) {
                        ForEach(0..<segments.count, id: \.self) { index in
                            Text(segments[index])
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // 検索結果
                    if !searchText.isEmpty {
                        switch selectedSegment {
                        case 0:
                            TrackSearchResults(searchText: searchText)
                        case 1:
                            ArtistSearchResults(searchText: searchText)
                        case 2:
                            PlaylistSearchResults(searchText: searchText)
                        case 3:
                            UserSearchResults(searchText: searchText)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("検索")
            .searchable(text: $searchText, prompt: "曲名、アーティスト名、ユーザー名など")
        }
        .onAppear {
            Task {
                print("プレイリストを取得")
                let japanTop = try await spotifyManager.getTopPlaylist().japan
                let globalTop = try await spotifyManager.getTopPlaylist().global
                print("japanTop: \(japanTop)")
                print("globalTop: \(globalTop)")
            }
        }
    }
}

// トップアーティストカード
struct WeeklyTopArtistCard: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .shadow(radius: 4)
            
            VStack(alignment: .center, spacing: 4) {
                Text("アーティスト名")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("週間リスナー: 100万")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: 120)
        }
    }
}

// トップソングカード
struct WeeklyTopSongCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                // 再生回数バッジ
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("100万回")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(8)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("曲名")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("アーティスト名")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: 160)
        }
    }
}

// 各検索結果コンポーネント
struct TrackSearchResults: View {
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<5) { _ in
                TrackRow()
            }
        }
    }
}

struct ArtistSearchResults: View {
    let searchText: String
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(0..<6) { _ in
                ArtistCard()
            }
        }
    }
}

struct PlaylistSearchResults: View {
    let searchText: String
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(0..<6) { _ in
                PlaylistCard()
            }
        }
    }
}

struct UserSearchResults: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5) { _ in
                UserRow()
            }
        }
    }
}

// 各行のコンポーネント
struct TrackRow: View {
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .resizable()
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text("曲名")
                    .font(.headline)
                Text("アーティスト名")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // メニューアクション
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArtistCard: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            
            Text("アーティスト名")
                .font(.headline)
                .lineLimit(1)
        }
    }
}

struct PlaylistCard: View {
    var body: some View {
        VStack {
            Image(systemName: "music.note.list")
                .resizable()
                .frame(width: 120, height: 120)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            Text("プレイリスト名")
                .font(.headline)
                .lineLimit(1)
        }
    }
}

struct UserRow: View {
    @State private var isFollowing = false
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text("ユーザー名")
                    .font(.headline)
                Text("@username")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                isFollowing.toggle()
            }) {
                Text(isFollowing ? "フォロー中" : "フォロー")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(isFollowing ? .primary : .white)
                    .cornerRadius(16)
            }
        }
    }
}

// プレビュー
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(SpotifyMusicManager())
    }
}
