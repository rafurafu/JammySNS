import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// 新規登録のエラー分岐
enum AuthError: Error {
    case signUpError(String)
    case unknown
}

class AuthViewModel: ObservableObject {
    // 公開プロパティ
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var decidedUserName = false
    @Published var errorMessage: String?
    @Published var myUserID: String?
    @Published var myUserInfo: UserProfile?
    @Published var emailVerificationState: EmailVerificationState = .none
    
    enum EmailVerificationState {
        case none
        case verifying
        case verified
        case failed(String)
    }
    
    // Firestoreデータベースへの参照
    private let db = Firestore.firestore()
    
    init() {
        observeAuthChanges()
        // UserDefaultsから保存された状態を読み込む
        self.decidedUserName = UserDefaults.standard.bool(forKey: "decidedUserName")
        observeAuthChanges()
    }
    
    // 認証状態の変更を監視するメソッド
    private func observeAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.isEmailVerified = user?.isEmailVerified ?? false
                self?.myUserID = user?.uid
                
                if let user = user {
                    self?.myUserID = user.uid
                    Task {
                        await self?.fetchMyUserInfo()
                    }
                }
            }
        }
    }
    
    // 自分のuserIDを取得するメソッド
    func getMyUserID(){
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Current user ID not found")
            return
        }
        self.myUserID = userID
        // UserIDを取得した後にユーザー情報を取得
        Task {
            await fetchMyUserInfo()
        }
    }
    
    // ユーザー情報を取得するメソッド
    @MainActor
    func fetchMyUserInfo() async {
        guard let uid = myUserID else {
            print("User ID is not set")
            return
        }
        
        do {
            let docRef = db.collection("users").document(uid)
            let document = try await docRef.getDocument()
            
            guard let data = document.data(), document.exists else {
                print("User document does not exist")
                return
            }
            
            // UserProfileオブジェクトを作成
            let userProfile = UserProfile(
                name: data["userName"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                profileImageURL: data["profileImageURL"] as? String,
                uid: data["uid"] as! String
            )
            
            // メインスレッドでPublished変数を更新
            self.myUserInfo = userProfile
            
            // ユーザー名が空でない場合、decidedUserNameをtrueに設定しUserDefaultsに保存
            let hasUserName = !(userProfile.name.isEmpty)
            self.decidedUserName = hasUserName
            UserDefaults.standard.set(hasUserName, forKey: "decidedUserName")
            
            print("User info loaded successfully")
            
        } catch {
            print("Error fetching user info: \(error.localizedDescription)")
            errorMessage = "ユーザー情報の取得に失敗しました"
        }
    }
    
    // ログインメソッド
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if result != nil {
                    self?.myUserID = result?.user.uid
                    UserDefaults.standard.set(result?.user.uid, forKey: "currentUserID")
                    self?.decidedUserName = true
                    self?.isAuthenticated = true
                }
            }
        }
    }

    // 新規登録
    func signUp(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // 成功時の処理
            self.myUserID = result.user.uid
            UserDefaults.standard.set(result.user.uid, forKey: "currentUserID")
            self.saveUserToFirestore(user: result.user, email: email)
            
        } catch let error as NSError {
            let errorMessage: String
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "このメールアドレスは既に使用されています"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "無効なメールアドレスです"
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "パスワードが弱すぎます"
            default:
                errorMessage = error.localizedDescription
            }
            throw AuthError.signUpError(errorMessage)
        }
    }
    
    // Firestoreにユーザーデータを保存するメソッド
    func saveUserToFirestore(user: FirebaseAuth.User, email: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uidが見つかりませんでした")
            return
        }
        
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "userName": "",
            "bio": "",
            "updatedAt": Timestamp(date: Date()),
            "followersCount": 0,
            "followingCount": 0
        ]
        
        db.collection("users").document(uid).setData(userData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "ユーザーデータの保存中にエラーが発生しました: \(error.localizedDescription)"
            } else {
                self?.decidedUserName = false
                print("ユーザーデータが Firestore に正常に保存されました")
            }
        }
    }
    
    // ユーザー名を更新するメソッド
    func updateUserName(_ name: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let updateData: [String: Any] = [
            "userName": name,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(uid).updateData(updateData) { error in
            if let error = error {
                print("ユーザー名の更新に失敗しました: \(error.localizedDescription)")
                completion(false)
            } else {
                self.decidedUserName = true
                completion(true)
            }
        }
    }
    
    func updateEmail(newEmail: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // メールリンクの設定
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = false
        
        // 新しいメールアドレスを一時的に保存
        UserDefaults.standard.set(newEmail, forKey: "pendingEmailUpdate")
        
        // 確認メールの送信
        Auth.auth().currentUser?.sendEmailVerification { error in
            if let error = error {
                print("確認メール送信エラー: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // 確認メールの送信に成功
            print("確認メールを送信しました")
            completion(true)
        }
    }
    
    // メールアドレスの確認状態をチェックするメソッド
    func checkEmailVerificationStatus(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // ユーザー情報を再読み込み
        user.reload { error in
            if let error = error {
                print("ユーザー情報の再読み込みエラー: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(user.isEmailVerified)
        }
    }
    
    // メール確認後のアドレス更新を完了するメソッド
    func finalizeEmailUpdate(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser,
              let newEmail = UserDefaults.standard.string(forKey: "pendingEmailUpdate") else {
            completion(false)
            return
        }
        
        // Firestoreの更新
        guard let uid = self.myUserID else {
            completion(false)
            return
        }
        
        let updateData: [String: Any] = [
            "email": newEmail,
            "updatedAt": Timestamp(date: Date())
        ]
        
        self.db.collection("users").document(uid).updateData(updateData) { error in
            if let error = error {
                print("Firestoreでのメールアドレス更新エラー: \(error.localizedDescription)")
                completion(false)
            } else {
                // 一時保存したメールアドレスを削除
                UserDefaults.standard.removeObject(forKey: "pendingEmailUpdate")
                completion(true)
            }
        }
    }
    
    
    
    
    // パスワードリセットメソッド
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                self?.errorMessage = "パスワードリセットの送信エラー: \(error.localizedDescription)"
            } else {
                print("パスワードリセットメールが正常に送信されました")
            }
        }
    }
    
    // ログアウトメソッド
    func signOut() {
        do {
            print("ログアウトします")
            try Auth.auth().signOut()
            isAuthenticated = false
            myUserID = nil
            myUserInfo = nil
            decidedUserName = false
            UserDefaults.standard.set(false, forKey: "decidedUserName")
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        } catch let signOutError as NSError {
            errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }
    
    // プロフィール画像をアップロードするメソッド
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    // ユーザープロフィールを更新するメソッド
    func updateUserProfile(name: String, bio: String, profileImageURL: String?, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uidが見つかりませんでした")
            completion(false)
            return
        }
        
        var updateData: [String: Any] = [
            "userName": name,
            "bio": bio,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let profileImageURL = profileImageURL {
            updateData["profileImageURL"] = profileImageURL
        }
        
        db.collection("users").document(uid).updateData(updateData) { error in
            if let error = error {
                print("ユーザープロファイルの更新中にエラーが発生しました: \(error.localizedDescription)")
                completion(false)
            } else {
                print("ユーザープロファイルが正常に更新されました")
                completion(true)
            }
        }
    }
    
    // Firestoreからユーザーデータを取得するメソッド
    func getUserProfile() async throws -> UserProfile {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID not set"])
        }
        
        // ユーザーデータを取得
        let userRef = db.collection("users").document(uid)
        let userData = try await userRef.getDocument()
        guard userData.exists else {
            throw NSError(domain: "AuthViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "User document does not exist for ID: \(uid)"])
        }
        
        let data = userData.data() ?? [:]
        let name = data["userName"] as? String ?? ""
        let bio = data["bio"] as? String ?? ""
        let profileImageURL = data["profileImageURL"] as? String
        
        do {
            // favorite_postsコレクションからお気に入り投稿を取得
            let favoritesRef = userRef.collection("favorite_posts")
            let favorites = try await favoritesRef.getDocuments()
            
            let favoritePostIds = favorites.documents.compactMap { doc in
                doc.documentID
            }
            
            return UserProfile(
                name: name,
                bio: bio,
                profileImageURL: profileImageURL,
                uid: uid,
                favoritePosts: favoritePostIds
            )
        
        } catch {
            print("Failed to fetch favorite posts: \(error)")
            return UserProfile(
                name: name,
                bio: bio,
                profileImageURL: profileImageURL,
                uid: uid,
                favoritePosts: nil
            )
        }
    }
    
    func getOtherUserProfile(id: String) async throws -> UserProfile {
        let documentSnapshot = try await db.collection("users").document(id).getDocument()
        
        guard let data = documentSnapshot.data(), documentSnapshot.exists else {
            throw NSError(domain: "UserProfileError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        let name = data["userName"] as? String ?? ""
        let bio = data["bio"] as? String ?? ""
        let profileImageURL = data["profileImageURL"] as? String ?? ""
        
        return UserProfile(name: name, bio: bio, profileImageURL: profileImageURL, uid: id)
    }
}
