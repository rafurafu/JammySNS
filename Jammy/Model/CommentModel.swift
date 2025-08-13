//
//  CommentModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/07/08.
//

import Foundation
import Firebase
import FirebaseFirestore

struct CommentModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userIconURL: String
    var content: String
    var commentTime: Date
}

class CommentViewModel: ObservableObject {
    @Published var comments: [CommentModel] = []
    @Published var newComment: String = ""
    @Published var isLoading: Bool = false
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchComments(for postId: String) {
        // 既存のリスナーを削除
        listener?.remove()
        
        // ローディング開始
        DispatchQueue.main.async {
            self.isLoading = true
            self.comments = []
        }
        
        // 新しいリスナーを設定
        listener = db.collection("posts").document(postId).collection("comments")
            .order(by: "commentTime", descending: true)
            .addSnapshotListener { (querySnapshot, error) in
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                if let error = error {
                    print("Error fetching comments: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No comments found for post: \(postId)")
                    DispatchQueue.main.async {
                        self.comments = []
                    }
                    return
                }
                
                print("Fetched \(documents.count) comments for post: \(postId)")
                
                DispatchQueue.main.async {
                    self.comments = documents.compactMap { queryDocumentSnapshot -> CommentModel? in
                        return try? queryDocumentSnapshot.data(as: CommentModel.self)
                    }
                    print("Comments updated: \(self.comments.count) items")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
    
    func addComment(to postId: String, userId: String, userName: String, userIconURL: String) {
        let newComment = CommentModel(userId: userId, userName: userName, userIconURL: userIconURL, content: self.newComment, commentTime: Date())
        
        do {
            _ = try db.collection("posts").document(postId).collection("comments").addDocument(from: newComment)
            self.newComment = ""
        } catch {
        }
    }
    
    func likeComment(_ comment: CommentModel, in postId: String) {
        guard let commentId = comment.id else { return }
        let ref = db.collection("posts").document(postId).collection("comments").document(commentId)
        ref.updateData([
            "likes": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
            }
        }
    }
}

extension CommentModel: Equatable {
    static func == (lhs: CommentModel, rhs: CommentModel) -> Bool {
        lhs.id == rhs.id
    }
}
