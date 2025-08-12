import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject var postViewModel = PostViewModel()
    @StateObject private var socialViewModel = OtherProfileViewModel()
    @EnvironmentObject var spotifyManager : SpotifyMusicManager
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var topExpanded: Bool = true
    @State private var playlistsExpanded: Bool = true
    @State private var artistsExpanded: Bool = true
    @State private var userProfile: UserProfile = UserProfile(name: "", bio: "", profileImageURL: "", uid: "")
    @State private var profileImage: UIImage? = nil
    @State private var isShowingPhotoPicker: Bool = false
    @State private var isShowingCropper: Bool = false
    @State private var isComment: Bool = false
    @Binding var navigationPath: NavigationPath
    @State private var myPosts: [PostModel] = []
    //@State private var LikeArtists: [LikeArtistsModel.Artists.Artist] = []
    @State private var favoriteArtists: [FavoriteArtist] = []
    @State private var favoritePosts: [PostModel] = []
    @Environment(\.colorScheme) var colorScheme
    
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
                VStack {
                    HStack(alignment: .top) {
                        NavigationLink(destination: ProfileAccountSettingView()) {
                            //VStack {
                            HStack {
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
                                
                                VStack (spacing: 7){
                                    Text(userProfile.name)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.1)
                                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                                        .foregroundColor(textColor)
                                        .fontWeight(.semibold)
                                    
                                    Text(userProfile.bio)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.1)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                                        .fontWeight(.medium)
                                }
                                .padding(.leading, 10)
                                Spacer()
                            }.padding(.leading, 10)
                            //}
                        }
                        .frame(alignment: .center)
                        Spacer()
                        NavigationLink(
                            destination: SettingView()
                                .environmentObject(blockViewModel)
                        ) {
                            Image(systemName: "gearshape")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding(.top, 20)
                                .frame(alignment: .topTrailing)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                                .fontWeight(.medium)
                        }
                    }
                    HStack(spacing: 10) {
                        NavigationLink(destination: FollowContainerView()) {
                            VStack(spacing: 4) {
                                Text("\(socialViewModel.followingCount)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(textColor)
                                Text("フォロー中")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 70)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        NavigationLink(destination: FollowContainerView()) {
                            VStack(spacing: 4) {
                                Text("\(socialViewModel.followersCount)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(textColor)
                                Text("フォロワー")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 70)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        VStack(spacing: 4) {
                            Text("\(favoritePosts.count)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(textColor)
                            Text("いいね")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 70)
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 5)
                    
                    Divider()
                    Spacer()
                    
                    DisclosureGroup(
                        isExpanded: $topExpanded,
                        content: {
                            ScrollView(.horizontal) {
                                LazyHStack {    // 自分の投稿
                                    ForEach(myPosts) { post in
                                        Button {
                                            navigationPath.append(AppNavigationDestination.post(post))
                                        } label: {
                                            if let url = URL(string: post.albumImageUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        }, label: {
                            Button {
                                navigationPath = NavigationPath()
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
                                            ) // mask
                                    ) // overlay
                            }
                        } // label
                    ) // DisclosureGroup
                    
                    Spacer()
                    
                    // いいねした投稿
                    
                    DisclosureGroup(
                        isExpanded: $playlistsExpanded,
                        content: {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(favoritePosts) { post in
                                        Button {
                                            navigationPath.append(AppNavigationDestination.post(post))
                                        } label: {
                                            if let url = URL(string: post.albumImageUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(width: 140.0, height: 140.0)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                navigationPath = NavigationPath()
                                navigationPath.append(AppNavigationDestination.likesGrid(favoritePosts))  // いいねした投稿のグリッド画面へ遷移
                            } label: {
                                Text("いいね")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .overlay(
                                        fontGradient
                                            .mask(
                                                Text("いいね")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                            )
                                    )
                            }
                        }
                    )
                    Spacer()
                    
                    // 好きなアーティスト
                    
                    DisclosureGroup(
                        isExpanded: $artistsExpanded,
                        content: {
                            ScrollView(.horizontal) {
                                LazyHStack {    // 好きなアーティスト
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
                                navigationPath = NavigationPath()
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
        .onAppear() {
            Task {
                                do {
                                    await loadUserProfile()
                                    favoriteArtists = try await spotifyManager.getLikeArtists()
                                    //print("👀favoriteArtists: \(favoriteArtists)")
                                    try await saveArtist()
                                    // フォロー/フォロワーデータを読み込む
                                    if let userId = Auth.auth().currentUser?.uid {
                                        await socialViewModel.loadFollowData(for: userId)
                                    }
                                } catch {
                                    print("Error fetching artists: \(error)")
                                }
            }
        }
    }
    
    private func loadUserProfile() async {
        do {
            let userProfile = try await authViewModel.getUserProfile()
            
            // UIの更新
            await MainActor.run {
                self.userProfile = userProfile
            }
            
            // プロフィール画像の取得
            if let imageURLString = userProfile.profileImageURL,
               let imageURL = URL(string: imageURLString) {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                    }
                }
            }
            
            // 投稿を取得
            try await postViewModel.getUsersPost(for: userProfile.id)
            
            // 投稿を保存
            await MainActor.run {
                self.myPosts = postViewModel.posts
            }
            
            // いいねした投稿を取得
            try await favoritePosts = postViewModel.getPostForPostId(postIds: userProfile.favoritePosts ?? [""])
            
        } catch {
            print("Error loading profile: \(error.localizedDescription)")
        }
    }
    
    // firebaseに好きなアーティストを保存、更新
    private func saveArtist() async throws {
        let favoriteArtistsManager = FavoriteArtistsManager()
        try await favoriteArtistsManager.saveFavoriteArtists(userId: userProfile.id, artists: favoriteArtists)
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

//#Preview {
//    ProfileView(navigationPath: .constant(NavigationPath()))
//}
