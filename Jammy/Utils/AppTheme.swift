//
//  AppTheme.swift
//  Jammy
//
//  統一されたテーマ管理
//

import SwiftUI

struct AppTheme {
    let colorScheme: ColorScheme
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white
    }
    
    static var spotifyGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.41, blue: 0.71),
                Color(red: 0.07, green: 0.21, blue: 0.49)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension View {
    func themed(_ colorScheme: ColorScheme) -> some View {
        self.environment(\.appTheme, AppTheme(colorScheme: colorScheme))
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(colorScheme: .light)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}