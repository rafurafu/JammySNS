//通知

import SwiftUI

struct SettingNotificationView : View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading, // 左から始める
        endPoint: .trailing // 右
    )
    @State private var isCommentEnabled: Bool = true
    @State private var isReactionEnabled: Bool = true
    @State private var isFriendRequestEnabled: Bool = true
    @State private var isMentionAndTagEnabled: Bool = true
    @State private var isFriendPostEnabled: Bool = true
    @Environment(\.colorScheme) var colorScheme
    //@EnvironmentObject var userState: User

    let backgroundColor = Color.white

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 90)
                
                Text("通知")
                    .fontWeight(.bold)
                    .font(.headline)
                    .foregroundStyle(fontColor)
                    .padding(.bottom, 20)
                
                
                VStack(spacing: 1) {
                    HStack {
                        Text("コメント")
                        Spacer()
                        Toggle("", isOn: $isCommentEnabled)
                            .labelsHidden()
                            
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    
                    HStack {
                        Text("リアクション")
                        Spacer()
                        Toggle("", isOn: $isReactionEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    
                    HStack {
                        Text("友達リクエスト")
                        Spacer()
                        Toggle("", isOn: $isFriendRequestEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    
                    HStack {
                        Text("友達の投稿")
                        Spacer()
                        Toggle("", isOn: $isFriendPostEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
            .edgesIgnoringSafeArea(.top)
        }
        .foregroundColor(colorScheme == .dark ? Color.white : Color.black) //設定のフォントの色変えるやつ
        .font(.headline)
        .fontWeight(.medium)
    }
}

#Preview {
    SettingNotificationView()
}

