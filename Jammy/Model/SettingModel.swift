//
//  File.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/07/09.
//

import Foundation
import FirebaseFirestore

struct SettingsModel: Identifiable {
    let id: String  //主キー
    let userId: String  // userId
    var blockedUserIds: [String]    // ブロックしたユーザーIDs
    var commentNoticeEnabled: Bool  // 投稿にコメントされた際の通知
    var reactionNoticeEnabled: Bool  //リアクションされた際の通知
    var friendRequestNoticeEnabled: Bool  //followのリクエスト通知
    var friendPostNoticeEnabled: Bool  //フォロー中の投稿の通知
    
    // 情報に欠陥がある場合nilを返す
    init?(document: QueryDocumentSnapshot) {
        guard
            let userId = document.data()["user_id"] as? String,
            let blockedUserIds = document.data()["blocked_user_ids"] as? [String],
            let commentNoticeEnabled = document.data()["comment_notice_enabled"] as? Bool,
            let reactionNoticeEnabled = document.data()["reaction_notice_enabled"] as? Bool,
            let friendRequestNoticeEnabled = document.data()["friend_request_notice_enabled"] as? Bool,
            let friendPostNoticeEnabled = document.data()["friend_post_notice_enabled"] as? Bool
        else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.blockedUserIds = blockedUserIds
        self.commentNoticeEnabled = commentNoticeEnabled
        self.reactionNoticeEnabled = reactionNoticeEnabled
        self.friendRequestNoticeEnabled = friendRequestNoticeEnabled
        self.friendPostNoticeEnabled = friendPostNoticeEnabled
    }
}
