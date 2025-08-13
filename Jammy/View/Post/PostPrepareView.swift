//
//  PostVerticalView.swift
//  Jammy
//
//  Created by yokoyama musashi on 2024/06/18.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage

struct PostPrepareView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @State private var inputText = ""
    @State var UploadAlert: Bool = false
    @State private var backgroundColor: Color = .clear
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @FocusState var keybordFocus: Bool
    @Binding var currentTrackInfo: TrackInfo
    @Binding var hasSongData: Bool
    @Binding var selection: Int
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 画像投稿関連の状態
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showImagePicker = false
    @State private var isUploading = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    mainContentSection(geometry: geometry)
                }
                .dismissKeyboardOnTap()
            }
            .background(backgroundColorForScheme)
        }
    }
    
    // 計算プロパティを分離
    private var backgroundColorForScheme: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
    }
    
    // メインコンテンツセクション
    private func mainContentSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            musicCardSection(geometry: geometry)
            textInputSection(geometry: geometry)
            imageSelectionSection(geometry: geometry)
        }
    }
    
    // 音楽カードセクション
    private func musicCardSection(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            // カード背景
            RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                .shadow(radius: 10, x: 5, y: 5)
                .frame(width: geometry.size.width - 40.0, height: 450)
                .foregroundColor(cardBackgroundColor)
                .padding(.top, 20)
            
            // カード内容
            VStack {
                albumImageView
                trackInfoView
                postButtonView(geometry: geometry)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // アルバム画像ビュー
    private var albumImageView: some View {
        Group {
            if let imageUrlString = currentTrackInfo.item.album.images.first?.url,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250.0, height: 250.0)
                        .padding(.top, 50)
                } placeholder: {
                    ProgressView()
                        .frame(width: 250.0, height: 250.0)
                        .padding(.top, 50)
                }
            } else {
                Text("画像が見つかりませんでした")
            }
        }
    }
    
    // トラック情報ビュー
    private var trackInfoView: some View {
        VStack(spacing: 15) {
            Text(currentTrackInfo.item.name)
                .font(.system(.title, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .frame(height: 40)
                .frame(alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
            
            Text(currentTrackInfo.item.artists.first?.name ?? "")
                .font(.system(.title3, design: .default))
                .fontWeight(.medium)
                .frame(height: 20)
                .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
        }
        .padding(.vertical, 10)
    }
    
    // 投稿ボタンビュー
    private func postButtonView(geometry: GeometryProxy) -> some View {
        Button(action: {
            UploadAlert = true
        }, label: {
            HStack {
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                    Text("投稿中...")
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("投稿")
                }
            }
            .font(.system(size: 32, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .frame(width: geometry.size.width - 40.0, height: 60)
            .background(isUploading ? AnyShapeStyle(Color.gray) : AnyShapeStyle(fontColor))
            .cornerRadius(15)
            .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
        })
        .disabled(isUploading)
        .alert(isPresented: $UploadAlert) {
            Alert(
                title: Text("この内容で投稿しますか？"),
                message: selectedImageData != nil ? Text("画像付きで投稿されます") : nil,
                primaryButton: .default(Text("投稿する"), action: {
                    Task {
                        await handlePostSubmission()
                    }
                }),
                secondaryButton: .cancel(Text("やめておく"))
            )
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // テキスト入力セクション
    private func textInputSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 15) {
            ZStack(alignment: .trailing) {
                textEditorView(geometry: geometry)
                keyboardToggleButton
            }
        }
    }
    
    // テキストエディターのビュー
    private func textEditorView(geometry: GeometryProxy) -> some View {
        let textEditorBackgroundColor = colorScheme == .dark ? 
            Color(red: 0.15, green: 0.15, blue: 0.15) : 
            Color(red: 0.95, green: 0.95, blue: 0.95)
        
        let textColor = colorScheme == .dark ? Color.white : Color.black
        
        return TextEditor(text: $inputText)
            .multilineTextAlignment(.leading)
            .foregroundStyle(textColor)
            .lineSpacing(5)
            .frame(width: geometry.size.width - 30, height: 120)
            .padding(8)
            .background(textEditorBackgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.gray.opacity(0.1), radius: 10, x: 2, y: 2)
            .padding(10)
            .focused(self.$keybordFocus)
            .autocorrectionDisabled(true)
            .overlay(alignment: .center) {
                if inputText.isEmpty {
                    Text("この曲についてコメントを書いてみよう...")
                        .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(6)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
            }
    }
    
    // キーボード切り替えボタン
    private var keyboardToggleButton: some View {
        let buttonColor = colorScheme == .dark ? Color.white : Color(red: 0.7, green: 0.7, blue: 0.7)
        
        return Group {
            if keybordFocus == false {
                Button(action: {
                    keybordFocus = true
                }, label: {
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(buttonColor)
                        .frame(width: 30)
                        .padding(.trailing, 30)
                })
            } else {
                Button(action: {
                    keybordFocus = false
                }, label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(buttonColor)
                        .frame(width: 30)
                        .padding(.trailing, 30)
                })
            }
        }
    }
    
    // 画像選択セクション
    private func imageSelectionSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            imageSelectionHeader
            
            if let selectedImageData = selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                selectedImagePreview(uiImage: uiImage)
            } else {
                imageSelectionButton(geometry: geometry)
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newPhoto in
            handlePhotoSelection(newPhoto)
        }
    }
    
    // 画像選択ヘッダー
    private var imageSelectionHeader: some View {
        HStack {
            Text("📸 画像を追加")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // 選択された画像のプレビュー
    private func selectedImagePreview(uiImage: UIImage) -> some View {
        VStack(spacing: 10) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            HStack {
                Button("画像を変更") {
                    showImagePicker = true
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("削除") {
                    selectedPhoto = nil
                    selectedImageData = nil
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // 画像選択ボタン
    private func imageSelectionButton(geometry: GeometryProxy) -> some View {
        let backgroundColor = colorScheme == .dark ? 
            Color(red: 0.15, green: 0.15, blue: 0.15) : 
            Color(red: 0.95, green: 0.95, blue: 0.95)
        
        return Button(action: {
            showImagePicker = true
        }) {
            VStack(spacing: 10) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("タップして画像を選択")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(width: geometry.size.width - 60, height: 100)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
            )
        }
        .padding(.horizontal, 20)
    }
    
    // 写真選択の処理
    private func handlePhotoSelection(_ newPhoto: PhotosPickerItem?) {
        Task {
            if let newPhoto = newPhoto {
                if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    // 投稿処理を実行する関数
    private func handlePostSubmission() async {
        await MainActor.run {
            isUploading = true
        }
        
        do {
            var imageURL: String? = nil
            
            // 画像がある場合はFirebase Storageにアップロード
            if let imageData = selectedImageData {
                imageURL = try await uploadImageToFirebaseStorage(imageData: imageData)
            }
            
            let postViewModel = PostViewModel()
            
            await MainActor.run {
                postViewModel.postTrackWithImage(
                    trackInfo: currentTrackInfo,
                    postComment: inputText,
                    imageURL: imageURL
                )
                
                isUploading = false
                hasSongData = false
                selection = 0
            }
            
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    // Firebase Storageに画像をアップロードする関数
    private func uploadImageToFirebaseStorage(imageData: Data) async throws -> String {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // 一意のファイル名を生成
        let imageFileName = "post_images/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(imageFileName)
        
        // メタデータを設定
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 画像をアップロード
        let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        
        // ダウンロードURLを取得
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL.absoluteString
    }
}

// Firebase Storage用の拡張
extension StorageReference {
    func putDataAsync(_ data: Data, metadata: StorageMetadata? = nil) async throws -> StorageMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            self.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown upload error"]))
                }
            }
        }
    }
}

#Preview {
    PostPrepareView(currentTrackInfo: .constant(TrackInfo()), hasSongData: .constant(true), selection: .constant(2))
}
