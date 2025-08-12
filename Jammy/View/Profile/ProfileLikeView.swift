import SwiftUI

struct ProfileLikeView: View {
    @State private var navigationPath = NavigationPath()
    
    let backGroundColor = Color.white
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @StateObject var postViewModel = PostViewModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @State private var isComment = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backGroundColor
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
                            VStack {
                                Button {
                                    // 投稿詳細への遷移
                                    navigationPath.append(AppNavigationDestination.post(post))
                                } label: {
                                    ProfilePostView(post: post)
                                        .frame(height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom - 150)
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                    }
                    
                    //Spacer()
                }
                .onAppear {
                    postViewModel.getPost()
                }
            }
        }
    }
}

#Preview {
    ProfileLikeView()
}
