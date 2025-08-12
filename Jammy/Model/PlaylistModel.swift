//
//  PlaylistModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/25.
//

import Foundation

struct PlaylistModel: Codable, Hashable, Equatable, Identifiable {
    let id: String
    let name: String
    let href: String
    let images: [PlaylistImage]
    
    struct PlaylistImage: Codable, Hashable, Equatable {
        let url: String
    }
}

struct PlaylistResponse: Codable, Hashable, Equatable {
    let items: [PlaylistModel?]  // nullを許容するためにオプショナルに変更
    
    // nullを除去した有効なプレイリストのみを取得するための計算プロパティ
    var validItems: [PlaylistModel] {
        return items.compactMap { $0 }  // nullを除去して有効な要素のみを返す
    }
}
