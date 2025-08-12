import SwiftUI
import FirebaseAuth

// FollowersView
struct FollowersView: View {
    @StateObject private var viewModel = OtherProfileViewModel()
    @State private var followers: [UserProfile] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 30)
            
            HStack {
                Text("フォロワー")
                    .fontWeight(.bold)
                    .font(.headline)
                    .foregroundStyle(.gray)
                
                Text("(\(followers.count))")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            .padding(.bottom, 10)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(followers, id: \.id) { follower in
                        UserRowView(
                            user: follower,
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
            await loadFollowers()
        }
        .refreshable {
            await loadFollowers()
        }
    }
    
    private func loadFollowers() async {
        do {
            if let currentUserId = Auth.auth().currentUser?.uid {
                followers = try await viewModel.fetchFollowers(for: currentUserId)
            }
        } catch {
            print("Error loading followers: \(error)")
        }
    }
}
