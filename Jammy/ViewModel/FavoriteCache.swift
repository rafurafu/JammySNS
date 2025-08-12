//
//  FavoriteCache.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/11/13.
//
import SwiftUI

// パフォーマンス最適化のためのキャッシュマネージャー
class FavoriteCache {
    static let shared = FavoriteCache()
    private var cache: [String: Set<String>] = [:] // [userId: Set<postId>]
    private let queue = DispatchQueue(label: "com.jammy.favoriteCache")
    
    func isFavorited(userId: String, postId: String) -> Bool? {
        queue.sync {
            cache[userId]?.contains(postId)
        }
    }
    
    func setFavorites(userId: String, postIds: Set<String>) {
        queue.async {
            self.cache[userId] = postIds
        }
    }
    
    func addFavorite(userId: String, postId: String) {
        queue.async {
            var userFavorites = self.cache[userId] ?? Set<String>()
            userFavorites.insert(postId)
            self.cache[userId] = userFavorites
        }
    }
    
    func removeFavorite(userId: String, postId: String) {
        queue.async {
            var userFavorites = self.cache[userId] ?? Set<String>()
            userFavorites.remove(postId)
            self.cache[userId] = userFavorites
        }
    }
    
    func clearCache(for userId: String) {
        queue.async {
            self.cache.removeValue(forKey: userId)
        }
    }
}
