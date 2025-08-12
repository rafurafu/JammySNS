import Foundation
import SwiftUI
import UIKit

struct PostRemainderView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State private var inputText = ""
    @State var UploadAlert: Bool = false
    @State var musicTimeSlider: Double = 0.3
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    let postViewModel = PostViewModel()
    @Binding var currentTrackInfo: TrackInfo
    //@State private var isListenMusic: Bool = false
    @Binding var hasSongData: Bool
    @Binding var selection: Int
    
    var body: some View {
        //NavigationStack {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    
                    Text("今聴いている曲を共有しよう")
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .foregroundStyle(fontColor)

                
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                            .shadow(radius: 10, x: 5, y: 5)
                            .frame(width:geometry.size.width-40.0, height: 400)
                            .foregroundColor(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
                            .padding(.top, 30)
                        VStack {
                            if let imageUrlString = currentTrackInfo.item.album.images.first?.url,
                               let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 250.0, height: 250.0)
                                        .padding(.top, 50)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 250.0, height: 250.0)
                                        .padding(.top, 50)
                                }
                            } else {
                                Text("画像が見つかりませんでした")
                            }
                            HStack(spacing: 10) {
                                VStack(spacing: 15) {
                                    Text(currentTrackInfo.item.name)
                                        .font(.system(.title, design: .rounded))
                                        .fontWeight(.medium)
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                        .frame(height: 40)
                                        .frame(alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.1)
                                    
                                    
                                    Text(currentTrackInfo.item.artists.first?.name ?? "")
                                        .font(.system(.title3, design: .default))
                                        .fontWeight(.medium)
                                        .frame(height: 20)
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.1)
                                }
                                .padding(.leading, 40)
                                
                                Button {
                                    Task {
                                        currentTrackInfo = try await postViewModel.fetchCurrentlyPlayingTrack(accessToken: spotifyManager.accessToken)
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 35)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                    
                    
                    HStack {
                        Button(action: {
                            openSpotify()
                        }, label: {
                            Image("Spotify Logo Green")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150.0, height: 80.0)
                                .padding(.horizontal, 10)
                                .background(.white)
                                .cornerRadius(20)
                                .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                        })
                        
                        Button(action: {
                            Task {
                                do {
                                    if currentTrackInfo.item.id == "" {
                                        let alert = ShowAlert()
                                        alert.showOKAlert(title: "曲が見つかりませんでした", message: "Spotifyで音楽を再生して、更新ボタンを押してください！")
                                        hasSongData = false
                                    } else {

                                        hasSongData = true
                                    }
                                } catch {
                                    print("musicInfoエラー: \(error.localizedDescription)")
                                }
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("投稿")
                            }
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 150.0, height: 80.0)
                            .padding(.horizontal, 10)
                            .background(fontColor)
                            .cornerRadius(20)
                            .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                        })
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                currentTrackInfo = try await postViewModel.fetchCurrentlyPlayingTrack(accessToken: spotifyManager.accessToken)
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        //}
    }
    
    func openSpotify() {
        let spotifyURL = URL(string: "spotify://")!
        let spotifyAppStoreURL = URL(string: "https://apps.apple.com/app/spotify/id324684580")!
        
        if UIApplication.shared.canOpenURL(spotifyURL) {
            UIApplication.shared.open(spotifyURL, options: [:]) { success in
            }
        } else {
            UIApplication.shared.open(spotifyAppStoreURL, options: [:]) { success in
            }
        }
    }
}


#Preview {
    PostRemainderView(currentTrackInfo:.constant(TrackInfo()), hasSongData: .constant(false), selection: .constant(1))
}
