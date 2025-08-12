import SwiftUI
import FirebaseAuth

struct FollowingView: View {
    @StateObject private var viewModel = OtherProfileViewModel()
    @State private var following: [UserProfile] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 30)
            
            HStack {
                Text("フォロー中")
                    .fontWeight(.bold)
                    .font(.headline)
                    .foregroundStyle(.gray)
                
                Text("(\(following.count))")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            .padding(.bottom, 10)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(following, id: \.id) { followedUser in
                        UserRowView(
                            user: followedUser,
                            showFollowButton: true
                        )
                    }
                }
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.97))
        .edgesIgnoringSafeArea(.top)
        .task {
            await loadFollowing()
        }
        .refreshable {
            await loadFollowing()
        }
    }
    
    private func loadFollowing() async {
        do {
            if let currentUserId = Auth.auth().currentUser?.uid {
                following = try await viewModel.fetchFollowing(for: currentUserId)
            }
        } catch {
            print("Error loading following: \(error)")
        }
    }
}
