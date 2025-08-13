//
//  DateFormatter+Extensions.swift
//  Jammy
//
//  日付フォーマット用ユーティリティ
//

import Foundation

extension RelativeDateTimeFormatter {
    static let japanese: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    static let abbreviated: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

extension Date {
    func relativeString(style: RelativeDateTimeFormatter.UnitsStyle = .short) -> String {
        switch style {
        case .short:
            return RelativeDateTimeFormatter.japanese.localizedString(for: self, relativeTo: Date())
        case .abbreviated:
            return RelativeDateTimeFormatter.abbreviated.localizedString(for: self, relativeTo: Date())
        default:
            return RelativeDateTimeFormatter.japanese.localizedString(for: self, relativeTo: Date())
        }
    }
}