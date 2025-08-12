import SwiftUI

struct SettingPrivacyView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading, // 左から始める
        endPoint: .trailing // 右
    )
    @State private var isContactSyncEnabled: Bool = true
    @Environment(\.colorScheme) var colorScheme
    //@EnvironmentObject var userState: User

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 90)
            
            Text("プライバシー")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            Group {
                VStack(spacing: 1) {
                    NavigationLink(destination: SettingPrivacyBlockView()) {
                        HStack {
                            Text("ブロックしたユーザー")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                    }
                    

                }
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black) //設定のフォントの色変えるやつ
            .font(.headline)
            .fontWeight(.medium)

        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    SettingPrivacyView()
}
