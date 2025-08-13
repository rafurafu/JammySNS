//
//  LikeModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/07/08.
//

import Foundation
import FirebaseFirestore

struct PostModel: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String? // FirestoreのドキュメントID
    var name: String
    var trackURI: String
    var artists: [String]
    var albumImageUrl: String
    var postComment: String
    var trackDuration: Int 
    var postTime: Date
    var postUser: String
    var likeCount: Int
    var previewURL: String
    var imageURL: String? // 投稿に添付された画像のURL
}
