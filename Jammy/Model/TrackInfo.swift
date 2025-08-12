//
//  TrackInfo.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/05/20.
//

import Foundation
import FirebaseFirestore

struct TrackInfo: Decodable {
    var item: Track
    
    struct Track: Decodable, Hashable {  // Hashableを追加
        var id: String
        var name: String
        var artists: [Artist]
        var album: Album
        var uri: String
        var duration_ms: Double  // 曲の長さ (ミリ秒)
        var preview_url: String? // プレビューURL用に追加

        // カスタムイニシャライザ
        init(id: String = "",
             name: String = "曲が見つかりません",
             artists: [Artist] = [Artist(name: "不明なアーティスト")],
             album: Album = Album(images: [AlbumImage(url: "https://www.shoshinsha-design.com/wp-content/uploads/2020/05/noimage-760x460.png")]),
             uri: String = "",
             duration_ms: Double = 1000,
             preview_url: String? = nil) {
            self.id = id
            self.name = name
            self.artists = artists
            self.album = album
            self.uri = uri
            self.duration_ms = duration_ms
            self.preview_url = preview_url
        }
    }
    
    struct Album: Decodable, Hashable {  // Hashableを追加
        var images: [AlbumImage]
    }
    
    struct Artist: Decodable, Hashable {  // Hashableを追加
        var name: String
    }
    
    struct AlbumImage: Decodable, Hashable {  // Hashableを追加
        var url: String
    }
    
    init(item: Track = Track(), progress_ms: Double? = nil) {
        self.item = item
    }
}
