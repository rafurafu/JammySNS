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
    @State private var hasLoadedComments = false
    
    var body: some View {
        VStack(spacing: 0) {
            // コメント一覧
            ScrollView {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("コメントを読み込み中...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 80)
                } else if viewModel.comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("まだコメントがありません")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Text("最初のコメントを投稿してみましょう！")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.comments) { comment in
                            MainCommentRow(comment: comment)
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.vertical, 16)
                }
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
            
            // 区切り線
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // コメント入力フォーム
            HStack(spacing: 12) {
                TextField("コメントを入力...", text: $viewModel.newComment, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...4)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        submitComment()
                    }
                
                Button(action: {
                    submitComment()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(viewModel.newComment.isEmpty ? .gray : .blue)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(UIColor.systemGray6)))
                }
                .disabled(viewModel.newComment.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
        }
        .onAppear {
            print("MainCommentView appeared for post: \(post.id ?? "unknown")")
            if let postId = post.id, !hasLoadedComments {
                print("Fetching comments for post: \(postId)")
                viewModel.fetchComments(for: postId)
                hasLoadedComments = true
            }
        }
        .onChange(of: post.id) { oldValue, newValue in
            if let postId = newValue, postId != oldValue {
                hasLoadedComments = false
                viewModel.fetchComments(for: postId)
                hasLoadedComments = true
            }
        }
    }
    
    private func submitComment() {
        guard !viewModel.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let postId = post.id else { return }
        
        viewModel.addComment(
            to: postId,
            userId: authManager.myUserID ?? "",
            userName: authManager.myUserInfo?.name ?? "不明なユーザー",
            userIconURL: authManager.myUserInfo?.profileImageURL ?? ""
        )
        isTextFieldFocused = false
    }
}

#Preview {
    MainCommentView(post: PostModel(name: "Sign", trackURI: "spotify:track:5ZLkGLEYYDlgcDXK6A2vYO", artists: ["Mr.Children"], albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273354761925b7a53bf12c6e07c", postComment: "aaa", trackDuration: 243000, postTime: Date(), postUser: "zuIyF0BTmGdVDH8JcTycN6qjbVO2", likeCount: 12, previewURL: ""))
}
