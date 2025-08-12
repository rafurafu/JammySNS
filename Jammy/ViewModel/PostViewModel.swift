//
//  PostViewModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/09/18.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [PostModel] = []
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let batchSize = 20
    @Published var isLoading = false
    @Published var hasMorePosts = true
    private var allPostIds: [String] = []
    
    // トレンドTL用の初期投稿取得
        func getInitialTrendPosts(blockedUsers: Set<String>) async throws {
            guard !isLoading else { return }
            isLoading = true
            
            do {
                let querySnapshot = try await db.collection("posts")
                    .order(by: "postTime", descending: true)
                    .limit(to: batchSize)
                    .getDocuments()
                
                let fetchedPosts = querySnapshot.documents.compactMap { document -> PostModel? in
                    try? document.data(as: PostModel.self)
                }.filter { !blockedUsers.contains($0.postUser) }
                
                self.posts = fetchedPosts
                self.lastDocument = querySnapshot.documents.last
                self.hasMorePosts = !querySnapshot.documents.isEmpty
                
            } catch {
                throw error
            }
            
            isLoading = false
        }
    
    // トレンドTL用の追加投稿取得（無限スクロール）
        func loadMoreTrendPosts(blockedUsers: Set<String>) async throws {
            guard !isLoading && hasMorePosts, let lastDocument = lastDocument else { return }
            isLoading = true
            
            do {
                let querySnapshot = try await db.collection("posts")
                    .order(by: "postTime", descending: true)
                    .limit(to: batchSize)
                    .start(afterDocument: lastDocument)
                    .getDocuments()
                
                let newPosts = querySnapshot.documents.compactMap { document -> PostModel? in
                    try? document.data(as: PostModel.self)
                }.filter { !blockedUsers.contains($0.postUser) }
                
                if !newPosts.isEmpty {
                    self.posts.append(contentsOf: newPosts)
                    self.lastDocument = querySnapshot.documents.last
                }
                
                self.hasMorePosts = !querySnapshot.documents.isEmpty
                
            } catch {
                throw error
            }
            
            isLoading = false
        }
    
    // 引き下げて更新用のメソッド
        func refreshTrendPosts(blockedUsers: Set<String>) async throws {
            self.lastDocument = nil
            self.hasMorePosts = true
            try await getInitialTrendPosts(blockedUsers: blockedUsers)
        }
    
    // ブロックユーザーの投稿をフィルタリングするメソッド
    private func filterBlockedPosts(_ posts: [PostModel], blockedUsers: Set<String>) -> [PostModel] {
        return posts.filter { !blockedUsers.contains($0.postUser) }
    }
    
    func loadMorePostsIfNeeded(currentIndex: Int, blockedUsers: Set<String>) async {
        if currentIndex == posts.count - 2 && !isLoading && hasMorePosts {
            isLoading = true
            do {
                try await loadMorePosts(blockedUsers: blockedUsers)
            } catch {
            }
            isLoading = false
        }
    }
    
    // 初期投稿を取得
    func getFirstPost(blockedUsers: Set<String>) async throws {
        do {
            let allDocs = try await db.collection("posts").getDocuments()
            allPostIds = allDocs.documents.map { $0.documentID }.shuffled()
            
            let firstBatchIds = Array(allPostIds.prefix(batchSize))
            var firstBatchPosts: [PostModel] = []
            
            for id in firstBatchIds {
                if let doc = try? await db.collection("posts").document(id).getDocument(),
                   let post = try? doc.data(as: PostModel.self) {
                    // ブロックユーザーの投稿は除外
                    if !blockedUsers.contains(post.postUser) {
                        firstBatchPosts.append(post)
                    }
                }
            }
            
            await MainActor.run {
                self.posts = firstBatchPosts
                self.hasMorePosts = allPostIds.count > batchSize
            }
        } catch {
            throw error
        }
    }
    
    // 追加の投稿を取得
    func loadMorePosts(blockedUsers: Set<String>) async throws {
        let currentCount = posts.count
        guard hasMorePosts && currentCount < allPostIds.count else { return }
        
        let nextBatchIds = Array(allPostIds[currentCount..<min(currentCount + batchSize, allPostIds.count)])
        var nextBatchPosts: [PostModel] = []
        
        for id in nextBatchIds {
            if let doc = try? await db.collection("posts").document(id).getDocument(),
               let post = try? doc.data(as: PostModel.self) {
                // ブロックユーザーの投稿は除外
                if !blockedUsers.contains(post.postUser) {
                    nextBatchPosts.append(post)
                }
            }
        }
        
        // ブロックユーザーの投稿を除外した次のバッチの投稿を追加
        await MainActor.run {
            self.posts.append(contentsOf: nextBatchPosts)
            self.hasMorePosts = posts.count < allPostIds.count
        }
    }
    
    // ドキュメントIDを使用して指定の投稿を取得
    func getPostById(postId: String) async throws -> PostModel? {
        do {
            let document = try await db.collection("posts").document(postId).getDocument()
            return try? document.data(as: PostModel.self)
        } catch {
            throw error
        }
    }
    
    /*
     現在聴いている曲を取得
     */
    func fetchCurrentlyPlayingTrack(accessToken: String) async throws -> TrackInfo {
        let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get currently playing track"])
        }
        
        let currentTrackInfo = try JSONDecoder().decode(TrackInfo.self, from: data)
        return currentTrackInfo
    }
    
    /*
     投稿を保存
     */
    func postTrack(trackInfo: TrackInfo, postComment: String) {
        let db = Firestore.firestore()
        
        // Get the current user's UID
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Generate a random post ID
        let postId = String(format: "%010d", abs(Int.random(in: 0...9999999999)))
        
        // 保存するデータの辞書を作成
        let postData: [String: Any] = [
            "postId": postId,  // Add the random post ID
            "postUser": uid, // ポストしたユーザーのid
            "name": trackInfo.item.name,    // 曲名
            "trackURI": trackInfo.item.uri,  // trackURI
            "artists": trackInfo.item.artists.map { $0.name }, // アーティスト名の配列
            "albumImageUrl": trackInfo.item.album.images.first?.url ?? "", // アルバム画像のURL
            "postComment": postComment, // 投稿コメント（nilの場合は空文字列）
            "trackDuration": trackInfo.item.duration_ms,    // 曲の長さ（秒）
            "postTime": Timestamp(date: Date()), // 投稿時間
            "likeCount": 0,  // いいね数の初期値を0に設定
            "previewURL": trackInfo.item.preview_url ?? ""
        ]
        
        
        // Firestoreのpostsコレクションにデータを保存
        db.collection("posts").document(postId).setData(postData) { error in
            if let error = error {
            } else {
            }
        }
    }
    
    /*
     投稿を取得
     */
    func getPost() {
        let db = Firestore.firestore()
        db.collection("posts").getDocuments { (querySnapshot, error) in
            if let error = error {
                return
            }
            
            // Firestoreから取得したデータをPostModelに変換
            if let documents = querySnapshot?.documents {
                self.posts = documents.compactMap { doc -> PostModel? in
                    do {
                        let post = try doc.data(as: PostModel.self)
                        
                        // DateFormatterでpostTimeをフォーマット
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP")
                        dateFormatter.dateFormat = "M月d日 HH時" // 月、日、時間を抽出
                        
                        // postTimeからフォーマットした日付を取得
                        let formattedDate = dateFormatter.string(from: post.postTime)
                        
                        return post
                    } catch {
                        return nil
                    }
                }
            }
        }
    }
    
    func getPostForPostId(postIds: [String]) async throws -> [PostModel] {
        // 空の配列の場合は早期リターン
        if postIds.isEmpty {
            return []
        }
        let db = Firestore.firestore()
        var posts: [PostModel] = []
        let postsRef = db.collection("posts")
        
        // TaskGroupを使用して並行処理
        try await withThrowingTaskGroup(of: PostModel?.self) { group in
            // 各postIdに対してタスクを作成
            for postId in postIds {
                group.addTask {
                    do {
                        let postDoc = try await postsRef.document(postId).getDocument()
                        guard let postData = postDoc.data() else { return nil }
                        
                        return PostModel(
                            id: postDoc.documentID,
                            name: postData["name"] as? String ?? "",
                            trackURI: postData["trackURI"] as? String ?? "",
                            artists: postData["artists"] as? [String] ?? [],
                            albumImageUrl: postData["albumImageUrl"] as? String ?? "",
                            postComment: postData["postComment"] as? String ?? "",
                            trackDuration: postData["trackDuration"] as? Int ?? 0,
                            postTime: (postData["postTime"] as? Timestamp)?.dateValue() ?? Date(),
                            postUser: postData["postUser"] as? String ?? "",
                            likeCount: postData["likeCount"] as? Int ?? 0,
                            previewURL: postData["previewURL"] as? String ?? ""
                        )
                    } catch {
                        return nil
                    }
                }
            }
            
            // 結果を収集
            for try await post in group {
                if let post = post {
                    posts.append(post)
                }
            }
        }
        
        // 取得した順序をpostIdsの順序と合わせる
        return posts.sorted { post1, post2 in
            guard let index1 = postIds.firstIndex(of: post1.id ?? ""),
                  let index2 = postIds.firstIndex(of: post2.id ?? "") else {
                return false
            }
            return index1 < index2
        }
    }
    
    func getUsersPost(for uid: String) async throws {
        let db = Firestore.firestore()
        // "uid" に一致する投稿のみを取得
        let querySnapshot = try await db.collection("posts")
            .whereField("postUser", isEqualTo: uid)
            .getDocuments()
        
        // Firestoreから取得したデータをPostModelに変換
        let fetchedPosts = querySnapshot.documents.compactMap { doc -> PostModel? in
            do {
                let posts = try doc.data(as: PostModel.self)
                // 取得した post をそのまま返す
                return posts
            } catch {
                return nil
            }
        }
        
        // メインスレッドでUIを更新
        DispatchQueue.main.async {
            self.posts = fetchedPosts
        }
    }
    
    // 投稿を削除する関数
    func deletePost(postId: String?) async throws {
        guard let postId = postId else {
            throw NSError(domain: "DeleteError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid post ID"])
        }
        
        let db = Firestore.firestore()
        
        // まずコメントのサブコレクションを削除
        let commentsSnapshot = try await db.collection("posts").document(postId).collection("comments").getDocuments()
        
        // バッチ処理を作成
        let batch = db.batch()
        
        // コメントの削除をバッチに追加
        for comment in commentsSnapshot.documents {
            let commentRef = db.collection("posts").document(postId).collection("comments").document(comment.documentID)
            batch.deleteDocument(commentRef)
        }
        
        // 投稿自体の削除をバッチに追加
        let postRef = db.collection("posts").document(postId)
        batch.deleteDocument(postRef)
        
        // バッチ処理を実行
        try await batch.commit()
        
        // 成功したら、ローカルの投稿リストから削除
        await MainActor.run {
            self.posts.removeAll { $0.id == postId }
        }
    }
    
    
    func getUserInfo(userId: String) async throws -> UserProfile {
        let db = Firestore.firestore()
        
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let userData = document.data() else {
            throw NSError(domain: "UserInfoError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        
        let userName = userData["userName"] as? String ?? "User"
        let bio = userData["bio"] as? String ?? "bio"
        let iconURL = userData["profileImageURL"] as? String ?? "iconURL"
        let userId = userData["uid"] as? String ?? "uid"
        
        let userInfo = UserProfile(name: userName, bio: bio, profileImageURL: iconURL, uid: userId)
        
        return userInfo
        
        /*
         投稿にいいねを追加
         */
        func likePost(postId: String) {
            let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            let likedUserRef = db.collection("posts").document(postId).collection("LikedUsers").document(uid)
            
            likedUserRef.setData(["likedAt": Timestamp(date: Date())]) { error in
                if let error = error {
                } else {
                    
                    // いいね数を更新
                    let postRef = db.collection("posts").document(postId)
                    postRef.updateData([
                        "likeCount": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                        } else {
                        }
                    }
                }
            }
        }
        
        /*
         投稿のいいねを解除
         */
        func unlikePost(postId: String) {
            let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            let likedUserRef = db.collection("posts").document(postId).collection("LikedUsers").document(uid)
            
            likedUserRef.delete() { error in
                if let error = error {
                } else {
                    
                    // いいね数を更新
                    let postRef = db.collection("posts").document(postId)
                    postRef.updateData([
                        "likeCount": FieldValue.increment(Int64(-1))
                    ]) { error in
                        if let error = error {
                        } else {
                        }
                    }
                }
            }
        }
        
        
        
        /*
         ユーザーが投稿にいいねしているかチェック
         */
        func checkIfLiked(postId: String, completion: @escaping (Bool) -> Void) {
            let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(false)
                return
            }
            
            let likedUserRef = db.collection("posts").document(postId).collection("LikedUsers").document(uid)
            
            likedUserRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}
