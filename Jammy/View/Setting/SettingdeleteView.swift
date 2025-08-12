import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SettingdeleteView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49)  // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 0.8, blue: 0.9, alpha: 1)), Color(#colorLiteral(red: 0.6, green: 0.7, blue: 1, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("アカウントを削除する")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(fontColor)
                
                VStack(spacing: 15) {
                    TextField("メールアドレスを入力", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    SecureField("パスワードを入力", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    Button(action: deleteAccount) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("アカウントを削除")
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 0.41, blue: 0.71, alpha: 1)), Color(#colorLiteral(red: 0.07, green: 0.21, blue: 0.49, alpha: 1))]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Account Deletion"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func deleteAccount() {
        isLoading = true
        guard let user = Auth.auth().currentUser else {
            alertMessage = "No user is currently signed in."
            showAlert = true
            isLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                handleError(error)
                return
            }
            
            deleteUserDataFromFirestore(userId: user.uid) { firestoreError in
                if let firestoreError = firestoreError {
                    handleError(firestoreError)
                    return
                }
                
                deleteUserFilesFromStorage(userId: user.uid) { storageError in
                    if let storageError = storageError {
                        handleError(storageError)
                        return
                    }
                    
                    user.delete { authError in
                        isLoading = false
                        if let authError = authError {
                            handleError(authError)
                        } else {
                            alertMessage = "Account and all associated data successfully deleted."
                            showAlert = true
                        }
                    }
                }
            }
        }
    }
    
    func deleteUserDataFromFirestore(userId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).delete { error in
            completion(error)
        }
    }
    
    func deleteUserFilesFromStorage(userId: String, completion: @escaping (Error?) -> Void) {
        let storage = Storage.storage()
        let userFolder = storage.reference().child("user_files/\(userId)")
        
        userFolder.listAll { (result, error) in
            if let error = error {
                completion(error)
                return
            }
            
            let group = DispatchGroup()
            
            for item in result!.items {
                group.enter()
                item.delete { error in
                    if let error = error {
                        print("Error deleting file: \(error)")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(nil)
            }
        }
    }
    
    func handleError(_ error: Error) {
        isLoading = false
        if let errorCode = AuthErrorCode.Code(rawValue: (error as NSError).code) {
            switch errorCode {
            case .userMismatch, .userNotFound, .invalidCredential, .wrongPassword:
                alertMessage = "Re-authentication failed. Please check your email and password."
            default:
                alertMessage = "An error occurred: \(error.localizedDescription)"
            }
        } else {
            alertMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        showAlert = true
    }
}

struct SettingdeleteView_Previews: PreviewProvider {
    static var previews: some View {
        SettingdeleteView()
    }
}
