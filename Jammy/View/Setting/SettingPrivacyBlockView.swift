import SwiftUI
import FirebaseFirestore

struct SettingPrivacyBlockView: View {
    @State var blockedUsers: [UserProfile] = []
    @EnvironmentObject var blockViewModel: BlockViewModel
    
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 90)
            
            Text("ブロックしたユーザー")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            if blockedUsers.isEmpty {
                VStack {
                    Spacer()
                    Text("ブロックしているユーザーはいません")
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(blockedUsers) { user in
                            BlockedUserCard(user: user)
                                .environmentObject(blockViewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
        .task {
            await blockViewModel.loadBlockedUsers()  // BlockViewModelの読み込みを待つ
            await loadBlockedUsers()  // ローカルのblockedUsersを更新
        }
        .onChange(of: blockViewModel.blockedUsers) { _, _ in
            Task {
                await loadBlockedUsers()
            }
        }
    }
    
    private func loadBlockedUsers() async {
        do {
            var profiles: [UserProfile] = []
            for userId in blockViewModel.blockedUsers {
                do {
                    if let profile = try await getBlockedUser(id: userId) {
                        profiles.append(profile)
                    } else {
                        // ユーザーが存在しない場合は自動的にブロックリストから削除
                        try await blockViewModel.unblockUser(userId)
                    }
                } catch {
                    print("Error fetching user \(userId): \(error.localizedDescription)")
                    // 存在しないユーザーの場合はブロックリストから削除
                    if error.localizedDescription.contains("User profile not found") {
                        try? await blockViewModel.unblockUser(userId)
                    }
                    continue
                }
            }
            
            await MainActor.run {
                blockedUsers = profiles
            }
        } catch {
            print("Error loading blocked user profiles: \(error.localizedDescription)")
        }
    }
    
    func getBlockedUser(id: String) async throws -> UserProfile? {
        let db = Firestore.firestore()
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

struct BlockedUserCard: View {
    let user: UserProfile
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var showingUnblockAlert = false
    @State private var isUnblocking = false
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
            }
            
            Spacer()
            
            Button {
                showingUnblockAlert = true
            } label: {
                Text("ブロック解除")
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .disabled(isUnblocking)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("ブロック解除", isPresented: $showingUnblockAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("解除する", role: .destructive) {
                Task {
                    isUnblocking = true
                    try await blockViewModel.unblockUser(user.id)
                    isUnblocking = false
                }
            }
        } message: {
            Text("\(user.name)のブロックを解除しますか？")
        }
    }
}

#Preview {
    SettingPrivacyBlockView()
        .environmentObject(BlockViewModel())
}
