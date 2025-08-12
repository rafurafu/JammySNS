//新規登録

import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @StateObject private var viewModel = AuthViewModel()
    @State private var errorMessage: String?    // 新規登録エラーメッセージ
    @State private var showingError = false
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
            VStack (alignment: .center){
                Text("Jammy")
                    .font(.system(size: 75, weight: .bold))
                    .foregroundStyle(fontColor)
                    .padding(.bottom, 100)
                
                
                VStack(spacing: 20) {
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onTapGesture { focusField = true }
                    
                    CustomSecureField(text: $password, isPasswordVisible: $isPasswordVisible)
                        .keyboardType(.asciiCapable).keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .onTapGesture { focusField = true }
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.signUp(email: email, password: password)
                            } catch AuthError.signUpError(let message) {
                                errorMessage = message
                                showingError = true
                            } catch {
                                errorMessage = "予期せぬエラーが発生しました"
                                showingError = true
                            }
                        }
                    } label: {
                        Text("新規登録")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(fontColor)
                            .cornerRadius(10)
                    }
                    
                    Text("※ 記号と数字は必須です。\n※ パスワードの文字数（6～30文字)")
                        .frame(maxWidth: .infinity,alignment: .leading)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(errorMessage ?? "エラーが発生しました")
            }
        }
    }
    
}

#Preview {
    SignUpView()
}
