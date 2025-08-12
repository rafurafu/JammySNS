//
//  FavoritePost.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/30.
//
import SwiftUI
import FirebaseFirestore

struct FavoritePostManager {
    static let shared = FavoritePostManager()
    private let db = Firestore.firestore()
    
    func checkFavoriteStatus(userId: String, postId: String) async throws -> Bool {
            // まずキャッシュをチェック
            if let cachedResult = FavoriteCache.shared.isFavorited(userId: userId, postId: postId) {
                return cachedResult
            }
            
            // キャッシュになければFirebaseから取得
            let favoritePosts = try await getFavoritePosts(userId: userId)
            let favoriteSet = Set(favoritePosts)
            
            // キャッシュを更新
            FavoriteCache.shared.setFavorites(userId: userId, postIds: favoriteSet)
            
            return favoriteSet.contains(postId)
        }
        
        // いいねの追加時にキャッシュも更新
        func saveFavoritePostWithCache(userId: String, postId: String) async throws {
            try await saveFavoritePost(userId: userId, postId: postId)
            FavoriteCache.shared.addFavorite(userId: userId, postId: postId)
        }
        
        // いいねの削除時にキャッシュも更新
        func removeFavoritePostWithCache(userId: String, postId: String) async throws {
            try await removeFavoritePost(userId: userId, postId: postId)
            FavoriteCache.shared.removeFavorite(userId: userId, postId: postId)
        }
    
    // いいねした投稿IDをコレクションを追加
    func saveFavoritePost(userId: String, postId: String) async throws {
        let userPostsRef = db.collection("users").document(userId).collection("favorite_posts")
        
        // 既存のデータがないかチェック
        let existingDoc = try await userPostsRef.document(postId).getDocument()
        if !existingDoc.exists {
            // 新しいデータを追加する
            try await userPostsRef.document(postId).setData(["id": postId])
        }
        try await addFavoritePost(postId: postId, changeInt: 1) //　投稿からfavoriteの数をひとつ増やす
    }

    // いいねした投稿をコレクションから削除
    func removeFavoritePost(userId: String, postId: String) async throws {
        let userPostsRef = db.collection("users").document(userId).collection("favorite_posts")
        
        // 既存のデータがないかチェック
        let existingDoc = try await userPostsRef.document(postId).getDocument()
        if existingDoc.exists {
            // データを削除する
            try await userPostsRef.document(postId).delete()
        }
        try await addFavoritePost(postId: postId, changeInt: -1)    // 投稿からfavoriteの数をひとつ減らす
    }

    // 投稿のいいね数を操作する関数
    func addFavoritePost(postId: String, changeInt: Int) async throws {
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                postDocument = try transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // 現在のいいね数を取得
            let currentLikes = postDocument.data()?["likeCount"] as? Int ?? 0
            
            // いいね数を更新
            let newLikes = max(0, currentLikes + changeInt) // いいね数が負の値にならないように制御
            
            // トランザクション内でデータを更新
            transaction.updateData([
                "likeCount": newLikes
            ], forDocument: postRef)
            
            return nil
        })
    }

    //　いいねした投稿を全取得
    func getFavoritePosts(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users").document(userId).collection("favorite_posts").getDocuments()
        
        return snapshot.documents.compactMap { $0.documentID }
    }
    
    // 投稿のいいね数を取得
    func getFavoritePostCount(postId: String) async throws -> Int {
        let document = try await db.collection("posts").document(postId).getDocument()
        return document.data()?["likeCount"] as? Int ?? 0
    }
}
