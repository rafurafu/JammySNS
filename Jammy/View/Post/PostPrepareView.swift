//
//  PostVerticalView.swift
//  Jammy
//
//  Created by yokoyama musashi on 2024/06/18.
//

import Foundation
import SwiftUI

struct PostPrepareView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State private var inputText = ""
    @State var UploadAlert: Bool = false
    @State private var backgroundColor: Color = .clear
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @FocusState var keybordFocus: Bool
    @Binding var currentTrackInfo: TrackInfo
    @Binding var hasSongData: Bool
    @Binding var selection: Int
    @State private var showError = false    // 投稿エラーのアラート
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack (alignment: .center) {
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                                .shadow(radius: 10, x: 5, y: 5)
                                .frame(width:geometry.size.width-40.0, height: 450)
                                .foregroundColor(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
                                .padding(.top, 20)
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
                                
                                VStack(spacing: 15, content: {
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
                                    
                                    Button(action: {
                                        UploadAlert = true
                                    }, label: {
                                        Text("投稿")
                                            .font(.system(size: 40, weight: .light, design: .rounded))
                                            .foregroundColor(Color.purple)
                                            .overlay(
                                                fontColor
                                                    .mask(
                                                        Text("投稿")
                                                            .fontWeight(.light)
                                                            .font(.system(size: 40, weight: .black, design: .rounded))
                                                    )
                                                    .alert(isPresented: $UploadAlert) {
                                                        Alert(title: Text("この内容で投稿しますか？"),
                                                              primaryButton: .default(Text("投稿する"), action: {
                                                            Task {
                                                                do {
                                                                    let postViewModel = PostViewModel()
                                                                    
                                                                    await MainActor.run {
                                                                        postViewModel.postTrack(
                                                                            trackInfo: currentTrackInfo,
                                                                            postComment: inputText
                                                                        )
                                                                        hasSongData = false
                                                                        selection = 0
                                                                    }
                                                                } catch {
                                                                    await MainActor.run {
                                                                        errorMessage = error.localizedDescription
                                                                        showError = true
                                                                    }
                                                                }
                                                            }
                                                        }),
                                                              secondaryButton: .cancel(Text("やめておく"), action:{})
                                                        )
                                                    }
                                                    .alert("エラー", isPresented: $showError) {
                                                        Button("OK", role: .cancel) { }
                                                    } message: {
                                                        Text(errorMessage)
                                                    }
                                            )})
                                    .frame(width:geometry.size.width - 40.0)
                                })
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        
                        ZStack (alignment: .trailing){
                            TextEditor(text: $inputText)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(Color.black)
                                .lineSpacing(5)
                                .frame(width:geometry.size.width - 30, height: 120)
                                .padding(0.3)
                                .background(Color.secondary)
                                .shadow(color: Color.gray.opacity(0.1), radius: 10, x: 2, y: 2)
                                .padding(10)
                                .focused(self.$keybordFocus)
                                .lineLimit(3)
                                .minimumScaleFactor(0.1)
                                .autocorrectionDisabled(true)
                                .overlay(alignment: .center) {
                                    if inputText.isEmpty {
                                        Text("ここにコメントを入力してね！")
                                            .foregroundColor(Color(uiColor: .placeholderText))
                                            .padding(6)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.1)
                                    }
                                }
                            
                            if keybordFocus == false {
                                Button(action: {
                                    keybordFocus = true
                                }, label: {
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.7, green: 0.7, blue: 0.7))
                                        .frame(width: 30)
                                        .padding(.trailing, 30)
                                })
                            } else {
                                Button(action: {
                                    keybordFocus = false
                                }, label: {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.7, green: 0.7, blue: 0.7))
                                        .frame(width: 30)
                                        .padding(.trailing, 30)
                                })
                            }
                        }
                    }
                }
                .dismissKeyboardOnTap()
            }
            .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        }
    }
    
}

#Preview {
    PostPrepareView(currentTrackInfo: .constant(TrackInfo()), hasSongData: .constant(true), selection: .constant(2))
}
