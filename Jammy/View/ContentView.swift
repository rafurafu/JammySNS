import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @State private var isSliderVisible = true
    @State private var targetPopularity: Double = 0.0
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State var navigationPath: NavigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $selection) {
                    NavigationStack(path: $navigationPath) {
                        MainView(navigationPath: $navigationPath)
                            .environmentObject(blockViewModel)
                            .environmentObject(spotifyManager)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .navigationDestination(for: AppNavigationDestination.self) { destination in
                                switch destination {
                                case .profile(let userProfile):
                                    OtherProfileView(navigationPath: $navigationPath, userId: userProfile.id)
                                case .selfProfile:
                                    ProfileView(navigationPath: $navigationPath)
                                        .environmentObject(spotifyManager)
                                        .environmentObject(blockViewModel)
                                case .postsGrid(let userInfo):
                                    ProfileGridPostView(navigationPath: $navigationPath, postUserInfo: userInfo)
                                case .post(let post):
                                    ProfilePostView(post: post)
                                case .playlist(let playlists, let currentTrack):
                                    MainPlaylistView(playlists: playlists, currentTrack: currentTrack)
                                case .artist(let artists):
                                    ProfileGridArtistView(navigationPath: $navigationPath, artistInfo: artists)
                                case .likesGrid(let posts):
                                    ProfileGridLikesView(navigationPath: $navigationPath, likePosts: posts)
                                case .report(let userId, let postId):
                                     ReportView(reportedUserId: userId, postId: postId)
                                default:
                                    EmptyView()
                                }
                            }
                    }
                    .tabItem {
                        Image(systemName: "house.fill")
                    }
                    .tag(0)
                    
                    SearchView() // 追加
                        .environmentObject(spotifyManager)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                        }
                        .tag(1)
                    
                    PostView(selection: $selection)
                        .tabItem {
                            Image(systemName: "paperplane.fill")
                        }
                        .tag(2)
                    
                    NavigationStack {
                        ProfileView(navigationPath: $navigationPath)
                            .environmentObject(spotifyManager)
                            .environmentObject(blockViewModel)
                    }
                    .tabItem {
                        Image(systemName: "person.fill")
                    }
                    .tag(3)
                }
                .tint(Color(red: 1.0, green: 0.41, blue: 0.71))
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
        }
        .task {
            if spotifyManager.hasValidToken {
                await spotifyManager.attemptTokenRefresh()
                await spotifyManager.updateUserProfile()
            }
        }
    }
}
