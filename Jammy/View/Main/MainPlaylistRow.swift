//
//  MainPlaylistRow.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/16.
//

import SwiftUI

struct MainPlaylistRow: View {
    let playlist: PlaylistModel  // 単一のプレイリスト
    @Binding var selectedPlaylists: Set<String>
    @State private var checkBox: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // チェックボックス
            Button(action: {
                checkBox.toggle()
                if checkBox {
                    selectedPlaylists.insert(playlist.id)
                } else {
                    selectedPlaylists.remove(playlist.id)
                }
            }) {
                Image(systemName: checkBox ? "checkmark.square" : "square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .foregroundColor(Color.black)
            }
            
            // プレイリスト画像
            if let imageUrl = playlist.images.first?.url {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                } placeholder: {
                    ProgressView()
                        .frame(width: 80, height: 80)
                }
            }
            
            // プレイリスト名
            Text(playlist.name)
                .font(.title2)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
        }
        .padding(.vertical, 10)
    }
}
