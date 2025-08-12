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
        VStack (alignment: .leading){
            
            Divider()
            
            HStack(alignment: .top, spacing: 15) {
                AsyncImage(url: URL(string: comment.userIconURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.userName)
                        .font(.headline)
                        .foregroundColor(Color.primary)
                        .padding(.top, 4)
                    
                    Text(comment.content)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                }
            }
            .frame(width: .infinity)
            .frame(minHeight: 70)
            .padding(.leading, 10)
            
        }
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
