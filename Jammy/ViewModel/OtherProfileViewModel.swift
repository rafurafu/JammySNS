//
//  FFmodelView.swift
//  Jammy
//
//  Created by adachikouki on 2024/10/11.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class OtherProfileViewModel: ObservableObject {
    // Published プロパティ
    @Published var isFollowing = false
    @Published var followingCount = 0
    @Published var followersCount = 0
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let db = Firestore.firestore()
    
    // フォロー状態とカウントを取得
    func loadFollowData(for targetUserId: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // フォロー状態の確認
            let followingDoc = try await db.collection("users")
                .document(currentUserId)
                .collection("social")
                .document("following")
                .getDocument()
            
            if let data = followingDoc.data(),
               let followingUsers = data["userIds"] as? [String] {
                await MainActor.run {
                    self.isFollowing = followingUsers.contains(targetUserId)
                }
            }
            
            // フォロワー数とフォロー数を取得
            let userDoc = try await db.collection("users")
                .document(targetUserId)
                .getDocument()
            
            if let data = userDoc.data() {
                await MainActor.run {
                    self.followersCount = data["followersCount"] as? Int ?? 0
                    self.followingCount = data["followingCount"] as? Int ?? 0
                }
            }
        } catch {
            print("Error loading follow data: \(error)")
        }
    }
    
    // フォロー/アンフォロー処理
    func toggleFollow(for targetUserId: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showError = true
            errorMessage = "ログインが必要です"
            return
        }
        
        do {
            if isFollowing {
                try await unfollow(targetUserId: targetUserId, currentUserId: currentUserId)
            } else {
                try await follow(targetUserId: targetUserId, currentUserId: currentUserId)
            }
            
            await loadFollowData(for: targetUserId)
        } catch {
            await MainActor.run {
                self.showError = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func follow(targetUserId: String, currentUserId: String) async throws {
        let batch = db.batch()
        
        // 自分のフォロー一覧に追加
        let followingRef = db.collection("users")
            .document(currentUserId)
            .collection("social")
            .document("following")
        
        batch.setData([
            "userIds": FieldValue.arrayUnion([targetUserId])
        ], forDocument: followingRef, merge: true)
        
        // 相手のフォロワー一覧に追加
        let followerRef = db.collection("users")
            .document(targetUserId)
            .collection("social")
            .document("followers")
        
        batch.setData([
            "userIds": FieldValue.arrayUnion([currentUserId])
        ], forDocument: followerRef, merge: true)
        
        // カウンターの更新
        let currentUserRef = db.collection("users").document(currentUserId)
        let targetUserRef = db.collection("users").document(targetUserId)
        
        batch.updateData([
            "followingCount": FieldValue.increment(Int64(1))
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followersCount": FieldValue.increment(Int64(1))
        ], forDocument: targetUserRef)
        
        // 通知の作成
        let notificationRef = db.collection("users")
            .document(targetUserId)
            .collection("notifications")
            .document()
        
        let notification: [String: Any] = [
            "type": "follow",
            "fromUserId": currentUserId,
            "createdAt": FieldValue.serverTimestamp(),
            "read": false
        ]
        
        batch.setData(notification, forDocument: notificationRef)
        
        try await batch.commit()
    }
    
    private func unfollow(targetUserId: String, currentUserId: String) async throws {
        let batch = db.batch()
        
        // 自分のフォロー一覧から削除
        let followingRef = db.collection("users")
            .document(currentUserId)
            .collection("social")
            .document("following")
        
        batch.updateData([
            "userIds": FieldValue.arrayRemove([targetUserId])
        ], forDocument: followingRef)
        
        // 相手のフォロワー一覧から削除
        let followerRef = db.collection("users")
            .document(targetUserId)
            .collection("social")
            .document("followers")
        
        batch.updateData([
            "userIds": FieldValue.arrayRemove([currentUserId])
        ], forDocument: followerRef)
        
        // カウンターの更新
        let currentUserRef = db.collection("users").document(currentUserId)
        let targetUserRef = db.collection("users").document(targetUserId)
        
        batch.updateData([
            "followingCount": FieldValue.increment(Int64(-1))
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followersCount": FieldValue.increment(Int64(-1))
        ], forDocument: targetUserRef)
        
        try await batch.commit()
    }
    
    // フォロワーリストを取得
    func fetchFollowers(for userId: String) async throws -> [UserProfile] {
        let followerDoc = try await db.collection("users")
            .document(userId)
            .collection("social")
            .document("followers")
            .getDocument()
        
        guard let data = followerDoc.data(),
              let followerIds = data["userIds"] as? [String] else {
            return []
        }
        
        var followers: [UserProfile] = []
        for followerId in followerIds {
            let userDoc = try await db.collection("users")
                .document(followerId)
                .getDocument()
            
            if let userData = userDoc.data() {
                let follower = UserProfile(
                    name: userData["userName"] as? String ?? "",
                    bio: userData["bio"] as? String ?? "",
                    profileImageURL: userData["profileImageURL"] as? String ?? "",
                    uid: followerId
                )
                followers.append(follower)
            }
        }
        
        return followers
    }
    
    // フォロー中のユーザーリストを取得
    func fetchFollowing(for userId: String) async throws -> [UserProfile] {
        let followingDoc = try await db.collection("users")
            .document(userId)
            .collection("social")
            .document("following")
            .getDocument()
        
        guard let data = followingDoc.data(),
              let followingIds = data["userIds"] as? [String] else {
            return []
        }
        
        var following: [UserProfile] = []
        for followingId in followingIds {
            let userDoc = try await db.collection("users")
                .document(followingId)
                .getDocument()
            
            if let userData = userDoc.data() {
                let followingUser = UserProfile(
                    name: userData["userName"] as? String ?? "",
                    bio: userData["bio"] as? String ?? "",
                    profileImageURL: userData["profileImageURL"] as? String ?? "",
                    uid: followingId
                )
                following.append(followingUser)
            }
        }
        
        return following
    }
}
