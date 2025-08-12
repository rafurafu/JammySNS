import SwiftUI

struct Logout: View {
    @EnvironmentObject var userState: User
    var body: some View {
        Text("削除")
    }
}

#Preview {
    Logout()
}

