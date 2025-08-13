//
//  SwiftUIView.swift
//  Jammy
//
//  Created by adachikouki on 2024/10/11.
//

import SwiftUI
import FirebaseAuth

struct OtherProfileView: View {
    // ViewModels
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var postViewModel = PostViewModel()
    @EnvironmentObject private var spotifyManager: SpotifyMusicManager
    @StateObject private var socialViewModel = OtherProfileViewModel()
    @State private var topExpanded: Bool = true
    @State private var playlistsExpanded: Bool = true
    @State private var artistsExpanded: Bool = true
    @State private var profileImage: UIImage? = nil
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var isShowingPhotoPicker: Bool = false
    @State private var isShowingCropper: Bool = false
    @State private var isShowingUnfollowAlert: Bool = false
    @State private var usersPost: [PostModel] = []
    @State private var favoriteArtists: [FavoriteArtist] = []
    @Binding var navigationPath: NavigationPath
    var userId: String
    @State var userProfile: UserProfile = UserProfile(name: "name", bio: "", profileImageURL: "", uid: "")
    
    // UI Components
    let settingView = SettingView()
    @Environment(\.colorScheme) var colorScheme
    
    // UI Colors & Styles
    var backGroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var fontGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.41, blue: 0.71),
                Color(red: 0.07, green: 0.21, blue: 0.49)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            backGroundColor
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack (spacing: 0){
                    // Profile Section
                        HStack {
                            Spacer()
                            
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            
                            // User Info
                            VStack(spacing: 7) {
                                Text(userName)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                                    .foregroundColor(textColor)
                                    .fontWeight(.semibold)
                                
                                Text(userBio)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                                    .fontWeight(.medium)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                        }
                        .padding(.trailing, 10)
                        
                        // Follow Stats
                            HStack(spacing: 20) {
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(socialViewModel.followingCount)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(textColor)
                                    Text("フォロー中")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } .frame(width: 70)
                                
                                Divider()
                                    .frame(height: 20)
                                
                                VStack(spacing: 4) {
                                    Text("\(socialViewModel.followersCount)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(textColor)
                                    Text("フォロワー")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } .frame(width: 70)
                                
                                Spacer()
                            }
                            .padding(.trailing, 10)
                            .padding(.vertical, 8)
                            .padding(.bottom, 5)
                        
                        // Follow Button
                        Button(action: {
                            Task {
                                if socialViewModel.isFollowing {
                                    isShowingUnfollowAlert = true
                                } else {
                                    await socialViewModel.toggleFollow(for: userId)
                                }
                            }
                        }) {
                            Text(socialViewModel.isFollowing ? "フォロー中" : "フォローする")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(socialViewModel.isFollowing ? .gray : .white)
                                .frame(width: 160, height: 36)
                                .background(
                                    Group {
                                        if socialViewModel.isFollowing {
                                            Color.gray.opacity(0.2)
                                        } else {
                                            fontGradient
                                        }
                                    }
                                )
                                .cornerRadius(18)
                                .padding(.bottom, 10)
                        }
                        .alert("フォローを解除", isPresented: $isShowingUnfollowAlert) {
                            Button("キャンセル", role: .cancel) { }
                            Button("フォロー解除", role: .destructive) {
                                Task {
                                    await socialViewModel.toggleFollow(for: userId)
                                }
                            }
                        } message: {
                            Text("このユーザーのフォローを解除しますか？")
                        }
                    
                    Divider()
                    
                    // Posts Section
                    DisclosureGroup(
                        isExpanded: $topExpanded,
                        content: {
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(usersPost) { post in
                                        Button {
                                            if navigationPath.count > 1 {
                                                navigationPath.removeLast()
                                            }
                                            navigationPath.append(AppNavigationDestination.post(post))
                                        } label: {
                                            if let url = URL(string: post.albumImageUrl), !post.albumImageUrl.isEmpty {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 140.0, height: 140.0)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    case .failure(_):
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 140.0, height: 140.0)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                            .overlay(
                                                                Image(systemName: "music.note")
                                                                    .foregroundColor(.gray)
                                                            )
                                                    case .empty:
                                                        ProgressView()
                                                            .frame(width: 140.0, height: 140.0)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 140.0, height: 140.0)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .overlay(
                                                        Image(systemName: "music.note")
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        },
                        label: {
                            Button {
                                if navigationPath.count > 2 {
                                    navigationPath.removeLast()
                                }
                                navigationPath.append(AppNavigationDestination.postsGrid(userProfile))
                            } label: {
                                Text("投稿")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .overlay(
                                        fontGradient
                                            .mask(
                                                Text("投稿")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                            )
                                    )
                            }
                        }
                    )
                    
                    // 好きなアーティスト
                   
                    DisclosureGroup(
                        isExpanded: $artistsExpanded,
                        content: {
                            ScrollView(.horizontal) {
                                LazyHStack {    // 投稿
                                    ForEach(favoriteArtists) { artist in
                                        Button {
                                            openSpotifyArtistPage(uri: artist.uri)
                                        } label: {
                                            if let url = URL(string: artist.imageUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(Circle())
                                                }
                                            } else {
                                                Text("ジャケット取得エラー")
                                                    .frame(width: 140.0, height: 140.0)
                                            }
                                        }
                                    }
                                }
                                Spacer()
                            }
                        },
                        label: {
                            Button {
                                navigationPath.append(AppNavigationDestination.artist(favoriteArtists))
                            } label: {
                                Text("好きなアーティスト")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .overlay(
                                        fontGradient
                                            .mask(
                                                Text("好きなアーティスト")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                            ) // mask
                                    ) // overlay
                            }
                        } // label
                    ) // DisclosureGroup
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                do {
                    // ユーザープロフィールの取得
                    userProfile = try await authViewModel.getOtherUserProfile(id: userId)
                    self.userName = userProfile.name
                    self.userBio = userProfile.bio
                    
                    // 投稿の取得
                    try await postViewModel.getUsersPost(for: userId)
                    await MainActor.run {
                        usersPost = postViewModel.posts
                    }
                    
                    // プロフィール画像の取得
                    if let imageURLString = userProfile.profileImageURL,
                       let imageURL = URL(string: imageURLString) {
                        URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                            if let data = data,
                               let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.profileImage = image
                                }
                            }
                        }.resume()
                    }
                    let favoriteManager = FavoriteArtistsManager()
                    let artists = try await favoriteManager.getFavoriteArtists(userId: userId)
                    await MainActor.run {
                        favoriteArtists = artists
                    }
                    // フォローデータの読み込み
                    await socialViewModel.loadFollowData(for: userId)
                } catch {
                    print("Error fetching profile: \(error.localizedDescription)")
                }
            }
        }
        .alert("エラー", isPresented: $socialViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(socialViewModel.errorMessage ?? "不明なエラーが発生しました")
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

#Preview {
    OtherProfileView(
        navigationPath: .constant(NavigationPath()),
        userId: "3UHKcuHHSzMZcu7LKRI0RWaDbFE3",
        userProfile: UserProfile(
            name: "name", bio: "bio",
            profileImageURL: "https://firebasestorage.googleapis.com:443/v0/b/jammy-1ab3e.appspot.com/o/profile_images%2FFkDwejuh3sdrQ4THg49uZH2XEmH3.jpg?alt=media&token=3084adab-9584-4385-a438-2850af213f10",
            uid: "3UHKcuHHSzMZcu7LKRI0RWaDbFE3"
        )
    )
}
