//言語

import SwiftUI

struct SettingLanguageView: View {
    let fontColor = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71), // #FF69B4
            Color(red: 0.07, green: 0.21, blue: 0.49) // #12367C
        ]),
        startPoint: .leading, // 左から始める
        endPoint: .trailing // 右
    )
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedLanguage: String = "日本語"
    @State private var languageToggles: [String: Bool] = [
        "日本語": true,
        "英語 - English": false,
        "韓国語 - 한국어": false,
        "中国語 - 中文": false,
        "ミャンマー語 - မြန်မာစာ": false
    ]
    //@EnvironmentObject var userState: User
    
    let backgroundColor = Color.white

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 90)

            Text("言語設定")
                .fontWeight(.bold)
                .font(.headline)
                .foregroundStyle(fontColor)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(languageToggles.keys.sorted(), id: \.self) { language in
                        HStack {
                            Text(language)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { self.languageToggles[language] ?? false },
                                set: { newValue in
                                    for key in self.languageToggles.keys {
                                        self.languageToggles[key] = false
                                    }
                                    self.languageToggles[language] = newValue
                                    self.selectedLanguage = newValue ? language : self.selectedLanguage
                                }
                            ))
                            .labelsHidden()
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white)
                    }
                }
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
            }

            Spacer()

            Button(action: {
            }) {
                Text("完了")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(fontColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white)
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    SettingLanguageView()
}

