//
//  MainFollowingView.swift
//  Jammy
//
//  フォロー中のユーザーの投稿を表示するビュー
//

import SwiftUI

struct MainFollowingView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("Coming Soon")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("フォロー中のユーザーの投稿表示機能は\n近日公開予定です")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
    }
}