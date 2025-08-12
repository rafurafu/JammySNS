//
//  test2.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/11/02.
//

import SwiftUI

struct usemenm: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Image(systemName: "chevron.left")
                    Spacer()
                    Text("mittiii切り抜きチャンネル [み...")
                        .lineLimit(1)
                        .font(.system(size: 18, weight: .medium))
                    Spacer()
                    Image(systemName: "bell")
                    Image(systemName: "chevron.right")
                }
                .padding()
                
                // Profile Section
                VStack(spacing: 20) {
                    Image("profileImage") // Replace with your image
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Text("@tamukun.jp.fans")
                        .font(.system(size: 18, weight: .medium))
                    
                    // Stats
                    HStack(spacing: 30) {
                        VStack {
                            Text("3")
                                .font(.system(size: 18, weight: .semibold))
                            Text("フォロー中")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("11.2K")
                                .font(.system(size: 18, weight: .semibold))
                            Text("フォロワー")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("33.2K")
                                .font(.system(size: 18, weight: .semibold))
                            Text("いいね")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Action Buttons
                    HStack {
                        Button(action: {}) {
                            Text("フォロー")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                        
                        Button(action: {}) {
                            Image(systemName: "arrowtriangle.down.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {}) {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    // Bio
                    VStack {
                        Text("動画見てくれて〜ありがとっ☆")
                        Text("follow me ! thanks so much !")
                    }
                    .font(.caption)
                    
                    // Video Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                        ForEach(0..<9) { _ in
                            ZStack(alignment: .bottomLeading) {
                                Color.gray.opacity(0.3)
                                    .aspectRatio(1, contentMode: .fit)
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("\(Int.random(in: 10...30))")
                                }
                                .font(.caption)
                                .padding(4)
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    usemenm()
}
