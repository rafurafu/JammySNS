//ログイン

import SwiftUI

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @StateObject var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isShowAlert = false
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @FocusState private var focusField: Bool?
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Jammy")
                    .font(.system(size: 75, weight: .bold))
                    .foregroundStyle(fontColor)
                    .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.asciiCapable).keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .onTapGesture { focusField = true }
                    
                    CustomSecureField(text: $password, isPasswordVisible: $isPasswordVisible)
                        .keyboardType(.asciiCapable).keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .onTapGesture { focusField = true }
                    
                    Button(action: {
                        viewModel.signIn(email: email, password: password)
                        
                        
                    }) {
                        Text("ログイン")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(fontColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                
                NavigationLink(destination: ResetPasswordView(viewModel: viewModel)) {
                    Text("パスワードをお忘れの方")
                        .foregroundColor(Color(red: 0.07, green: 0.21, blue: 0.49))
                        .padding(.top, 16)
                }
                
                Spacer()
            }
        }
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    @Binding var isPasswordVisible: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isPasswordVisible {
                    TextField("パスワード", text: $text)
                } else {
                    SecureField("パスワード", text: $text)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.07, green: 0.21, blue: 0.49), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(Color(red: 0.07, green: 0.21, blue: 0.49))
            }
            .padding(.trailing, 10)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.07, green: 0.21, blue: 0.49), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}
