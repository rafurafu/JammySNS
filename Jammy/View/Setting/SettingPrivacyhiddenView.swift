/*import SwiftUI

struct HiddenUser: Identifiable {
    let id: String
    let name: String
    let iconName: String
}

struct SettingPrivacyhiddenView: View {
    @State private var hiddenUsers = [
        HiddenUser(id: "001", name: "田中太郎", iconName: "person.circle.fill"),
        HiddenUser(id: "002", name: "佐藤花子", iconName: "person.circle.fill"),
        HiddenUser(id: "003", name: "鈴木一郎", iconName: "person.circle.fill"),
        HiddenUser(id: "004", name: "高橋美咲", iconName: "person.circle.fill"),
        HiddenUser(id: "005", name: "伊藤健太", iconName: "person.circle.fill")
    ]
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userState: User
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 90)
            
            Text("非表示のユーザー")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(hiddenUsers) { user in
                        HiddenUserCard(user: user, unhideAction: { unhideUser(user) })
                    }
                }
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.97))
        .edgesIgnoringSafeArea(.top)
    }
    
    func unhideUser(_ user: HiddenUser) {
        hiddenUsers.removeAll { $0.id == user.id }
    }
}

struct HiddenUserCard: View {
    let user: HiddenUser
    let unhideAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: user.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text("ID: \(user.id)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: unhideAction) {
                Text("表示する")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SettingPrivacyhiddenView()
}*/
