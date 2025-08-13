//
//  ProfileImageView.swift
//  Jammy
//
//  再利用可能なプロフィール画像コンポーネント
//

import SwiftUI

struct ProfileImageView: View {
    let profileImageURL: String?
    let size: CGFloat
    
    var body: some View {
        AsyncImage(url: URL(string: profileImageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
        }
    }
}

struct AlbumImageView: View {
    let albumImageUrl: String
    let size: CGFloat
    let cornerRadius: CGFloat
    
    init(albumImageUrl: String, size: CGFloat, cornerRadius: CGFloat = 8) {
        self.albumImageUrl = albumImageUrl
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        AsyncImage(url: URL(string: albumImageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .cornerRadius(cornerRadius)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
                .cornerRadius(cornerRadius)
        }
    }
}