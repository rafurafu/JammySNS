//メールアドレス

import SwiftUI
import FirebaseAuth

struct SettingEmailView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var currentEmail: String = ""
    @State private var newEmail: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showPassword: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 90)
            
            Text("メールアドレス設定")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 20) {
                // 現在のメールアドレス（表示のみ）
                VStack(alignment: .leading, spacing: 10) {
                    Text("現在のメールアドレス")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.headline)
                    Text(currentEmail)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                
                // 新しいメールアドレス入力フィールド
                VStack(alignment: .leading, spacing: 10) {
                    Text("新しいメールアドレス")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.headline)
                    TextField("新しいメールアドレスを入力", text: $newEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                
                // パスワード入力フィールド
                VStack(alignment: .leading, spacing: 10) {
                    Text("パスワード(確認用)")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.headline)
                    
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            TextField("パスワードを入力", text: $password)
                                .textInputAutocapitalization(.never)
                                .padding()
                        } else {
                            SecureField("パスワードを入力", text: $password)
                                .textInputAutocapitalization(.never)
                                .padding()
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // 保存ボタン
            Button(action: updateEmail) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isLoading ?
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) : fontColor
            )
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .disabled(isLoading || newEmail.isEmpty || password.isEmpty)
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
        .onAppear(perform: loadCurrentEmail)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("お知らせ"),
                message: Text(alertMessage),
                primaryButton: .default(Text("確認")) {
                    if alertMessage.contains("確認メール") {
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
    }
    
    private func loadCurrentEmail() {
        if let email = Auth.auth().currentUser?.email {
            currentEmail = email
        }
    }
    
    private func updateEmail() {
        isLoading = true
        
        // 再認証を行う
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            isLoading = false
            alertMessage = "ユーザー情報の取得に失敗しました"
            showAlert = true
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "認証に失敗しました：パスワードを確認してください"
                    showAlert = true
                }
                return
            }
            
            // メールアドレスの更新プロセスを開始
            authViewModel.updateEmail(newEmail: newEmail) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        alertMessage = """
                            確認メールを現在のメールアドレスに送信しました。
                            
                            1. 受信した確認メールのリンクをクリックして確認を完了してください
                            2. 確認完了後、アプリに戻り、もう一度設定画面から変更を完了してください
                            
                            ※確認メールの有効期限は1時間です
                            """
                        showAlert = true
                    } else {
                        alertMessage = """
                            メールアドレスの更新に失敗しました。
                            
                            以下をご確認ください：
                            ・入力したメールアドレスが正しいこと
                            ・インターネット接続が安定していること
                            ・既に使用されているメールアドレスではないこと
                            """
                        showAlert = true
                    }
                }
            }
        }
    }
    
    // アラートの更新
    var alert: Alert {
        Alert(
            title: Text("お知らせ"),
            message: Text(alertMessage),
            dismissButton: .default(Text("確認")) {
                if alertMessage.contains("確認メール") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        )
    }
}
