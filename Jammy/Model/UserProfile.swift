//
//  UserProfile.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/23.
//
import SwiftUI
import FirebaseFirestore

// ユーザープロフィール構造体
struct UserProfile: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let name: String
    let bio: String
    let profileImageURL: String?
    let uid: String
    var favoritePosts: [String]?
    
    init(name: String, bio: String, profileImageURL: String?, uid: String, favoritePosts: [String]? = nil) {
        self.id = uid
        self.name = name
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.uid = uid
        self.favoritePosts = favoritePosts
    }
    
    // Firestoreのドキュメントからデコードするための初期化メソッド
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let uid = try container.decode(String.self, forKey: .uid)
        self.id = uid
        self.uid = uid
        self.name = try container.decode(String.self, forKey: .name)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        self.favoritePosts = try container.decodeIfPresent([String].self, forKey: .favoritePosts)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case bio
        case profileImageURL
        case uid
        case favoritePosts
    }
}
