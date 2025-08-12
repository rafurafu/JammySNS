//
//  LikeArtists.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/29.
//

import Foundation

// アーティストを取得するモデル
struct LikeArtistsModel: Codable {
    let artists: Artists
    
    struct Artists: Codable {
        let items: [Artist]
        
        struct Artist: Codable {
            let id: String
            let name: String
            let uri: String
            let genres: [String]
            let images: [Images]
            
            struct Images: Codable {
                let url: String
            }
        }
    }
}

// ユーザーの好きなアーティストを保存するモデル
struct FavoriteArtist: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let imageUrl: String 
    let uri: String
    let genres: [String]
}
