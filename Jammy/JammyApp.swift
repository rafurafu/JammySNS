//
//  JammyApp.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/05/10.
//

import SwiftUI
import SpotifyiOS

@main
struct JammyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authViewModel = AuthViewModel()
    @StateObject private var spotifyManager = SpotifyMusicManager()
    @StateObject private var termsViewModel = TermsViewModel()
    @StateObject private var blockViewModel = BlockViewModel()
    @State var recommendSettings = RecommendSettings(targetPopularity: 0, valence: 0, energy: 0, minTempo: 0, selectedGenres: ["j-pop"])
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !authViewModel.isAuthenticated {
                    // Step 1: 認証前の初期画面
                    StartView(viewModel: authViewModel)
                        .environmentObject(authViewModel)
                } else if !termsViewModel.hasAgreedToTerms {
                    // Step 2: 利用規約同意画面
                    SettingServiceView()
                        .environmentObject(termsViewModel)
                } else if !authViewModel.decidedUserName {
                    // Step 3: ユーザー名設定画面
                    StartSettingView(viewModel: authViewModel)
                        .environmentObject(authViewModel)
                } else if !spotifyManager.hasValidToken {
                    // Step 4: Spotify認証画面
                    SpotifyAuthView()
                        .environmentObject(spotifyManager)
                        .onOpenURL(perform: { url in
                            Task {
                                spotifyManager.handleAuthCallback(url: url)
                            }
                        })
                } else {
                    // Step 5: メインコンテンツ
                    ContentView()
                        .environmentObject(spotifyManager)
                        .environmentObject(authViewModel)
                        .environmentObject(blockViewModel)
                }
            }
        }
    }
}
