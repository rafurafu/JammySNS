//設定画面

import SwiftUI
import FirebaseCore
import FirebaseFirestore

enum DisplayMode: String, CaseIterable {
    case system
    case light
    case dark
    
    var localizedName: String {
        switch self {
        case .system: return "システム設定に従う"
        case .light: return "ライトモード"
        case .dark: return "ダークモード"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "gearshape"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .system: return .gray
        case .light: return .yellow
        case .dark: return .blue
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum PlayingMode: String, CaseIterable {
    case full
    case preview
    
    var localizedName: String {
        switch self {
        case .full: return "Spotifyでフル再生"
        case .preview: return "プレビューのみ"
        }
    }
    
    var iconName: String {
        switch self {
        case .full: return "music.note"
        case .preview: return "waveform"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .full: return .green
        case .preview: return .blue
        }
    }
}

struct SettingView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State private var isContactSyncEnabled: Bool = true
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("displayMode") var displayMode: DisplayMode = .system
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingLogoutAlert = false
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @EnvironmentObject var blockViewModel: BlockViewModel
    
    var currentColorScheme: ColorScheme {
        displayMode == .system ? systemColorScheme : (displayMode == .dark ? .dark : .light)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
                .frame(height: 90)
            
            Text("設定")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            Group {
                VStack(spacing: 1) {
                    NavigationLink(destination: ProfileAccountSettingView()) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                            Text("アカウント")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink(destination: SettingEmailView()) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                            Text("メールアドレス")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink(
                        destination: SettingPrivacyBlockView()
                            .environmentObject(blockViewModel)
                    ) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                            Text("ブロックしたユーザー")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink {
                        List {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    displayMode = mode
                                }) {
                                    HStack {
                                        Image(systemName: mode.iconName)
                                            .foregroundColor(mode.iconColor)
                                        
                                        Text(mode.localizedName)
                                            .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                                        
                                        Spacer()
                                        
                                        if displayMode == mode {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTitle("外観モード")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Image(systemName: "moon")
                                .foregroundColor(.yellow)
                            Text("外観モード")
                            Spacer()
                            Text(displayMode.localizedName)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink {
                        List {
                            ForEach(PlayingMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    if mode == .preview {
                                        spotifyManager.isPreview = true
                                    } else {
                                        spotifyManager.isPreview = false
                                    }
                                })
                                {
                                    HStack {
                                        Image(systemName: mode.iconName)
                                            .foregroundColor(mode.iconColor)
                                        
                                        Text(mode.localizedName)
                                            .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                                        
                                        Spacer()
                                        
                                        if spotifyManager.isPreview == (mode == .preview) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .disabled(mode == .full && (!spotifyManager.isSpotifyInstalled || spotifyManager.isPremiumUser == false))
                                .opacity(mode == .full && (!spotifyManager.isSpotifyInstalled || spotifyManager.isPremiumUser == false) ? 0.5 : 1.0)
                            }
                        }
                        .navigationTitle("再生方法")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Image(systemName: "play.circle")
                                .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
                            Text("再生方法")
                            Spacer()
                            Text(spotifyManager.isPreview ? "プレビューのみ" : "フル再生")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                }
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                VStack(spacing: 1) {
                    NavigationLink(destination: SettingPolicyView()) {
                        HStack {
                            Text("ポリシー")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink(destination: SettingServiceView()) {
                        HStack {
                            Text("利用規約")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink(destination: SpotifyAuthView()
                        .onOpenURL(perform: { url in
                        Task {
                            spotifyManager.handleAuthCallback(url: url)
                        }
                    })
                    ) {
                        HStack {
                            Text("spotifyアカウントを再連携")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    NavigationLink(destination: SettingdeleteView()) {
                        HStack {
                            Text("アカウントを削除")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Text("ログアウト")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                    }
                    .alert(isPresented: $showingLogoutAlert) {
                        Alert(
                            title: Text("ログアウト"),
                            message: Text("本当にログアウトしますか？"),
                            primaryButton: .destructive(Text("ログアウト")) {
                                viewModel.signOut()
                                spotifyManager.logout()
                            },
                            secondaryButton: .cancel(Text("キャンセル"))
                        )
                    }
                }
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .foregroundColor(currentColorScheme == .dark ? Color.white : Color.black)
            .font(.headline)
            .fontWeight(.medium)
        }
        .background(currentColorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
        .preferredColorScheme(displayMode.colorScheme)
    }
}

#Preview {
    SettingView()
        .environmentObject(SpotifyMusicManager())
}
