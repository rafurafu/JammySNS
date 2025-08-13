//
//  MainCommentRow.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/10/15.
//

import SwiftUI

struct MainCommentRow: View {
    var comment: CommentModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像
            AsyncImage(url: URL(string: comment.userIconURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
            }
            
            // コメント内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text(formatDate(comment.commentTime))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MainCommentRow(comment: CommentModel(userId: "zuIyF0BTmGdVDH8JcTycN6qjbVO2", userName: "ユーザー名", userIconURL: "https://i.scdn.co/image/ab67616d0000b273354761925b7a53bf12c6e07c", content: "content", commentTime: Date()))
}
