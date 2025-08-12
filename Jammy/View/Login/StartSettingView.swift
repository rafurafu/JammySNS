//名前決めるページ

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StartSettingView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    @Environment(\.colorScheme) var colorScheme
    @State var name: String = ""
    @StateObject var viewModel = AuthViewModel()
    @State private var navigateToSpotifyAuth = false
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    //@StateObject var spotifyManager = SpotifyMusicManager()
    //@StateObject var userState: User = User(id: "testId", name: "testName", email: "test@test.com", password: "testPass")
    
    
    func saveNameToFirestore() {
        viewModel.updateUserName(name) { success in
            if success {
                navigateToSpotifyAuth = true
            } else {
                print("ユーザー名の更新に失敗しました")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .center) {
                Text("Jammy")
                    .font(.system(size: 75))
                    .fontWeight(.bold)
                    .foregroundColor(.clear)
                    .overlay(
                        fontColor
                            .mask(
                                Text("Jammy")
                                    .font(.system(size: 75))
                                    .fontWeight(.bold)
                            )
                    )
                    .padding(.bottom,20)
                Text("あなたの名前を教えてください!!")
                    .foregroundColor(.clear)
                    .overlay(
                        fontColor
                            .mask(
                                Text("あなたの名前を教えてください!!")
                            )
                    )
                    .padding(.bottom,60)
                
                TextField("ユーザー名", text: $name, axis: .vertical)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                
                Button("名前を保存") {
                    saveNameToFirestore()
                }
                .padding()
                .background(fontColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                }
            }
        }
    }

