//
//  AppDestination.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/23.
//

import Foundation

enum AppNavigationDestination: Hashable {
    case post(PostModel)
    case postsGrid(UserProfile)
    case profile(UserProfile)
    case selfProfile
    case comments(PostModel)
    case playlist([PlaylistModel], PostModel)
    case artist([FavoriteArtist])
    case likesGrid([PostModel])
    case report(reportedUserId: String, postId: String?)
}
