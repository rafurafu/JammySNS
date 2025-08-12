//
//  TestView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/09/06.
//

import SwiftUI
import SpotifyiOS

struct SpotifyAuthView: View {
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    //@StateObject private var spotifyManager = SpotifyMusicManager()
    
    let gradientColors = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49)  // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ZStack {
            // 白背景
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()  // 上部のスペース
                
                VStack(spacing: 40) {
                    Text("Jammy")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(gradientColors)
                        .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    // Spotify認証ボタン
                    Button(action: {
                        spotifyManager.authorize()
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Spotifyと接続")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(gradientColors)
                        .cornerRadius(30)
                        .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .sheet(isPresented: $spotifyManager.showingSafariView, content: {
                        if let url = spotifyManager.authURL {
                            SafariView(url: url)
                        }
                    })
                }
                
                Spacer()  // 下部のスペース
            }
        }
    }
}


// プレビュー用のコード
#Preview {
    SpotifyAuthView()
}
