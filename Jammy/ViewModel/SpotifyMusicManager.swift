//
//  SpotifyAuthManager.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/09/09.
//

import SwiftUI
import SpotifyiOS
import CommonCrypto
import AVFoundation
import SwiftKeychainWrapper
import UIKit

class SpotifyMusicManager: NSObject, ObservableObject {
    
    enum SpotifyAuthError: Error {
        case codeChallengeFailed
        case urlCreationFailed
        case noAccessToken
        case networkError(Error)
    }
    
    // エラー定義の更新
    enum SpotifyPlaybackError: Error {
        case previewNotAvailable    //
        case premiumRequired    //
        case noDevicesAvailable // デバイスが見つからない
        case deviceActivationFailed // デバイスが見つからない
        case playbackFailed(Int, String) // 再生開始に失敗（ステータスコード, エラーメッセージ）
        case networkError(Error)    // ネットワークエラー
    }
    // Spotifyのエラーレスポンス用の構造体
    struct SpotifyErrorResponse: Codable {
        struct ErrorDetail: Codable {
            let status: Int
            let message: String
            let reason: String?
        }
        let error: ErrorDetail
    }
    @Published var hasValidToken: Bool = false
    private let keychainService = "com.your.app.spotify"
    private let accessTokenKey = "spotifyAccessToken"
    private let refreshTokenKey = "spotifyRefreshToken"
    private let tokenExpirationKey = "spotifyTokenExpiration"
    
    @Published var accessToken: String = ""
    @Published var refreshToken: String = ""
    @Published var isAuthorized = false
    @Published private var tokenExpiration: Date?
    @Published var isConnected = false
    @Published var authorizationError: String?
    @Published var connectionAttempts: Int = 0
    @Published var isPremiumUser: Bool? = nil   //　プレミアムに加入しているかどうか
    @Published var isPreview: Bool {    // プレミアムユーザーがプレビューを流すかどうか
        didSet {
            // 設定が変更されたらUserDefaultsに保存
            UserDefaults.standard.set(isPreview, forKey: "SpotifyPlaybackIsPreview")
        }
    }
    @Published var isSpotifyInstalled: Bool = false //　Spotifyアプリがインストールされているか
    @Published var isPlayingPreview: Bool = false
    @Published var authURL: URL? = nil
    @Published var showingSafariView = false
    private var previewPlayer: AVPlayer?
    private let maxConnectionAttempts = 3
    
    // 色キャッシュシステム
    @Published var colorCache: [String: Color] = [:]
    private let colorCacheQueue = DispatchQueue(label: "colorCache", qos: .background)
    private var imageDownloadTasks: [String: Task<Color?, Never>] = [:]
    private let clientID = "e8f692a2d12e4d2699692c38b2c7e1d6"
    private let redirectURI = URL(string: "spotify-ios-quick-start://callback")!
    private let clientSecretID = "98e6b76d2d114c11843da6f2b0400cd1"
    private var isAuthenticating = false
    
    override init() {
        self.isPreview = UserDefaults.standard.bool(forKey: "SpotifyPlaybackIsPreview")
        super.init()
        loadTokensFromKeychain()    //　ローカルからアクセストークン、リフレッシュトークン取得
        checkTokenValidity()    //　トークンのリフレッシュ
        checkSpotifyInstallation()  // Spotifuアプリがインストールされてるか確認
    }
    
    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURI)
        return configuration
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    private lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    // Spotifyアプリのインストール状態をチェック
    private func checkSpotifyInstallation() {
        let spotifyURL = URL(string: "spotify://")!
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isSpotifyInstalled = UIApplication.shared.canOpenURL(spotifyURL)
            
            if !self.isSpotifyInstalled {
                let showAlert = ShowAlert()
                showAlert.showActionAlert(
                    title: "Spotifyがインストールされていません",
                    message: "Spotifyアプリがインストールされていないため、30秒のプレビュー再生のみ利用可能です。フル機能を利用するにはSpotifyアプリをインストールしてください。",
                    primaryButton: .default(title: "Spotifyをインストール") {
                        Task {
                            if let url = URL(string: "https://apps.apple.com/app/spotify/id324684580") {
                                await UIApplication.shared.open(url)
                                
                                // インストール後の確認は少し待ってから行う
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                                await MainActor.run {
                                    self.isSpotifyInstalled = UIApplication.shared.canOpenURL(spotifyURL)
                                    if self.isSpotifyInstalled {
                                        // インストールが確認できた場合の処理
                                        self.isPremiumUser = nil  // 改めて認証プロセスを開始
                                        self.authorize()  // 必要に応じて認証を開始
                                    }
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(title: "そのまま続行") {
                        self.isPremiumUser = false
                    }
                )
            }
        }
    }
    
    // Spotify接続
    func connect() {
        guard !appRemote.isConnected else {
            self.isAuthorized = true
            return
        }
        
        // Spotifyインストール済みの場合
        if isSpotifyInstalled {
            // Spotifyアプリがインストールされている場合の通常の接続フロー
            if !self.isAuthorized && !self.accessToken.isEmpty {
                connectionAttempts += 1
                
                if connectionAttempts > maxConnectionAttempts {
                    let showAlert = ShowAlert()
                    showAlert.showOKAlert(title: "Spotifyと接続できませんでした。", message: "Spotifyアカウントが存在することを確認して、もう一度お試しください。")
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.appRemote.connect()
                }
            } else {
            }
        } else {
            // Spotifyアプリがインストールされていない場合
            self.isAuthorized = true  // プレビュー再生用に認証状態を許可
            self.isPremiumUser = false // フリープラン扱いとする
        }
    }
    
    private func handleConnectionError(_ message: String) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.authorizationError = message
            self.showErrorAlert(message: message)
        }
    }
    
    // Spotify認証
    func authorize() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        // Spotifyインストール済みの認証処理
        if isSpotifyInstalled {
            do {
                let codeVerifier = generateCodeVerifier()
                guard let codeChallenge = generateCodeChallenge(from: codeVerifier) else {
                    throw SpotifyAuthError.codeChallengeFailed
                }
                
                UserDefaults.standard.set(codeVerifier, forKey: "codeVerifier")
                
                let clientID = "e8f692a2d12e4d2699692c38b2c7e1d6"
                let redirectURI = "spotify-ios-quick-start://callback"
                let scope = "user-read-private user-read-email user-modify-playback-state user-read-playback-state app-remote-control user-top-read playlist-modify-public playlist-modify-private user-follow-read playlist-read-collaborative playlist-read-private user-read-playback-position user-library-read"
                
                let authURL = "https://accounts.spotify.com/authorize" +
                "?response_type=code" +
                "&client_id=\(clientID)" +
                "&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" +
                "&redirect_uri=\(redirectURI)" +
                "&code_challenge_method=S256" +
                "&code_challenge=\(codeChallenge)"
                
                guard let url = URL(string: authURL) else {
                    throw SpotifyAuthError.urlCreationFailed
                }
                
                // URLを保存してSafariViewを表示するフラグを設定
                DispatchQueue.main.async {
                    self.authURL = url
                    self.showingSafariView = true
                }
            } catch {
                handleAuthorizationError(error)
            }
        } else {
            //　Spotifyインストールしていない場合
            DispatchQueue.main.async {
                self.isAuthorized = true
                self.isPremiumUser = false
                self.isAuthenticating = false
                
                let showAlert = ShowAlert()
                showAlert.showActionAlert(
                    title: "プレビューモードで続行",
                    message: "Spotifyアプリがインストールされていないため、30秒のプレビュー再生のみ利用可能です。フル機能を利用するにはSpotifyアプリをインストールしてください。",
                    primaryButton: .default(title: "Spotifyをインストール") {
                        if let url = URL(string: "https://apps.apple.com/app/spotify/id324684580") {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(title: "プレビューモードで続行") { [self] in
                        do {
                            let codeVerifier = self.generateCodeVerifier()
                            guard let codeChallenge = generateCodeChallenge(from: codeVerifier) else {
                                throw SpotifyAuthError.codeChallengeFailed
                            }
                            
                            UserDefaults.standard.set(codeVerifier, forKey: "codeVerifier")
                            
                            let clientID = "e8f692a2d12e4d2699692c38b2c7e1d6"
                            let redirectURI = "spotify-ios-quick-start://callback"
                            let scope = "user-read-private user-read-email user-modify-playback-state user-read-playback-state app-remote-control user-top-read playlist-modify-public playlist-modify-private user-follow-read playlist-read-collaborative playlist-read-private user-read-playback-position user-library-read"
                            
                            let authURL = "https://accounts.spotify.com/authorize" +
                            "?response_type=code" +
                            "&client_id=\(clientID)" +
                            "&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" +
                            "&redirect_uri=\(redirectURI)" +
                            "&code_challenge_method=S256" +
                            "&code_challenge=\(codeChallenge)"
                            
                            guard let url = URL(string: authURL) else {
                                throw SpotifyAuthError.urlCreationFailed
                            }
                            
                            // URLを保存してSafariViewを表示するフラグを設定
                            DispatchQueue.main.async {
                                self.authURL = url
                                self.showingSafariView = true
                            }
                        } catch {
                            handleAuthorizationError(error)
                        }
                    }
                )
            }
        }
    }
    
    // アプリに帰ってきた際にアクセストークンを取り出す処理へ
    func handleAuthCallback(url: URL) {
        guard let parameters = appRemote.authorizationParameters(from: url),
              let code = parameters["code"] else {
            handleAuthorizationError(SpotifyAuthError.noAccessToken)
            return
        }
        self.hasValidToken = true
        exchangeCodeForAccessToken(with: code)
        sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    private func handleAuthorizationError(_ error: Error) {
        isAuthenticating = false
        let message: String
        switch error {
        case SpotifyAuthError.codeChallengeFailed:
            message = "認証の準備中にエラーが発生しました。再度お試しください。"
        case SpotifyAuthError.urlCreationFailed:
            message = "認証URLの作成に失敗しました。ネットワーク接続を確認してください。"
        case SpotifyAuthError.noAccessToken:
            message = "アクセストークンの取得に失敗しました。Spotifyアプリが最新版かご確認ください。"
        case let SpotifyAuthError.networkError(networkError):
            message = "ネットワークエラーが発生しました: \(networkError.localizedDescription)"
        default:
            message = "予期せぬエラーが発生しました: \(error.localizedDescription)"
        }
        
        DispatchQueue.main.async {
            self.authorizationError = message
            self.showErrorAlert(message: message)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "認証エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "再試行", style: .default, handler: { [weak self] _ in
            self?.authorize()
        }))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    // Keychainへのトークンの保存
    private func saveTokensToKeychain(accessToken: String, refreshToken: String, expiresIn: Int) {
        let keychain = KeychainWrapper.standard
        keychain.set(accessToken, forKey: accessTokenKey)
        keychain.set(refreshToken, forKey: refreshTokenKey)
        
        // 有効期限をタイムスタンプとして保存
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        keychain.set(expirationDate.timeIntervalSince1970, forKey: tokenExpirationKey)
        
        DispatchQueue.main.async {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.hasValidToken = true
            self.isAuthorized = true
        }
    }
    
    
    // Keychainからトークンの読み込み
    private func loadTokensFromKeychain() {
        let keychain = KeychainWrapper.standard
        if let accessToken = keychain.string(forKey: accessTokenKey),
           let refreshToken = keychain.string(forKey: refreshTokenKey) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.isAuthorized = true
        }
    }
    
    // トークンの有効性チェック
    private func checkTokenValidity() {
        let keychain = KeychainWrapper.standard
        if let expirationTimeInterval = keychain.double(forKey: tokenExpirationKey) {
            let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
            // 期限切れの1分前にリフレッシュするように
            hasValidToken = Date().addingTimeInterval(60) < expirationDate
        } else {
            hasValidToken = false
        }
    }
    
    // トークンの自動リフレッシュを試みる
    func attemptTokenRefresh() async {
        guard !refreshToken.isEmpty else { return }
        
        do {
            try await refreshAccessToken()
            await MainActor.run {
                self.hasValidToken = true
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.hasValidToken = false
                self.isAuthorized = false
            }
        }
    }
    
    // exchangeCodeForAccessToken関数
    private func exchangeCodeForAccessToken(with authCode: String) {
        guard let codeVerifier = UserDefaults.standard.string(forKey: "codeVerifier") else {
            return
        }
        
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let credentials = "\(self.clientID):\(self.clientSecretID)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        let requestBody = "grant_type=authorization_code&code=\(authCode)&redirect_uri=\(self.redirectURI)&code_verifier=\(codeVerifier)"
        request.httpBody = requestBody.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.handleAuthorizationError(SpotifyAuthError.networkError(error))
                return
            }
            
            guard let data = data else {
                self?.handleAuthorizationError(SpotifyAuthError.noAccessToken)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String,
                   let expiresIn = json["expires_in"] as? Int {
                    
                    // トークンをKeychainに保存
                    self?.saveTokensToKeychain(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: expiresIn
                    )
                    
                    DispatchQueue.main.async {
                        self?.appRemote.connectionParameters.accessToken = accessToken
                        self?.isAuthorized = true
                        self?.hasValidToken = true
                        self?.isAuthenticating = false
                        self?.connect()
                        
                        // ユーザー情報を取得して処理
                        Task {
                            do {
                                if let userProfile = try await self?.getUserInfo(accessToken: accessToken) {
                                    if self?.isSpotifyInstalled == true {
                                        let isPremium = userProfile.product.lowercased() == "premium"
                                        self?.isPremiumUser = isPremium // Spotifyがインストールされていて、プレミアムユーザーの場合isPremiumUserをtrueに
                                    }
                                }
                            } catch {
                                print("Failed to get user info: \(error)")
                            }
                        }
                    }
                } else {
                    self?.handleAuthorizationError(SpotifyAuthError.noAccessToken)
                }
            } catch {
                self?.handleAuthorizationError(SpotifyAuthError.networkError(error))
            }
        }
        
        task.resume()
    }
    
    // リフレッシュトークンを使用してアクセストークンを更新
    private func refreshAccessToken() async throws {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let credentials = "\(self.clientID):\(self.clientSecretID)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        let requestBody = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = requestBody.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyAuthError.noAccessToken
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let newAccessToken = json["access_token"] as? String,
           let expiresIn = json["expires_in"] as? Int {
            
            // 新しいリフレッシュトークンが含まれている場合は更新
            let newRefreshToken = (json["refresh_token"] as? String) ?? refreshToken
            
            await MainActor.run {
                self.saveTokensToKeychain(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    expiresIn: expiresIn
                )
                self.appRemote.connectionParameters.accessToken = newAccessToken
            }
        } else {
            throw SpotifyAuthError.noAccessToken
        }
    }
    
    // ランダムなcode_verifierを生成
    func generateCodeVerifier() -> String {
        let length = 128
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    // code_challengeを生成（SHA256ハッシュをBase64でURLエンコード）
    func generateCodeChallenge(from verifier: String) -> String? {
        guard let verifierData = verifier.data(using: .utf8) else { return nil }
        
        // SHA256でハッシュ化
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        verifierData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(verifierData.count), &digest)
        }
        
        let challengeData = Data(digest)
        
        // Base64 URLエンコードを適用
        return challengeData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")  // "+"を"-"に変換
            .replacingOccurrences(of: "/", with: "_")  // "/"を"_"に変換
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))  // "="を削除
    }
    
    func logout() {
        // KeyChainからトークン情報を削除
        let keychain = KeychainWrapper.standard
        keychain.removeObject(forKey: accessTokenKey)
        keychain.removeObject(forKey: refreshTokenKey)
        keychain.removeObject(forKey: tokenExpirationKey)
        
        // UserDefaultsからcode verifierを削除
        UserDefaults.standard.removeObject(forKey: "codeVerifier")
        UserDefaults.standard.removeObject(forKey: "hasAgreedToTerms")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userSettings")
        
        // プロパティをリセット
        DispatchQueue.main.async {
            self.accessToken = ""
            self.refreshToken = ""
            self.isAuthorized = false
            self.hasValidToken = false
            self.isPremiumUser = nil
            self.isConnected = false
            self.connectionAttempts = 0
            
            // 再認証を開始
            self.authorize()
        }
    }
    
    /*
     ユーザー情報取得
     */
    func getUserInfo(accessToken: String) async throws -> SpotifyUserProfile {
        let userInfoURL = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: userInfoURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 200 {
            let userProfile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
            return userProfile
        } else {
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to get user info"])
        }
    }
    
    /*
     ユーザー情報を更新
     */
    func updateUserProfile() async {
        do {
            if !accessToken.isEmpty {
                let userProfile = try await getUserInfo(accessToken: accessToken)
                let isPremium = userProfile.product.lowercased() == "premium"
                
                await MainActor.run {
                    if isSpotifyInstalled == true {
                        self.isPremiumUser = isPremium  // Spotifyがインストールされていて、プレミアムユーザーの場合isPremiumUserをtrueに
                    }
                    if !isPremium {
                        let showAlert = ShowAlert()
                        showAlert.showActionAlert(
                            title: "Freeプランをご利用中です",
                            message: "音楽は30秒のプレビュー再生のみとなります。全曲再生にはSpotifyPremiumプランにアップグレードしてください！",
                            primaryButton: .default(title: "Premiumにアップグレードする") {
                                let spotifyPremiumURL = URL(string: "https://www.spotify.com/premium")!
                                if UIApplication.shared.canOpenURL(spotifyPremiumURL) {
                                    UIApplication.shared.open(spotifyPremiumURL)
                                } else {
                                }
                            },
                            secondaryButton: .cancel(title: "今はしない")
                        )
                    }
                }
            }
        } catch {
            // トークンが無効な場合は再認証が必要
            if let httpError = error as NSError?, httpError.domain == "HTTPError" && httpError.code == 401 {
                await MainActor.run {
                    self.hasValidToken = false
                    self.isAuthorized = false
                }
            }
        }
    }
    
    // Spotifyに登録している情報をデコードする構造体
    struct SpotifyUserProfile: Codable {
        let product: String  // "premium" または "free"
    }
    
    
    //MARK: 音楽再生機能
    func playTrack(accessToken: String, trackURI: String, previewURL: String?, positionMs: Int? = nil) async throws {
        
        // isPremiumUserがnilの場合、ユーザープロファイルを更新
        if isPremiumUser == nil {
            await updateUserProfile()
        }
        
        // プレビュー再生処理
        if !isSpotifyInstalled || isPremiumUser == false || isPreview == true {
            guard let previewURL = previewURL, !previewURL.isEmpty else {
                throw SpotifyPlaybackError.previewNotAvailable
            }
            try await playPreviewTrack(previewURL: previewURL)
            return
        }
        
        //  フル再生処理
        try await playFullTrack(accessToken: accessToken, trackURI: trackURI, positionMs: positionMs)
        
    }
    
    func playFullTrack(accessToken: String, trackURI: String, positionMs: Int? = nil) async throws {
        let maxAttempts = 3 // 失敗した際の試行回数
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                // 再生を試みる
                let url = URL(string: "https://api.spotify.com/v1/me/player/play")!
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var body: [String: Any] = ["uris": [trackURI]]
                if let positionMs = positionMs {
                    body["position_ms"] = positionMs
                }
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SpotifyPlaybackError.networkError(NSError(domain: "InvalidResponse", code: 0))
                }
                
                if httpResponse.statusCode == 204 {
                    return // 成功したら終了
                }
                
                // エラーレスポンスの処理
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                
                if let errorResponse = try? JSONDecoder().decode(SpotifyErrorResponse.self, from: data) {
                    switch httpResponse.statusCode {
                    case 404:
                        DispatchQueue.main.async {
                            self.appRemote.authorizeAndPlayURI("")
                        }
                        if attempt == maxAttempts {  // 最後の試行でのみアラートを表示
                            if let spotifyURL = URL(string: "spotify://") {
                                await MainActor.run {
                                    let showAlert = ShowAlert()
                                    showAlert.showActionAlert(
                                        title: "音楽を再生できませんでした。",
                                        message: "Spotifyを開き、手動で音楽を再生したまま再試行して下さい。",
                                        primaryButton: .default(title: "OK") {
                                            UIApplication.shared.open(spotifyURL)
                                        }
                                    )
                                }
                            }
                            throw SpotifyPlaybackError.noDevicesAvailable
                        } else {
                            // 次の試行の前に待機
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 0.5秒待機
                            continue
                        }
                        
                    case 403:
                        lastError = SpotifyPlaybackError.playbackFailed(403, errorResponse.error.message)
                        
                    default:
                        lastError = SpotifyPlaybackError.playbackFailed(
                            httpResponse.statusCode,
                            errorResponse.error.message
                        )
                    }
                } else {
                    lastError = SpotifyPlaybackError.playbackFailed(
                        httpResponse.statusCode,
                        "申し訳ありません。不明なエラーが発生しました"
                    )
                }
                
                if attempt < maxAttempts {
                    // 次の試行の前に待機
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
                }
                
            } catch {
                lastError = error
                if attempt == maxAttempts {
                    throw error  // 最後の試行で失敗した場合はエラーをスロー
                }
                // 次の試行の前に待機
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        
        // 全ての試行が失敗した場合、最後のエラーをスロー
        if let lastError = lastError {
            throw lastError
        }
    }
    
    private func playPreviewTrack(previewURL: String) async throws {
        await MainActor.run {
            stopPreview() // 既存の再生を停止
            
            if let url = URL(string: previewURL) {
                let playerItem = AVPlayerItem(url: url)
                previewPlayer = AVPlayer(playerItem: playerItem)
                previewPlayer?.play()
                isPlayingPreview = true
                
                // プレビュー終了時の処理
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                       object: playerItem,
                                                       queue: .main) { [weak self] _ in
                    self?.stopPreview()
                }
            }
        }
    }
    
    // プレビュー停止
    func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        isPlayingPreview = false
    }
    
    // Spotifyのプレイヤーステートを表す構造体
    struct PlayerState: Decodable {
        let progress_ms: Int?
    }
    
    /*
     音楽停止
     */
    func stopTrack(accessToken: String) async throws {
        if self.isPreview == false {
            let url = URL(string: "https://api.spotify.com/v1/me/player/pause")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            if httpResponse.statusCode == 204 {
                
            } else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                } else {
                }
            }
        } else {
            stopPreview()
        }
    }
    
    /*
     現在の再生秒数を取得
     */
    func getPlayerProgress() async throws -> Int? {
        let url = URL(string: "https://api.spotify.com/v1/me/player")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        
        do {
            // プレイヤーステートのデコード
            let playerState = try JSONDecoder().decode(PlayerState.self, from: data)
            
            // progress_ms を返す
            if let progressMs = playerState.progress_ms {
                return progressMs
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func seek(to positionMs: Int) async throws {
        let url = URL(string: "https://api.spotify.com/v1/me/player/seek?position_ms=\(positionMs)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    /*
     プレイリスト取得
     */
    func getPlaylist(accessToken: String) async throws -> [PlaylistModel] {
        let playlistURL = URL(string: "https://api.spotify.com/v1/me/playlists/")!
        var request = URLRequest(url: playlistURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTPError", code: 0)
        }
        let playlistResponse = try JSONDecoder().decode(PlaylistResponse.self, from: data)
        return playlistResponse.validItems
    }
    
    /*
     プレイリストにtrackを保存
     */
    func saveTrackToPlaylist(trackUri: String, playlistId: String) async throws {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Bearer トークンの形式を確認
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディをデバッグ出力
        let body: [String: Any] = [
            "uris": [trackUri]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // レスポンスの詳細をデバッグ出力
        
        switch httpResponse.statusCode {
        case 201, 200:  // 200も成功として扱う
            await MainActor.run {
                let showAlert = ShowAlert()
                showAlert.showOKAlert(
                    title: "保存完了！",
                    message: "プレイリストに音楽を追加しました。"
                )
            }
            
        case 400:
            // 認証エラーの詳細を解析
            struct SpotifyError: Codable {
                let error: ErrorDetails
                struct ErrorDetails: Codable {
                    let status: Int
                    let message: String
                }
            }
            
            let errorResponse = try JSONDecoder().decode(SpotifyError.self, from: data)
            throw NSError(
                domain: "AuthenticationError",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message]
            )
            
        case 401:
            // アクセストークンの再取得が必要
            throw NSError(
                domain: "AuthenticationError",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Access token expired. Please authenticate again."]
            )
            
        case 403:
            throw NSError(
                domain: "AuthorizationError",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "You don't have permission to modify this playlist"]
            )
            
        case 404:
            throw NSError(
                domain: "NotFoundError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Playlist not found"]
            )
            
        default:
            throw NSError(
                domain: "UnknownError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed to add track to playlist"]
            )
        }
    }
    
    /*
     　好きなアーティストを取得
     */
    
    func getLikeArtists() async throws -> [FavoriteArtist] {  // 戻り値の型を変更
        let likedArtistsURL = URL(string: "https://api.spotify.com/v1/me/following?type=artist")!
        var request = URLRequest(url: likedArtistsURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyAuthError.networkError(NSError(domain: "InvalidResponse", code: 0))
        }
        
        // エラーレスポンスの処理
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(SpotifyErrorResponse.self, from: data) {
                throw SpotifyPlaybackError.playbackFailed(
                    httpResponse.statusCode,
                    errorResponse.error.message
                )
            } else {
                throw SpotifyAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
        }
        
        // デバッグ用
        
        // レスポンスをデコード
        let artistsResponse = try JSONDecoder().decode(LikeArtistsModel.self, from: data)
        
        // SpotifyのアーティストモデルをFavoriteArtistに変換
        return artistsResponse.artists.items.map { artist in
            FavoriteArtist(
                id: artist.id,
                name: artist.name,
                imageUrl: artist.images.first?.url ?? "",
                uri: artist.uri,
                genres: artist.genres
            )
        }
    }
    
    // プレイリストを取得
    enum PlaylistError: Error {
        case invalidResponse(statusCode: Int)
        case invalidData
        case networkError(Error)
    }
    
    private func fetchPlaylist(id: String) async throws -> [PlaylistModel] {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // レスポンスの詳細なログ
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaylistError.invalidResponse(statusCode: 0)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlaylistError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            // JSONデコードを試みる前にデータの中身を確認
            
            do {
                let playlistResponse = try JSONDecoder().decode(PlaylistResponse.self, from: data)
                return playlistResponse.validItems
            } catch {
                throw PlaylistError.invalidData
            }
        } catch let error as DecodingError {
            throw PlaylistError.invalidData
        } catch {
            throw PlaylistError.networkError(error)
        }
    }

    func getTopPlaylist() async throws -> (japan: [PlaylistModel], global: [PlaylistModel]) {
       // let japanTop50Id = "3cEYpjA9oz9GiPac4AsH4n"
        let japanTop50Id = "37i9dQZEVXbKXQ4mDTEBXq"
        let globalTop50Id = "37i9dQZEVXbNG2KDcFcKOF"
        
        async let japanPlaylist = fetchPlaylist(id: japanTop50Id)
        async let globalPlaylist = fetchPlaylist(id: globalTop50Id)
        
        return try await (japan: japanPlaylist, global: globalPlaylist)
    }
    
    // MARK: - 色抽出機能
    
    /// アルバムアートワークから主要色を抽出（パフォーマンス最適化版）
    func getAlbumDominantColor(for trackId: String, imageURL: String) -> Color {
        // すでにキャッシュされている場合は即座に返す
        if let cachedColor = colorCache[trackId] {
            print("キャッシュから色取得: \(trackId) -> \(cachedColor)")
            return cachedColor
        }
        
        // バックグラウンドで色抽出を開始
        if imageDownloadTasks[trackId] == nil {
            print("色抽出開始: \(trackId) - \(imageURL)")
            imageDownloadTasks[trackId] = Task {
                await extractAndCacheColor(trackId: trackId, imageURL: imageURL)
            }
        }
        
        // デフォルト色を返す（非同期で色が更新される）
        return Color.gray.opacity(0.3)
    }
    
    /// アルバムアートワークから色を抽出してキャッシュに保存
    private func extractAndCacheColor(trackId: String, imageURL: String) async -> Color? {
        guard let url = URL(string: imageURL) else { return nil }
        
        do {
            // 画像をダウンロード
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return nil }
            
            // 軽量化された画像で色抽出（パフォーマンス向上）
            let resizedImage = resizeImage(uiImage, to: CGSize(width: 50, height: 50))
            let dominantColor = extractDominantColor(from: resizedImage)
            
            // メインスレッドでキャッシュを更新
            await MainActor.run {
                print("色抽出成功: \(trackId) -> \(dominantColor)")
                colorCache[trackId] = dominantColor
                imageDownloadTasks.removeValue(forKey: trackId)
            }
            
            return dominantColor
        } catch {
            print("色抽出エラー: \(error)")
            await MainActor.run {
                imageDownloadTasks.removeValue(forKey: trackId)
            }
            return nil
        }
    }
    
    /// 画像をリサイズ（パフォーマンス向上のため）
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /// 画像から主要色を抽出
    private func extractDominantColor(from image: UIImage) -> Color {
        guard let cgImage = image.cgImage else { return Color.gray }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: height * width * bytesPerPixel)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 色の統計を取る（サンプリングで高速化）
        var redTotal: Int = 0
        var greenTotal: Int = 0
        var blueTotal: Int = 0
        var sampleCount: Int = 0
        
        // 10x10のグリッドでサンプリング（パフォーマンス向上）
        let sampleStep = max(1, min(width, height) / 10)
        
        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in stride(from: 0, to: width, by: sampleStep) {
                let pixelIndex = (y * width + x) * bytesPerPixel
                
                if pixelIndex + 2 < pixelData.count {
                    let red = Int(pixelData[pixelIndex])
                    let green = Int(pixelData[pixelIndex + 1])
                    let blue = Int(pixelData[pixelIndex + 2])
                    
                    // 極端に暗い・明るい色をスキップ
                    let brightness = (red + green + blue) / 3
                    if brightness > 30 && brightness < 220 {
                        redTotal += red
                        greenTotal += green
                        blueTotal += blue
                        sampleCount += 1
                    }
                }
            }
        }
        
        guard sampleCount > 0 else { return Color.gray }
        
        let avgRed = Double(redTotal) / Double(sampleCount) / 255.0
        let avgGreen = Double(greenTotal) / Double(sampleCount) / 255.0
        let avgBlue = Double(blueTotal) / Double(sampleCount) / 255.0
        
        // 彩度を調整してSpotifyライクな色に
        let adjustedColor = adjustColorSaturation(
            red: avgRed,
            green: avgGreen,
            blue: avgBlue
        )
        
        return adjustedColor
    }
    
    /// 彩度を調整してより魅力的な色に
    private func adjustColorSaturation(red: Double, green: Double, blue: Double) -> Color {
        // HSBに変換
        let max = Swift.max(red, green, blue)
        let min = Swift.min(red, green, blue)
        let delta = max - min
        
        var hue: Double = 0
        let brightness = max
        let saturation = max == 0 ? 0 : delta / max
        
        if delta != 0 {
            if max == red {
                hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if max == green {
                hue = (blue - red) / delta + 2
            } else {
                hue = (red - green) / delta + 4
            }
            hue *= 60
            if hue < 0 { hue += 360 }
        }
        
        // 彩度を適度に調整（Spotifyライクに）
        let adjustedSaturation = Swift.min(1.0, saturation * 1.2)
        let adjustedBrightness = Swift.max(0.3, Swift.min(0.85, brightness))
        
        return Color(hue: hue / 360, saturation: adjustedSaturation, brightness: adjustedBrightness)
    }
    
    /// キャッシュをクリア
    func clearColorCache() {
        colorCache.removeAll()
        imageDownloadTasks.values.forEach { $0.cancel() }
        imageDownloadTasks.removeAll()
    }
}

// Spotify セッションの状態監視
extension SpotifyMusicManager: SPTSessionManagerDelegate {
    
    // セッション開始時の処理
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        DispatchQueue.main.async {
            self.authorizationError = nil
        }
    }
    
    // セッション失敗時の処理
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.authorizationError = error.localizedDescription
        }
    }
    
    // セッション更新時の処理
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        //TODO: トークン取得処理実装
    }
}

// Spotify　接続状態監視
extension SpotifyMusicManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.isAuthorized = true
            self.connectionAttempts = 0
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        
        if connectionAttempts < maxConnectionAttempts {
            connect()
        } else {
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        
        // エラーの説明から認証が必要かどうかを判断
        if let error = error as NSError? {
            let errorDescription = error.localizedDescription.lowercased()
            let needsReauthorization = errorDescription.contains("token") ||
            errorDescription.contains("authorization") ||
            errorDescription.contains("authenticate") ||
            !self.isAuthorized
            
            if needsReauthorization {
                let showAlert = ShowAlert()
                showAlert.showActionAlert(
                    title: "再認証が必要です",
                    message: "Spotifyとの接続が切断されました。再認証しますか？",
                    primaryButton: .default(title: "はい") {
                        self.authorize()
                    },
                    secondaryButton: .cancel(title: "いいえ")
                )
            } else {
                // その他の切断
            }
        }
    }
}
