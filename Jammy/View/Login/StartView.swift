import SwiftUI

struct StartView: View {
    @Environment(\.dismiss) private var dismiss
    @State var isShowLogin = false
    @StateObject var viewModel = AuthViewModel()
   
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Jammy")
                    .font(.system(size: 75, weight: .bold))
                    .foregroundStyle(fontColor)
                    .padding(.top, 60)
                    .offset(y: 50)
                
                Spacer()
                
                NavigationLink(destination: SignInView(viewModel: viewModel)) {
                    Text("ログイン")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: SignUpView()) {
                    Text("新規登録")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(spacing: 5) {
                        Text("登録された時点で、本アプリの利用規約および")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    
                        Text("プライバシーポリシーに同意したものとみなします。")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        Button(action: {
                            // Show Terms of Service
                        }) {
                            NavigationLink(destination: SettingPolicyView()) {
                                Text("利用規約")
                                    .font(.footnote)
                                    .underline()
                            }
                        }
                        Text("•")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Button(action: {
                            // Show Privacy Policy
                        }) {
                            NavigationLink(destination: SettingPolicyView()) {
                                Text("プライバシーポリシー")
                                    .font(.footnote)
                                    .underline()
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}


