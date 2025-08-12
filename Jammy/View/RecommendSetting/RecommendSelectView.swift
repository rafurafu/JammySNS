//ランダムレコメンド
//  RecommendSelectView.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/11/05.
//

import SwiftUI

struct RecommendSelectView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var navigationPath: NavigationPath
    @State var isSliderVisible: Bool = false
    @State var targetPopularity: Double = 0
    //@State var showDetailSettings: Bool =
    @StateObject private var jammyRecommendModel = JammyRecommendModel()
    @EnvironmentObject var spotifyManager: SpotifyMusicManager
    @Binding var isRecommended: Bool
    @Binding var recommendSettings: RecommendSettings
    @Binding var recommendedTracks: [TrackInfo.Track]
    
    // アニメーション用のState
    @State private var isAnimating = false
    @State private var sliderValue: Double = 50
    @State private var shouldStartRecommendation = false
    @State private var showAnimation = false
    @State private var animationOffset: CGFloat = 1000
    
    let gradientColors = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.41, blue: 0.71),
            Color(red: 0.07, green: 0.21, blue: 0.49)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    private let sliderTitles = ["超マイナー", "マイナー寄り", "バランス", "メジャー寄り", "超メジャー"]
    private let ranges = [0...20, 20...40, 40...60, 60...80, 80...100]
    
    var currentRangeIndex: Int {
        ranges.firstIndex(where: { $0.contains(Int(sliderValue)) }) ?? 2
    }
    
    var body: some View {
        NavigationStack{
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 30) {
                        // タイトルセクション
                        VStack(spacing: 12) {
                            Text("レコメンドタイプを選択")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("好みに合わせて音楽を探してみましょう！")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, geometry.size.height * 0.05)
                        
                        // スライダーセクション
                        VStack(spacing: 12) {
                            Text(sliderTitles[currentRangeIndex])
                                .font(.headline)
                                .foregroundColor(.gray)
                                .animation(.easeInOut, value: currentRangeIndex)
                            
                            HStack {
                                Text("マイナー")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(sliderValue))%")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 60)
                                    .animation(.easeInOut, value: sliderValue)
                                
                                Spacer()
                                
                                Text("メジャー")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            // カスタムスライダー
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    // バックグラウンドトラック
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 2)
                                    
                                    // プログレストラック
                                    Rectangle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 1.0, green: 0.41, blue: 0.71),
                                                Color(red: 0.07, green: 0.21, blue: 0.49)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: proxy.size.width * CGFloat(sliderValue / 100), height: 2)
                                        .animation(isAnimating ? .easeInOut(duration: 1.0) : nil, value: sliderValue)
                                    
                                    // スライダーつまみ
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.41, blue: 0.71))
                                        .frame(width: 20, height: 20)
                                        .position(x: proxy.size.width * CGFloat(sliderValue / 100), y: 10)
                                        .animation(isAnimating ? .easeInOut(duration: 1.0) : nil, value: sliderValue)
                                        .shadow(radius: 2)
                                }
                            }
                            .frame(height: 20)
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                        
                        // ボタンセクション
                        VStack(spacing: 20) {
                            Button(action: randomSelect) {
                                HStack {
                                    if isAnimating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                    } else {
                                        Image(systemName: "shuffle")
                                            .font(.headline)
                                        Text("ランダムに選ぶ")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(gradientColors)
                                .foregroundColor(.white)
                                .cornerRadius(28)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isAnimating)
                            
                            
                            NavigationLink {
                                JammyRecommendSettingView(targetPopularity: $targetPopularity, recommendSettings: $recommendSettings, recommendedTracks: $recommendedTracks, isRecommended: $isRecommended)
                                    .environmentObject(spotifyManager)
                            } label: {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.headline)
                                    Text("細かく設定する")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(Color(red: 1.0, green: 0.41, blue: 0.71))
                                .background(Color.white)
                                .cornerRadius(28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color(red: 1.0, green: 0.41, blue: 0.71), lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                            
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.98, green: 0.98, blue: 0.98))
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.2), radius: 20)
                    .padding()
                    
                    if showAnimation {
                        AnimationOverlay()
                            .transition(.move(edge: .bottom))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.5))
            }
        }
    }
    
    private func randomSelect() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.3)) {
            showAnimation = true
        }
        
        // ランダムな値を生成して10回スライダーを動かす
        var count = 0
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            sliderValue = Double.random(in: 0...100)
            count += 1
            
            if count >= 10 {
                timer.invalidate()
                let finalValue = Double.random(in: 0...100)
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    sliderValue = finalValue
                }
                
                // アニメーション完了後の処理
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    Task {
                        do {
                            // オプショナルチェーンを除去
                            let recommendedResults = try await jammyRecommendModel.randomRecommend(popularity: finalValue)
                            
                            await MainActor.run {
                                recommendedTracks = recommendedResults
                                isRecommended = true
                                targetPopularity = finalValue
                                
                                // アニメーション完了と同時に画面を閉じる
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAnimation = false
                                    isAnimating = false
                                }
                            }
                        } catch {
                            print("Recommendation error: \(error)")
                            // エラー時の処理
                            await MainActor.run {
                                let alert = ShowAlert()
                                alert.showOKAlert(
                                    title: "レコメンドに失敗しました",
                                    message: "もう一度お試しください"
                                )
                                showAnimation = false
                                isAnimating = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // アニメーションオーバーレイの更新
    struct AnimationOverlay: View {
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                scale = 1.2
                            }
                        }
                    
                    Text("レコメンド中...")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
