//パスワード変更画面

import SwiftUI

struct ResetPasswordView: View {
    @State private var email: String = ""
    @StateObject var viewModel = AuthViewModel()

    var body: some View {
        VStack {
            TextField("メールアドレス", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("パスワード変更メール送信") {
                viewModel.resetPassword(email: email)
            }
        }
    }
}
