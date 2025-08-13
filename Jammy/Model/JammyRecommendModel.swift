//
//  JammyRecommendModel.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/16.
//

import Foundation
import FirebaseFirestore

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
        let urlString = buildRandomRecommendURL(popularity: popularity)
        
        guard let url = URL(string: urlString) else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(spotifyManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await performSpotifyRequest(request)
    }
    
    // 細かくレコメンド
    func customRecommend(recommend: RecommendSettings) async throws -> [TrackInfo.Track] {
        let urlString = buildCustomRecommendURL(recommend: recommend)
        
        guard let url = URL(string: urlString) else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(spotifyManager.accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await performSpotifyRequest(request)
    }
    
    private func performSpotifyRequest(_ request: URLRequest) async throws -> [TrackInfo.Track] {
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SpotifyError.badServerResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    let tracks = try parseTrackResponse(data: data)
                    if tracks.isEmpty {
                        throw SpotifyError.noTracksFound
                    }
                    return tracks
                    
                case 429:
                    if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let waitTime = Int(retryAfter) {
                        try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                        retryCount += 1
                        continue
                    }
                    throw SpotifyError.rateLimited
                    
                default:
                    if retryCount < maxRetries - 1 {
                        retryCount += 1
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw SpotifyError.badServerResponse
                }
                
            } catch {
                if retryCount < maxRetries - 1 {
                    retryCount += 1
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                throw error
            }
        }
        
        throw SpotifyError.badServerResponse
    }
    
    private func buildRandomRecommendURL(popularity: Double) -> String {
        let formattedPopularity = String(format: "%.0f", popularity)
        
        let baseRange = 25
        let additionalRange = if popularity <= 10 {
            35
        } else if popularity >= 90 {
            30
        } else if popularity <= 20 || popularity >= 80 {
            25
        } else {
            15
        }
        
        let popularityRange = baseRange + additionalRange
        let minPopularity = max(0, Double(formattedPopularity)! - Double(popularityRange))
        let maxPopularity = min(100, Double(formattedPopularity)! + Double(popularityRange))
        
        let genres = ["j-pop", "j-rock", "anime", "japanese", "jpop"]
        let genreString = genres.shuffled().prefix(2).joined(separator: ",")
        
        return "https://api.spotify.com/v1/recommendations?" +
        "limit=\(getTrackNumber)" +
        "&market=JP" +
        "&seed_genres=\(genreString)" +
        "&target_popularity=\(formattedPopularity)" +
        "&min_popularity=\(Int(minPopularity))" +
        "&max_popularity=\(Int(maxPopularity))"
    }
    
    private func buildCustomRecommendURL(recommend: RecommendSettings) -> String {
        let formattedPopularity = String(format: "%.0f", recommend.targetPopularity)
        let formattedEnergy = String(format: "%.2f", recommend.energy)
        let formattedTempo = String(format: "%.0f", recommend.minTempo)
        let formattedValence = String(format: "%.2f", recommend.valence)
        
        let genreString = recommend.selectedGenres
            .map { $0.lowercased() }
            .joined(separator: ",")
        
        return "https://api.spotify.com/v1/recommendations?" +
        "limit=\(getTrackNumber)" +
        "&market=JP" +
        "&seed_genres=\(genreString)" +
        "&target_popularity=\(formattedPopularity)" +
        "&target_energy=\(formattedEnergy)" +
        "&target_tempo=\(formattedTempo)" +
        "&target_valence=\(formattedValence)"
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

}
