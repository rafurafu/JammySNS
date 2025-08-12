import SwiftUI

struct PostView: View {
    @State var name: String = ""
    @State private var inputText = ""
    @State var UploadAlert: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    @State var hasSongData: Bool = false
    @State var musicTimeSlider: Double = 0.3
    @State var currentTrackInfo: TrackInfo = TrackInfo()
    @Binding var selection: Int
    
    // 背景色をダークモード対応に変更
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    // フォントカラーのグラデーションをダークモード対応に
    var fontGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ?
                Color(red: 1.0, green: 0.51, blue: 0.81) : // ダークモード時は少し明るく
                Color(red: 1.0, green: 0.41, blue: 0.71),  // #FF69B4
                colorScheme == .dark ?
                Color(red: 0.17, green: 0.31, blue: 0.59) : // ダークモード時は少し明るく
                Color(red: 0.07, green: 0.21, blue: 0.49)   // #12367C
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Text("Jammy")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .padding(.top, 70)
                        .padding(.bottom, 20)
                        .padding(.leading, 20)
                        //.foregroundColor(.clear)
                        .overlay(
                            fontGradient
                                .mask(
                                    Text("Jammy")
                                        .font(.system(size: 40))
                                        .fontWeight(.bold)
                                        .padding(.bottom, 20)
                                        .padding(.top, 70)
                                        .padding(.leading, 20)
                                )
                        )
                        .frame(width: geometry.size.width, height: 90, alignment: .leading)
                        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
                    //.background(backgroundColor) // ダークモード対応の背景色を使用
                        .padding(0)
                    
                    Divider()
                        .frame(height: 10)
                    
                    PostRemainderView(currentTrackInfo: $currentTrackInfo, hasSongData: $hasSongData, selection: $selection)
                }
                .ignoresSafeArea(.all)
                .frame(width: geometry.size.width,height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom - 100)
                .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
                // .background(backgroundColor) // ダークモード対応の背景色を使用
                .navigationDestination(isPresented: $hasSongData) {
                    PostPrepareView(currentTrackInfo: $currentTrackInfo, hasSongData: $hasSongData, selection: $selection)
                }
            }
            .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        }
    }
}

#Preview {
    PostView(selection: .constant(2))
}
