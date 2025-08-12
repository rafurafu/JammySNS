//
//  FavoriteArtistsManager.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/30.
//

import SwiftUI
import FirebaseFirestore

struct FavoriteArtistsManager {
    static let shared = FavoriteArtistsManager()
    private let db = Firestore.firestore()
    
    // コレクションとして保存
    func saveFavoriteArtists(userId: String, artists: [FavoriteArtist]) async throws {
        // ユーザーのfavorite_artistsコレクションへの参照
        let userArtistsRef = db.collection("users").document(userId).collection("favorite_artists")
        
        // まず既存のコレクションをクリア
        let existingDocs = try await userArtistsRef.getDocuments()
        let batch = db.batch()
        existingDocs.documents.forEach { doc in
            batch.deleteDocument(userArtistsRef.document(doc.documentID))
        }
        try await batch.commit()
        
        // 新しいデータを保存
        let newBatch = db.batch()
        for artist in artists {
            let artistData: [String: Any] = [
                "id": artist.id,
                "name": artist.name,
                "imageUrl": artist.imageUrl,  // 修正: artist.imagesではなくimageUrlを使用
                "uri": artist.uri,
                "genres": artist.genres,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            let docRef = userArtistsRef.document(artist.id)
            newBatch.setData(artistData, forDocument: docRef)
        }
        
        try await newBatch.commit()
    }
    
    func getFavoriteArtists(userId: String) async throws -> [FavoriteArtist] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("favorite_artists")
            .getDocuments()
        
        return snapshot.documents.map { document in
            let data = document.data()
            return FavoriteArtist(
                id: data["id"] as? String ?? "",
                name: data["name"] as? String ?? "",
                imageUrl: data["imageUrl"] as? String ?? "",
                uri: data["uri"] as? String ?? "",
                genres: data["genres"] as? [String] ?? []
            )
        }
    }
    
}

