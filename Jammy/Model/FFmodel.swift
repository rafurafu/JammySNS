//
//  FFmodel.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/29.
//

import Foundation
import FirebaseFirestore

// ユーザー間のフォロー関係を表すモデル
struct SocialConnection: Codable, Identifiable {
    var id: String { followerId + followingId }
    let followerId: String      // フォローしているユーザーのID
    let followingId: String     // フォローされているユーザーのID
    let timestamp: Date         // フォロー開始日時
}

// フォロー/フォロワー統計情報
struct SocialStats: Codable {
    let followersCount: Int
    let followingCount: Int
}

// フォロー関係の変更イベントを表す列挙型
enum SocialGraphEvent {
    case followed(userId: String)
    case unfollowed(userId: String)
    case followerAdded(userId: String)
    case followerRemoved(userId: String)
}

// フォロー/フォロワーの並び替えオプション
enum SocialSortOption {
    case nameAscending
    case nameDescending
    case dateAscending
    case dateDescending
}

// フォロー/フォロワーのフィルタリングオプション
enum SocialFilterOption {
    case all
    case mutualFollows
    case notFollowingBack
    case notFollowedBack
}
