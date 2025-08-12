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
    private var db = Firestore.firestore()
    
    func fetchComments(for postId: String) {
        db.collection("posts").document(postId).collection("comments")
            .order(by: "commentTime", descending: true)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("コメント取得エラー: \(error?.localizedDescription ?? "不明なエラー")")
                    return
                }
                
                self.comments = documents.compactMap { queryDocumentSnapshot -> CommentModel? in
                    return try? queryDocumentSnapshot.data(as: CommentModel.self)
                }
            }
    }
    
    func addComment(to postId: String, userId: String, userName: String, userIconURL: String) {
        let newComment = CommentModel(userId: userId, userName: userName, userIconURL: userIconURL, content: self.newComment, commentTime: Date())
        
        do {
            _ = try db.collection("posts").document(postId).collection("comments").addDocument(from: newComment)
            self.newComment = ""
        } catch {
            print("Firestore へのコメント追加エラー: \(error)")
        }
    }
    
    func likeComment(_ comment: CommentModel, in postId: String) {
        guard let commentId = comment.id else { return }
        let ref = db.collection("posts").document(postId).collection("comments").document(commentId)
        ref.updateData([
            "likes": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("ドキュメントの更新中にエラーが発生しました: \(error)")
            }
        }
    }
}

extension CommentModel: Equatable {
    static func == (lhs: CommentModel, rhs: CommentModel) -> Bool {
        lhs.id == rhs.id
    }
}
