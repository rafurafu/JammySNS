//
//  MainCommentView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/06/04.
//

import SwiftUI

struct MainCommentView: View {
    var post: PostModel
    @EnvironmentObject var authManager: AuthViewModel
    @StateObject private var viewModel = CommentViewModel()
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.comments) { comment in
                        MainCommentRow(comment: comment)
                    }
                }
            }
            
            .padding()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        
        
        Divider()
        
        HStack(spacing: 10) {
            TextField("コメントを入力...", text: $viewModel.newComment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .onTapGesture {
                    isTextFieldFocused = true
                }
                //.simultaneousGesture(TapGesture().onEnded {})
            
            Button(action: {
                if let postId = post.id {
                    viewModel.addComment(to: postId, userId: authManager.myUserID ?? "", userName: authManager.myUserInfo?.name ?? "不明なユーザー", userIconURL: authManager.myUserInfo?.profileImageURL ?? "")
                    isTextFieldFocused = false
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            // キーボードがViewを押し上げないようにする
            .background(Color(UIColor.systemBackground))
        }
        .padding(20)
        //.ignoresSafeArea(.keyboard)
        .onAppear {
            if let postId = post.id {
                viewModel.fetchComments(for: postId)
            }
        }
    }
    
}

#Preview {
    MainCommentView(post: PostModel(name: "Sign", trackURI: "spotify:track:5ZLkGLEYYDlgcDXK6A2vYO", artists: ["Mr.Children"], albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273354761925b7a53bf12c6e07c", postComment: "aaa", trackDuration: 243000, postTime: Date(), postUser: "zuIyF0BTmGdVDH8JcTycN6qjbVO2", likeCount: 12, previewURL: ""))
}
