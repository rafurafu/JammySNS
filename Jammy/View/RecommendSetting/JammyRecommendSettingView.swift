//細かくレコメンド
//  JammyRecommendSettingView.swift
//
//  Created by 柳井大輔 on 2024/10/30.
//

import SwiftUI

// レコメンド設定を保持する構造体
struct RecommendSettings {
    var targetPopularity: Double
    var valence: Double
    var energy: Double
    var minTempo: Double
    var selectedGenres: [String]
}

// スタイル定義
private struct JammyStyle {
    static let gradientColors = [
        Color(red: 1.0, green: 0.41, blue: 0.71),
        Color(red: 0.07, green: 0.21, blue: 0.49)
    ]
    
    static let gradient = LinearGradient(
        gradient: Gradient(colors: gradientColors),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let darkBackgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let darkComponentColor = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let accentColor = Color(red: 1.0, green: 0.41, blue: 0.71)
}

struct JammyRecommendSettingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    //@StateObject private var jammyRecommendModel = JammyRecommendModel()
    @State private var jammyRecommendModel: JammyRecommendModel?
    //@Binding var isSliderVisible: Bool
    @Binding var targetPopularity: Double
    @Binding var recommendSettings: RecommendSettings
    @Binding var recommendedTracks: [TrackInfo.Track]
    @Binding var isRecommended: Bool
    // 各設定値のState
    @State private var valence: Double = 0.0     // 曲の明るさ
    @State private var energy: Double = 0.0      // エネルギー
    @State private var minTempo: Double = 0.0    // 最小テンポ
    @State var selectedGenres: [String] = []
    @State private var sliderAnimation: Double = 0.0
    @State private var isLoading: Bool = false
    @State private var recommendStarted: Bool = false
    @State private var showResultAlert: Bool = false
    @State private var trackCount: Int = 0
    
    // ジャンルの定義
    private let availableGenres = [
        Genre(id: "k-pop", name: "K-POP"),
        Genre(id: "j-pop", name: "J-POP"),
        Genre(id: "j-rock", name: "J-ROCK"),
        Genre(id: "hip-hop", name: "ヒップホップ"),
        Genre(id: "anime", name: "アニメ"),
        Genre(id: "dance-pop", name: "ダンスポップ"),
        Genre(id: "indie-pop", name: "インディーポップ"),
        Genre(id: "rock", name: "ロック")
    ]
    
    private let gradientColors = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    titleSection
                        .padding(.top, geometry.size.height * 0.02)
                    
                    genreSelectionSection
                    
                    settingsSection
                    
                    recommendationButton
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, geometry.size.height * 0.05)
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.98, green: 0.98, blue: 0.98))
        }
        .opacity(sliderAnimation)
        .onAppear {
            jammyRecommendModel = JammyRecommendModel()
            withAnimation(.easeIn(duration: 0.3)) {
                sliderAnimation = 1.0
            }
        }
        .onChange(of: recommendStarted) { started in
            if started {
                withAnimation(.easeOut(duration: 0.3)) {
                    sliderAnimation = 0
                }
                // アニメーション完了後にビューを閉じる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("今日のおすすめを探しましょう！")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("お好みに合わせて設定を調整してください")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    private var genreSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ジャンル選択")
                .font(.headline)
                .foregroundStyle(gradientColors)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(availableGenres) { genre in
                    GenreButton(
                        title: genre.name, id: genre.id,
                        selectedGenres: $selectedGenres
                    )
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    private var settingsSection: some View {
        VStack(spacing: 24) {
            // 人気度バランス
            sliderSection(
                title: "人気度バランス",
                value: $targetPopularity,
                range: 0...100,
                step: 10.0,
                leftLabel: "マイナー寄り",
                rightLabel: "メジャー寄り",
                valueLabel: "\(Int(targetPopularity))%"
            )
            
            // 曲の明るさ
            sliderSection(
                title: "曲の明るさ",
                value: $valence,
                range: 0...1,
                step: 0.1,
                leftLabel: "落ち着いた",
                rightLabel: "明るい",
                valueLabel: "\(Int(valence * 100))%"
            )
            
            // エネルギー
            sliderSection(
                title: "エネルギー",
                value: $energy,
                range: 0...1,
                step: 0.1,
                leftLabel: "静か",
                rightLabel: "激しい",
                valueLabel: "\(Int(energy * 100))%"
            )
            
            // 最小テンポ
            sliderSection(
                title: "最小テンポ",
                value: $minTempo,
                range: 60...180,
                step: 5.0,
                leftLabel: "遅い",
                rightLabel: "速い",
                valueLabel: "\(Int(minTempo)) BPM"
            )
        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    private var recommendationButton: some View {
        Button(action: startRecommendation) {
            Text("レコメンド開始")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    selectedGenres.isEmpty ?
                    AnyShapeStyle(Color.gray) :
                        AnyShapeStyle(gradientColors)
                )
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.15), radius: 8)
        }
        .disabled(isLoading || selectedGenres.isEmpty)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
    private func startRecommendation() {
        Task {
            let newSettings = RecommendSettings(
                targetPopularity: targetPopularity,
                valence: valence,
                energy: energy,
                minTempo: minTempo,
                selectedGenres: selectedGenres
            )
            
            recommendSettings = newSettings
            
            // アニメーション付きでビューを消す
            withAnimation(.easeInOut(duration: 0.3)) {
                sliderAnimation = 0
                recommendStarted = true
            }
            
            print("jammyRecommendModel: \(String(describing: jammyRecommendModel))")
            if let model = jammyRecommendModel {
                print("レコメンド開始！！")
                // カスタムレコメンドを実行して結果を保存
                recommendedTracks = try await model.customRecommend(recommend: recommendSettings)
                print("レコメンド終了：\(recommendedTracks)")
            }

            // ビューを閉じる
            isRecommended = true
            dismiss()
        }
    }
    
    private func sliderSection(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        leftLabel: String,
        rightLabel: String,
        valueLabel: String
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text(valueLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Slider(value: value, in: range, step: step)
                .tint(Color(red: 1.0, green: 0.41, blue: 0.71))
            
            HStack {
                Text(leftLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Text(rightLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
    
    struct Genre: Identifiable {
        let id: String
        let name: String
    }
    
    struct GenreButton: View {
        let title: String
        let id: String
        @Environment(\.colorScheme) var colorScheme
        @State var isPressed: Bool = false
        @Binding var selectedGenres: [String]
        
        var body: some View {
            if isPressed {
                Button {
                    isPressed = false
                    selectedGenres.removeAll { $0 == id }
                } label: {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isPressed ? .white : (colorScheme == .dark ? .white : .primary))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            isPressed ?
                            Color(red: 1.0, green: 0.41, blue: 0.71) :
                                (colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.gray.opacity(0.1))
                        )
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
            } else {
                Button {
                    isPressed = true
                    selectedGenres.append(id)
                } label: {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isPressed ? .white : (colorScheme == .dark ? .white : .primary))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            isPressed ?
                            Color(red: 1.0, green: 0.41, blue: 0.71) :
                                (colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.gray.opacity(0.1))
                        )
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
            }
        }
    }
}

#Preview {
    JammyRecommendSettingView(
        targetPopularity: .constant(50.0),
        recommendSettings: .constant(RecommendSettings(
            targetPopularity: 50.0,
            valence: 0.5,
            energy: 0.5,
            minTempo: 120.0,
            selectedGenres: ["j-pop"])
        ), recommendedTracks: .constant([]), isRecommended: .constant(false))
    .environmentObject(SpotifyMusicManager())
}
