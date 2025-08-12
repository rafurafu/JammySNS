//アカウント
import SwiftUI
import PhotosUI

struct ProfileAccountSettingView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var editedName: String = ""
    @State private var editedBio: String = ""
    @State private var userProfile = UserProfile(name: "", bio: "", profileImageURL: "", uid: "")
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showImageCropper = false
    @State private var showCameraSheet = false
    @State private var getUIImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var initialProfileImage: UIImage?
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingActionSheet = false
    @State private var showPhotoPicker = false
    
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
            
            Text("プロフィール設定")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            VStack(alignment: .center, spacing: 20) {
                // プロフィール画像の表示
                Button(action: {
                    showingActionSheet = true
                }) {
                    if let croppedImage = croppedImage {
                        Image(uiImage: croppedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                    } else if let initialImage = initialProfileImage {
                        Image(uiImage: initialImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }

                Text("写真やアバターを編集")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("名前")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.headline)
                    TextField("名前を入力", text: $editedName)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("自己紹介")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.headline)
                    TextField("自己紹介を入力", text: $editedBio)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            Button(action: {
                updateUserProfile()
            }) {
                Text("保存")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(fontColor)
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .disabled(isLoading)
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
        // アクションシート
        .confirmationDialog("プロフィール画像の変更",
                          isPresented: $showingActionSheet,
                          titleVisibility: .visible) {
            Button("ライブラリから選択") {
                showingActionSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPhotoPicker = true
                }
            }
            Button("写真を撮影") {
                showCameraSheet = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        // PhotosPicker
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 1,
            matching: .images
        )
        // アルバムから取得した画像をUIImage型に変換
        .onChange(of: selectedPhotos) { _ in
            Task {
                if let photo = selectedPhotos.first,
                   let data = try? await photo.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    getUIImage = uiImage
                }
            }
        }
        // カメラ表示
        .fullScreenCover(isPresented: $showCameraSheet) {
            CameraView(image: $getUIImage)
                .ignoresSafeArea()
        }
        // 画像を得た時の処理
        .onChange(of: getUIImage) { _ in
            if getUIImage != nil {
                showImageCropper = true
            }
        }
        // 画像クロッパーの表示
        .sheet(isPresented: $showImageCropper) {
            if let image = getUIImage {
                ImageCropper(image: image, visible: $showImageCropper, done: imageCropped)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("お知らせ"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // トリミングが終わった後に呼ばれる
    func imageCropped(image: UIImage) {
        croppedImage = image
    }

    private func updateUserProfile() {
        isLoading = true
        
        if let imageToUpload = croppedImage {
            authViewModel.uploadProfileImage(imageToUpload) { result in
                switch result {
                case .success(let imageURL):
                    self.authViewModel.updateUserProfile(
                        name: editedName,
                        bio: editedBio,
                        profileImageURL: imageURL
                    ) { success in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if success {
                                self.alertMessage = "プロフィールが更新されました。"
                                self.showAlert = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            } else {
                                self.alertMessage = "プロフィールの更新に失敗しました。"
                                self.showAlert = true
                            }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        } else {
            authViewModel.updateUserProfile(
                name: editedName,
                bio: editedBio,
                profileImageURL: nil
            ) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.alertMessage = "プロフィールが更新されました。"
                        self.showAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        self.alertMessage = "プロフィールの更新に失敗しました。"
                        self.showAlert = true
                    }
                }
            }
        }
    }

    private func loadUserProfile() async {
        do {
            let userProfile = try await authViewModel.getUserProfile()
            
            await MainActor.run {
                self.userProfile = userProfile
                self.editedName = userProfile.name  // 編集用の名前を初期化
                self.editedBio = userProfile.bio    // 編集用のbioを初期化
            }
            
            if let imageURLString = userProfile.profileImageURL,
               let imageURL = URL(string: imageURLString) {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.initialProfileImage = image
                    }
                }
            }
        } catch {
            print("Error loading profile: \(error.localizedDescription)")
        }
    }
}
