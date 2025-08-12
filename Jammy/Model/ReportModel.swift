//
//  ReportModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/12/02.
//


import Foundation
import FirebaseFirestore

// 通報の種類を定義
enum ReportReason: String, CaseIterable {
    case spam = "スパム"
    case inappropriate = "不適切なコンテンツ"
    case harassment = "嫌がらせ/迷惑行為"
    case hateSpeech = "ヘイトスピーチ"
    case violence = "暴力的なコンテンツ"
    case copyright = "著作権侵害"
    case other = "その他"
}

// 通報モデル
struct Report: Identifiable {
    let id: String
    let reportedUserId: String
    let reporterId: String
    let reason: ReportReason
    let additionalComment: String?
    let postId: String?
    let timestamp: Date
    let status: ReportStatus
    
    enum ReportStatus: String {
        case pending = "審査中"
        case resolved = "対応済み"
        case rejected = "却下"
    }
}
