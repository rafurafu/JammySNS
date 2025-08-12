//
//  ReportViewModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/12/02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReportViewModel: ObservableObject {
    private let db = Firestore.firestore()
    
    func submitReport(
        reportedUserId: String,
        reason: ReportReason,
        additionalComment: String?,
        postId: String?
    ) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "ユーザーが認証されていません"])
        }
        
        let reportData: [String: Any] = [
            "reportedUserId": reportedUserId,
            "reporterId": currentUserId,
            "reason": reason.rawValue,
            "additionalComment": additionalComment ?? "",
            "postId": postId ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "status": Report.ReportStatus.pending.rawValue
        ]
        
        // 通報情報を保存
        try await db.collection("reports").addDocument(data: reportData)
        
        // 同じユーザーへの通報回数をカウント
        let reportCount = try await getReportCount(for: reportedUserId)
        
        // 通報回数が一定数を超えた場合の処理
        if reportCount >= 5 {
            // 管理者に通知を送る
            try await notifyAdmins(userId: reportedUserId, reportCount: reportCount)
        }
    }
    
    private func getReportCount(for userId: String) async throws -> Int {
        let snapshot = try await db.collection("reports")
            .whereField("reportedUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: Report.ReportStatus.pending.rawValue)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    private func notifyAdmins(userId: String, reportCount: Int) async throws {
        let notificationData: [String: Any] = [
            "type": "multiple_reports",
            "userId": userId,
            "reportCount": reportCount,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("adminNotifications").addDocument(data: notificationData)
    }
}
