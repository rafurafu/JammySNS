//
//  BlockViewModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/12/01.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class BlockViewModel: ObservableObject {
    @Published var blockedUsers: Set<String> = []
    private let db = Firestore.firestore()
    
    init() {
        loadBlockedUsers()
    }
    
    // ブロックユーザーリストを読み込む
    func loadBlockedUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(currentUserId).collection("blockedUsers")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error loading blocked users: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                self.blockedUsers = Set(documents.compactMap { $0.documentID })
            }
    }
    
    // ユーザーをブロックする
    func blockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let blockRef = db.collection("users").document(currentUserId)
            .collection("blockedUsers").document(userId)
        
        try await blockRef.setData([
            "blockedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // ブロック解除する
    func unblockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let blockRef = db.collection("users").document(currentUserId)
            .collection("blockedUsers").document(userId)
        
        try await blockRef.delete()
    }
    
    // ユーザーがブロックされているかチェック
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }
}
