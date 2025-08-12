//
//  ProfileGridLikesView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/11/05.
//

import SwiftUI

struct ProfileGridLikesView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    let likePosts: [PostModel]
    
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
                    LazyVGrid(columns: layout, spacing: 16) {
                        ForEach(likePosts) { post in
                            Button {
                                print("navigationPath: \(navigationPath.count)")
                                if navigationPath.count > 2{
                                    navigationPath.removeLast()
                                }
                                navigationPath.append(AppNavigationDestination.post(post))
                            } label: {
                                LikesThumbnailView(post: post, geometry: geometry)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// サムネイル表示用のヘルパービュー
struct LikesThumbnailView: View {
    let post: PostModel
    let geometry: GeometryProxy
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // アルバムジャケット
            if let url = URL(string: post.albumImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (geometry.size.width - 48) / 2, height: (geometry.size.width - 48) / 2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    ProgressView()
                        .frame(width: (geometry.size.width - 48) / 2, height: (geometry.size.width - 48) / 2)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // 曲名とアーティスト名
            VStack(alignment: .leading, spacing: 4) {
                Text(post.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                
                Text(post.artists.joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: (geometry.size.width - 48) / 2)
            .padding(.horizontal, 4)
        }
        .frame(width: (geometry.size.width - 48) / 2)
    }
}

#Preview {
    ProfileGridLikesView(navigationPath: .constant(NavigationPath()), likePosts: [])
}
