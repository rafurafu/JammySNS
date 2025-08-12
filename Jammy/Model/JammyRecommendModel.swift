//
//  JammyRecommendModel.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/16.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftKeychainWrapper
import SwiftUI

// MARK: 今のレコメンドモデル

// カスタムエラーの定義
enum SpotifyError: Error {
    case invalidURL
    case badServerResponse
    case rateLimited
    case parseError(String)
    case noTracksFound
}

class JammyRecommendModel: ObservableObject {
    // 公開プロパティ
    @Published var unheardTracks: [PostModel] = []
    private let db = Firestore.firestore()
    private let spotifyManager: SpotifyMusicManager
    let getTrackNumber: Int = 10    // 取得する曲数
    
    init(spotifyManager: SpotifyMusicManager? = nil) {
        self.spotifyManager = spotifyManager ?? SpotifyMusicManager()
    }
    
    // ランダムレコメンドの実装
    func randomRecommend(popularity: Double) async throws -> [TrackInfo.Track] {
        print("\n=== ランダムレコメンド開始 ===")
        print("設定値:")
        print("- 人気度: \(String(format: "%.1f", popularity))%")
        
        let formattedPopularity = String(format: "%.0f", popularity)
        
        // 人気度の範囲を動的に設定
        let baseRange = 25  // 基本の範囲
        let additionalRange = if popularity <= 10 {
            35  // マイナー寄りの場合、より広い範囲で検索
        } else if popularity >= 90 {
            30  // メジャー寄りの場合も範囲を広げる
        } else if popularity <= 20 || popularity >= 80 {
            25  // やや極端な場合
        } else {
            15  // 通常の場合
        }
        
        let popularityRange = baseRange + additionalRange
        let minPopularity = max(0, Double(formattedPopularity)! - Double(popularityRange))
        let maxPopularity = min(100, Double(formattedPopularity)! + Double(popularityRange))
        
        // ジャンルシードの設定
        let genres = ["j-pop", "j-rock", "anime", "japanese", "jpop"]
        let genreString = genres.shuffled().prefix(2).joined(separator: ",")
        
        // APIリクエストURLの構築
        let urlString = "https://api.spotify.com/v1/recommendations?" +
        "limit=\(getTrackNumber)" +
        "&market=JP" +
        "&seed_genres=\(genreString)" +
        "&target_popularity=\(formattedPopularity)" +
        "&min_popularity=\(Int(minPopularity))" +
        "&max_popularity=\(Int(maxPopularity))"
        
        print("\nリクエストURL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error: URLの生成に失敗")
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(spotifyManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                print("\n試行 \(retryCount + 1)/\(maxRetries)")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: 不正なレスポンス形式")
                    throw SpotifyError.badServerResponse
                }
                
                print("ステータスコード: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    let tracks = try parseTrackResponse(data: data)
                    if tracks.isEmpty {
                        print("Error: 曲が見つかりませんでした")
                        throw SpotifyError.noTracksFound
                    }
                    print("取得件数: \(tracks.count)曲")
                    print("=== レコメンド完了 ===\n")
                    return tracks
                    
                case 429:
                    print("Error: レート制限に到達")
                    if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let waitTime = Int(retryAfter) {
                        print("待機時間: \(waitTime)秒")
                        try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                        retryCount += 1
                        continue
                    }
                    throw SpotifyError.rateLimited
                    
                default:
                    if retryCount < maxRetries - 1 {
                        print("Error: ステータスコード \(httpResponse.statusCode)")
                        retryCount += 1
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw SpotifyError.badServerResponse
                }
                
            } catch {
                if retryCount < maxRetries - 1 {
                    print("Error: \(error.localizedDescription)")
                    retryCount += 1
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                throw error
            }
        }
        
        print("Error: すべての試行が失敗")
        throw SpotifyError.badServerResponse
    }
    
    // 細かくレコメンド
    func customRecommend(recommend: RecommendSettings) async throws -> [TrackInfo.Track] {
        print("\n=== カスタムレコメンド開始 ===")
        print("設定値:")
        print("- 人気度: \(String(format: "%.1f", recommend.targetPopularity))%")
        print("- エネルギー: \(String(format: "%.1f", recommend.energy * 100))%")
        print("- テンポ: \(String(format: "%.1f", recommend.minTempo))BPM")
        print("- 明るさ: \(String(format: "%.1f", recommend.valence * 100))%")
        print("- ジャンル: \(recommend.selectedGenres)")
        
        // 数値を2桁の小数点に制限
        let formattedPopularity = String(format: "%.0f", recommend.targetPopularity)
        let formattedEnergy = String(format: "%.2f", recommend.energy)
        let formattedTempo = String(format: "%.0f", recommend.minTempo)
        let formattedValence = String(format: "%.2f", recommend.valence)
        
        // ジャンルを結合
        let genreString = recommend.selectedGenres
            .map { $0.lowercased() }
            .joined(separator: ",")
        
        let urlString = "https://api.spotify.com/v1/recommendations?" +
        "limit=\(getTrackNumber)" +
        "&market=JP" +
        "&seed_genres=\(genreString)" +
        "&target_popularity=\(formattedPopularity)" +
        "&target_energy=\(formattedEnergy)" +
        "&target_tempo=\(formattedTempo)" +
        "&target_valence=\(formattedValence)"
        
        print("\nリクエストURL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error: URLの生成に失敗")
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(spotifyManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                print("\n試行 \(retryCount + 1)/\(maxRetries)")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: 不正なレスポンス形式")
                    throw SpotifyError.badServerResponse
                }
                
                print("ステータスコード: \(httpResponse.statusCode)")
                
                // レスポンスボディの内容を確認
                if let responseString = String(data: data, encoding: .utf8) {
                    print("レスポンス内容: \(responseString)")
                }
                
                switch httpResponse.statusCode {
                case 200:
                    let tracks = try parseTrackResponse(data: data)
                    if tracks.isEmpty {
                        print("Error: 曲が見つかりませんでした")
                        throw SpotifyError.noTracksFound
                    }
                    print("取得件数: \(tracks.count)曲")
                    print("=== レコメンド完了 ===\n")
                    return tracks
                    
                case 429:
                    print("Error: レート制限に到達")
                    if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let waitTime = Int(retryAfter) {
                        print("待機時間: \(waitTime)秒")
                        try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                        retryCount += 1
                        continue
                    }
                    throw SpotifyError.rateLimited
                    
                default:
                    if retryCount < maxRetries - 1 {
                        print("Error: ステータスコード \(httpResponse.statusCode)")
                        retryCount += 1
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw SpotifyError.badServerResponse
                }
                
            } catch {
                if retryCount < maxRetries - 1 {
                    print("Error: \(error.localizedDescription)")
                    retryCount += 1
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                throw error
            }
        }
        
        print("Error: すべての試行が失敗")
        throw SpotifyError.badServerResponse
    }
    
    // トラックレスポンスのパース
    private func parseTrackResponse(data: Data) throws -> [TrackInfo.Track] {
        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let items = jsonResult["tracks"] as? [[String: Any]] else {
            throw SpotifyError.parseError("Failed to parse response")
        }
        
        let tracks = items.compactMap { item -> TrackInfo.Track? in
            guard let name = item["name"] as? String,
                  let uri = item["uri"] as? String,
                  let durationMS = item["duration_ms"] as? Double,
                  let albumData = item["album"] as? [String: Any],
                  let albumImages = albumData["images"] as? [[String: Any]],
                  let firstImage = albumImages.first,
                  let imageUrl = firstImage["url"] as? String,
                  let artistsData = item["artists"] as? [[String: Any]],
                  let previewUrl = item["preview_url"] as? String? else {
                return nil
            }
            
            let artists = artistsData.compactMap { artistData -> TrackInfo.Artist? in
                guard let artistName = artistData["name"] as? String else { return nil }
                return TrackInfo.Artist(name: artistName)
            }
            
            let album = TrackInfo.Album(images: [TrackInfo.AlbumImage(url: imageUrl)])
            
            return TrackInfo.Track(
                id: item["id"] as? String ?? "",
                name: name,
                artists: artists,
                album: album,
                uri: uri,
                duration_ms: durationMS,
                preview_url: previewUrl
            )
        }
        
        // エラー処理の改善
        if tracks.isEmpty {
            throw SpotifyError.noTracksFound
        }
        
        return tracks
    }
    
    // エラーメッセージの取得
    func getErrorMessage(_ error: Error) -> String {
        switch error {
        case SpotifyError.invalidURL:
            return "URLの生成に失敗しました"
        case SpotifyError.badServerResponse:
            return "サーバーからの応答が無効です"
        case SpotifyError.rateLimited:
            return "APIリクエスト制限に達しました。しばらく待ってから再試行してください"
        case SpotifyError.parseError(let message):
            return "データの解析に失敗しました: \(message)"
        case SpotifyError.noTracksFound:
            return "条件に合う楽曲が見つかりませんでした"
        default:
            return "予期せぬエラーが発生しました: \(error.localizedDescription)"
        }
    }

    
    // MARK: 過去のレコメンドモデル
    //class JammyRecommendModel: ObservableObject {
    //    // 公開プロパティ
    //    @Published var unheardTracks: [PostModel] = []
    //    private let db = Firestore.firestore()
    //    private let keychain = KeychainWrapper.standard
    //
    //    // キーの定義
    //    private let unheardTracksKey = "unheardTracks"
    //    private let lastFetchDateKey = "lastFetchDate"
    //    private let dailySeedKey = "dailySeed"
    //
    //    // 1日のタイムスタンプ（秒）
    //    private let dayInSeconds: TimeInterval = 24 * 60 * 60
    //
    //    init() {
    //        loadPersistedData()
    //    }
    //
    //    // データの永続化
    //    private func loadPersistedData() {
    //        if let userId = Auth.auth().currentUser?.uid,
    //           let savedData = keychain.data(forKey: "\(unheardTracksKey)_\(userId)"),
    //           let tracks = try? JSONDecoder().decode([PostModel].self, from: savedData) {
    //            DispatchQueue.main.async {
    //                self.unheardTracks = tracks
    //            }
    //        }
    //    }
    //
    //    private func persistData() {
    //        if let userId = Auth.auth().currentUser?.uid,
    //           let encodedData = try? JSONEncoder().encode(unheardTracks) {
    //            keychain.set(encodedData, forKey: "\(unheardTracksKey)_\(userId)")
    //        }
    //    }
    //
    //    // 最後の更新日時を取得
    //    private func getLastFetchDate() -> Date {
    //        if let userId = Auth.auth().currentUser?.uid,
    //           let timestamp = keychain.double(forKey: "\(lastFetchDateKey)_\(userId)") {
    //            return Date(timeIntervalSince1970: timestamp)
    //        }
    //        return Date(timeIntervalSince1970: 0)
    //    }
    //
    //    // 更新日時を保存
    //    private func updateLastFetchDate() {
    //        if let userId = Auth.auth().currentUser?.uid {
    //            keychain.set(Date().timeIntervalSince1970, forKey: "\(lastFetchDateKey)_\(userId)")
    //        }
    //    }
    //
    //    // 日付からシード文字列を生成
    //    private func formatDateForSeed(_ date: Date) -> String {
    //        let formatter = DateFormatter()
    //        formatter.dateFormat = "yyyyMMdd"
    //        return formatter.string(from: date)
    //    }
    //
    //    // 2つの日付が同じ日かどうかを判定
    //    private func isSameDay(date1: Date, date2: Date) -> Bool {
    //        let calendar = Calendar.current
    //        return calendar.isDate(date1, inSameDayAs: date2)
    //    }
    //
    //    // デイリーシードの保存
    //    private func saveDailySeed(_ seed: String) {
    //        if let userId = Auth.auth().currentUser?.uid {
    //            keychain.set(seed, forKey: "\(dailySeedKey)_\(userId)")
    //        }
    //    }
    //
    //    // デイリーシードの取得
    //    private func getDailySeed() -> String? {
    //        if let userId = Auth.auth().currentUser?.uid {
    //            return keychain.string(forKey: "\(dailySeedKey)_\(userId)")
    //        }
    //        return nil
    //    }
    //
    //    private let japaneseArtistCategories = [
    //        "popular": [
    //            "5Vo1hnCRmCM6M4thZCInCj",  // YOASOBI
    //            "6zYRxuMRAO4n9CghKeI8wu",  // 米津玄師
    //            "7k73EtZwoPs516ZxE72KsO",  // あいみょん
    //            "2htRXGHXCwVw5iMYFs7BiE",  // Official髭男dism
    //            "5kVZa4lFUmAQlBogl1fkd6",  // Ado
    //            "4uEBZ5RiVuYPIKx859iym3",  // あいみょん
    //            "5PqoZ2GhcPyB9TQoUC4Bku",  // Kenshi Yonezu
    //        ],
    //        "indie": [
    //            "7vcvz5LUBZFvzO9uaQJFOK",  // 須田景凪
    //            "2n6OICMr4icxJqjNqoZ5GB",  // ZUTOMAYO
    //            "5RqSsHQNwf2u3qLXwVibhZ",  // Vaundy
    //            "6mEQK9m2krja6X1cfsAjfl",  // Eve
    //            "1MUhx6fluMxE3LHNUUk3Hj",  // ヨルシカ
    //            "0kJcGiyqAZJZnENhKE8t9x",  // Creepy Nuts
    //            "7lbZvvWQYpk4fPVH14BMXJ",  // PEOPLE 1
    //        ],
    //        "band": [
    //            "5Ikqx3acqNpFhL7kX6zSAv",  // Mrs. GREEN APPLE
    //            "64tJ2EAv1R6UaZqc4iOCyj",  // King Gnu
    //            "2nvl0N9GwyX69RRBMEZ4OD",  // back number
    //            "7tUDQOgOCN4b9N1CiRTuMF",  // ONE OK ROCK
    //            "38WbKH6oKAZskBhqDFA8Uj",  // DISH//
    //            "1EowJ1WwkMzkCkRomFhui7",  // RADWIMPS
    //            "6x1rJCry0EvMl4xklN4qnj",  // マカロニえんぴつ
    //        ],
    //        "alternative": [
    //            "6sRz5qn8Cw7oaJkftNHQb3",  // millennium parade
    //            "2kQxkUZ5ZHZbVMpFB8aOJM",  // 04 Limited Sazabys
    //            "5Vo6TyvNWFxZzDtKJB3cPz",  // 10-FEET
    //            "1SNvVntF2v8WPvuQPOzqJ7",  // Saucy Dog
    //            "3rCxJMWU3wHL5PXD14YofC",  // Art-School
    //            "3QYXcnDp2LKzcFyzhJ7pwI",  // KANA-BOON
    //            "2GxvEWJcJ1wbPa41N5sE5y",  // SiM
    //        ],
    //        "electronic": [
    //            "2n6OICMr4icxJqjNqoZ5GB",  // ZUTOMAYO
    //            "6mEQK9m2krja6X1cfsAjfl",  // Eve
    //            "1MUhx6fluMxE3LHNUUk3Hj",  // ヨルシカ
    //            "3z89YGXgJh8rFbqyHPBRGG",  // amazarashi
    //            "5BYhxBPY67TyLsHjhS9Q6D",  // FEMM
    //            "2KC9Qb60EaY0kW4eH68vr3"   // Wednesday Campanella
    //        ]
    //    ]
    //
    //    // カスタムレコメンド機能
    //    func customRecommend(recommend: RecommendSettings) async throws -> [TrackInfo.Track] {
    //        guard let uid = Auth.auth().currentUser?.uid else {
    //            throw NSError(domain: "認証エラー", code: 0, userInfo: [NSLocalizedDescriptionKey: "ユーザーが認証されていません"])
    //        }
    //
    //        // Spotifyマネージャーからアクセストークンを取得
    //        guard let spotifyManager = try? await SpotifyMusicManager() else {
    //            throw NSError(domain: "SpotifyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Spotify認証エラー"])
    //        }
    //
    //        // 日本のトラックを取得
    //        let japaneseTopTracks = try await fetchJapaneseTracks(
    //            accessToken: spotifyManager.accessToken,
    //            seed: formatDateForSeed(Date()),
    //            targetPopularity: Int(recommend.targetPopularity)
    //        )
    //
    //        // ユーザー設定に基づいてフィルタリング
    //        let filteredTracks = japaneseTopTracks.filter { track in
    //            // ジャンルのフィルタリング（アーティストの特徴から判断）
    //            let matchesGenre = recommend.selectedGenres.isEmpty ||
    //                recommend.selectedGenres.contains { genre in
    //                    isArtistInGenre(track.artists.first?.name ?? "", genre: genre)
    //                }
    //
    //            // バレンス（明るさ）のフィルタリング
    //            let matchesValence = true // バレンス情報が利用可能な場合はここでフィルタリング
    //
    //            // エネルギーのフィルタリング
    //            let matchesEnergy = true // エネルギー情報が利用可能な場合はここでフィルタリング
    //
    //            // テンポのフィルタリング
    //            let matchesTempo = true // テンポ情報が利用可能な場合はここでフィルタリング
    //
    //            return matchesGenre && matchesValence && matchesEnergy && matchesTempo
    //        }
    //
    //        // フィルタリングされたトラックから未視聴の曲を抽出
    //        let newTracks = try await filterNewTracks(tracks: filteredTracks)
    //
    //        // シャッフルして最大10曲を返す
    //        return Array(newTracks.shuffled().prefix(10))
    //    }
    //
    //    // アーティストがジャンルに属しているかを判定
    //    private func isArtistInGenre(_ artistName: String, genre: String) -> Bool {
    //        switch genre.lowercased() {
    //        case "j-pop":
    //            return isJapaneseArtist(artistName)
    //        case "rock", "j-rock":
    //            return isJapaneseArtist(artistName) // より詳細な判定が必要
    //        case "indie-pop":
    //            return isJapaneseArtist(artistName) // より詳細な判定が必要
    //        case "dance-pop":
    //            return isJapaneseArtist(artistName)
    //        case "anime":
    //            return isJapaneseArtist(artistName)
    //        default:
    //            return true
    //        }
    //    }
    //
    //    private func fetchJapaneseTracks(accessToken: String, seed: String, targetPopularity: Int) async throws -> [TrackInfo.Track] {
    //        var allTracks: [TrackInfo.Track] = []
    //        var usedTrackURIs = Set<String>()  // 重複トラック防止用
    //
    //        // 人気度の範囲を動的に設定
    //        let baseRange = 25  // 基本の範囲
    //        let additionalRange = if targetPopularity <= 10 {
    //            35  // マイナー寄りの場合、より広い範囲で検索
    //        } else if targetPopularity >= 90 {
    //            30  // メジャー寄りの場合も範囲を広げる
    //        } else if targetPopularity <= 20 || targetPopularity >= 80 {
    //            25  // やや極端な場合
    //        } else {
    //            15  // 通常の場合
    //        }
    //
    //        let popularityRange = baseRange + additionalRange
    //        // 最小値を0未満にしない、最大値を100超にしないよう調整
    //        let minPopularity = max(0, targetPopularity - popularityRange)
    //        let maxPopularity = min(100, targetPopularity + popularityRange)
    //
    //        // よりマイナーなアーティストを含めるための重み付け調整
    //        let categories = if targetPopularity <= 10 {
    //            ["popular": 0.05, "band": 0.15, "indie": 0.35, "alternative": 0.25, "electronic": 0.20]
    //        } else if targetPopularity <= 20 {
    //            ["popular": 0.10, "band": 0.20, "indie": 0.30, "alternative": 0.25, "electronic": 0.15]
    //        } else if targetPopularity >= 90 {
    //            ["popular": 0.50, "band": 0.25, "indie": 0.05, "alternative": 0.10, "electronic": 0.10]
    //        } else if targetPopularity >= 80 {
    //            ["popular": 0.45, "band": 0.25, "indie": 0.10, "alternative": 0.10, "electronic": 0.10]
    //        } else if targetPopularity >= 50 {
    //            ["popular": 0.40, "band": 0.30, "indie": 0.10, "alternative": 0.10, "electronic": 0.10]
    //        } else {
    //            ["popular": 0.15, "band": 0.20, "indie": 0.30, "alternative": 0.20, "electronic": 0.15]
    //        }
    //
    //        for (category, weight) in categories {
    //            guard let artistsInCategory = japaneseArtistCategories[category] else { continue }
    //
    //            let artistCount = max(3, Int(Double(artistsInCategory.count) * weight))
    //            let selectedArtists = selectArtistsFromCategory(artists: artistsInCategory, count: artistCount, seed: seed)
    //
    //            for artistId in selectedArtists {
    //                let urlString = "https://api.spotify.com/v1/recommendations?" +
    //                    "limit=5" +
    //                    "&market=JP" +
    //                    "&seed_artists=\(artistId)" +
    //                    "&max_popularity=\(maxPopularity)" +
    //                    "&min_popularity=\(minPopularity)" +
    //                    "&target_popularity=\(targetPopularity)" +
    //                    "&min_acousticness=0.0" +
    //                    "&max_acousticness=1.0" +
    //                    "&min_danceability=0.0" +
    //                    "&max_danceability=1.0" +
    //                    "&min_energy=0.0" +
    //                    "&max_energy=1.0" +
    //                    "&min_instrumentalness=0.0" +
    //                    "&max_instrumentalness=1.0" +
    //                    "&min_tempo=60" +
    //                    "&max_tempo=200" +
    //                    "&min_liveness=0.0" +
    //                    "&max_liveness=1.0" +
    //                    "&min_speechiness=0.0" +
    //                    "&max_speechiness=1.0" +
    //                    "&min_valence=0.0" +
    //                    "&max_valence=1.0"
    //
    //                guard let url = URL(string: urlString) else { continue }
    //
    //                var request = URLRequest(url: url)
    //                request.httpMethod = "GET"
    //                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    //
    //                do {
    //                    let (data, response) = try await URLSession.shared.data(for: request)
    //
    //                    guard let httpResponse = response as? HTTPURLResponse else {
    //                        print("Invalid response for category: \(category)")
    //                        continue
    //                    }
    //
    //                    switch httpResponse.statusCode {
    //                    case 200:
    //                        let tracks = try parseTrackResponse(data: data)
    //                        // 重複を避けながらトラックを追加
    //                        for track in tracks {
    //                            if !usedTrackURIs.contains(track.uri) {
    //                                allTracks.append(track)
    //                                usedTrackURIs.insert(track.uri)
    //                            }
    //                        }
    //
    //                    case 429:  // Rate limit exceeded
    //                        if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
    //                           let waitTime = Int(retryAfter) {
    //                            try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
    //                            continue
    //                        }
    //
    //                    default:
    //                        print("API error: \(httpResponse.statusCode) for category \(category)")
    //                        continue
    //                    }
    //
    //                    // API制限を考慮して少し待機
    //                    try await Task.sleep(nanoseconds: 500_000_000)
    //
    //                } catch {
    //                    print("Error fetching tracks for category \(category): \(error)")
    //                    continue
    //                }
    //            }
    //        }
    //
    //        if allTracks.count < 10 {
    //            // 人気度の範囲を更に広げて再検索
    //            let expandedMinPopularity = max(0, minPopularity - 25)
    //            let expandedMaxPopularity = min(100, maxPopularity + 25)
    //
    //            for (category, _) in categories {
    //                guard let artists = japaneseArtistCategories[category] else { continue }
    //                let selectedArtists = selectArtistsFromCategory(artists: artists, count: 2, seed: String(Date().timeIntervalSince1970))
    //
    //                for artistId in selectedArtists {
    //                    let urlString = "https://api.spotify.com/v1/recommendations?" +
    //                        "limit=5" +
    //                        "&market=JP" +
    //                        "&seed_artists=\(artistId)" +
    //                        "&min_popularity=\(expandedMinPopularity)" +
    //                        "&max_popularity=\(expandedMaxPopularity)"
    //
    //                    guard let url = URL(string: urlString) else { continue }
    //
    //                    var request = URLRequest(url: url)
    //                    request.httpMethod = "GET"
    //                    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    //
    //                    do {
    //                        let (data, response) = try await URLSession.shared.data(for: request)
    //
    //                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
    //                            let tracks = try parseTrackResponse(data: data)
    //                            for track in tracks {
    //                                if !usedTrackURIs.contains(track.uri) {
    //                                    allTracks.append(track)
    //                                    usedTrackURIs.insert(track.uri)
    //                                }
    //                            }
    //                        }
    //
    //                        try await Task.sleep(nanoseconds: 500_000_000)
    //
    //                    } catch {
    //                        print("Error in additional search: \(error)")
    //                        continue
    //                    }
    //                }
    //            }
    //        }
    //
    //        return Array(allTracks.shuffled().prefix(10))
    //    }
    //
    //    // カテゴリーからアーティストを選択するヘルパーメソッド
    //    private func selectArtistsFromCategory(artists: [String], count: Int, seed: String) -> [String] {
    //        var generator = SeededRandomNumberGenerator(seed: Int(seed) ?? 0)
    //        return Array(artists.shuffled(using: &generator).prefix(count))
    //    }
    //
    //    // トラックレスポンスのパース
    //    private func parseTrackResponse(data: Data) throws -> [TrackInfo.Track] {
    //        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
    //              let items = jsonResult["tracks"] as? [[String: Any]] else {
    //            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    //        }
    //
    //        return items.compactMap { item -> TrackInfo.Track? in
    //            guard let name = item["name"] as? String,
    //                  let uri = item["uri"] as? String,
    //                  let durationMS = item["duration_ms"] as? Double,
    //                  let albumData = item["album"] as? [String: Any],
    //                  let albumImages = albumData["images"] as? [[String: Any]],
    //                  let firstImage = albumImages.first,
    //                  let imageUrl = firstImage["url"] as? String,
    //                  let artistsData = item["artists"] as? [[String: Any]],
    //                  let previewUrl = item["preview_url"] as? String? else {
    //                return nil
    //            }
    //
    //            let artists = artistsData.compactMap { artistData -> TrackInfo.Artist? in
    //                guard let artistName = artistData["name"] as? String else { return nil }
    //                return TrackInfo.Artist(name: artistName)
    //            }
    //
    //            let album = TrackInfo.Album(images: [TrackInfo.AlbumImage(url: imageUrl)])
    //
    //            return TrackInfo.Track(
    //                id: item["id"] as? String ?? "",
    //                name: name,
    //                artists: artists,
    //                album: album,
    //                uri: uri,
    //                duration_ms: durationMS,
    //                preview_url: previewUrl
    //            )
    //        }
    //    }
    //
    //    // 未視聴の曲をフィルタリング
    //    private func filterNewTracks(tracks: [TrackInfo.Track]) async throws -> [TrackInfo.Track] {
    //        guard let uid = Auth.auth().currentUser?.uid else {
    //            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "ユーザーが認証されていません"])
    //        }
    //
    //        let userPostsSnapshot = try await db.collection("posts")
    //            .whereField("postUser", isEqualTo: uid)
    //            .getDocuments()
    //        let postedTrackURIs = Set(userPostsSnapshot.documents.compactMap { $0.data()["trackURI"] as? String })
    //
    //        return tracks.filter { !postedTrackURIs.contains($0.uri) }
    //    }
    //
    //    // 日本のアーティストかどうかを判定
    //    private func isJapaneseArtist(_ artistName: String) -> Bool {
    //        // 日本語文字のチェック
    //        let japaneseRange = "\\p{Script=Hiragana}|\\p{Script=Katakana}|\\p{Script=Han}"
    //        let regex = try? NSRegularExpression(pattern: japaneseRange)
    //        let range = NSRange(location: 0, length: artistName.utf16.count)
    //
    //        // 既知の日本のアーティストリスト
    //        let knownJapaneseArtists = [
    //            "YOASOBI", "King Gnu", "Official HIGE DANdism",
    //            "Mrs. GREEN APPLE", "RADWIMPS", "Vaundy",
    //            "back number", "THE FIRST TAKE", "BABYMETAL",
    //            "ONE OK ROCK", "Eve", "Ado", "Zutomayo",
    //            "Yorushika", "Kenshi Yonezu"
    //        ].map { $0.lowercased() }
    //
    //        let hasJapaneseCharacters = regex?.firstMatch(in: artistName, options: [], range: range) != nil
    //        let isKnownArtist = knownJapaneseArtists.contains(artistName.lowercased())
    //
    //        return hasJapaneseCharacters || isKnownArtist
    //    }
    //
    //    // シード付き乱数生成器の実装
    //    struct SeededRandomNumberGenerator: RandomNumberGenerator {
    //        private var seed: UInt64
    //
    //        init(seed: Int) {
    //            self.seed = UInt64(seed)
    //        }
    //
    //        mutating func next() -> UInt64 {
    //            seed = 2862933555777941757 &* seed &+ 3037000493
    //            return seed
    //        }
    //    }
    //
    //    // エラー定義
    //    enum RecommendationError: Error {
    //        case authenticationError
    //        case networkError
    //        case parseError
    //        case storageError
    //        case invalidData
    //
    //        var localizedDescription: String {
    //            switch self {
    //            case .authenticationError:
    //                return "認証エラーが発生しました。再ログインしてください。"
    //            case .networkError:
    //                return "ネットワークエラーが発生しました。インターネット接続を確認してください。"
    //            case .parseError:
    //                return "データの解析中にエラーが発生しました。"
    //            case .storageError:
    //                return "データの保存中にエラーが発生しました。"
    //            case .invalidData:
    //                return "無効なデータが検出されました。"
    //            }
    //        }
    //    }
    //}
}
