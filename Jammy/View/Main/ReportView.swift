//
//  ReportView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/12/02.
//


import SwiftUI

struct ReportView: View {
    let reportedUserId: String
    let postId: String?
    @StateObject private var viewModel = ReportViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .spam
    @State private var additionalComment: String = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通報理由")) {
                    Picker("理由を選択", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }
                }
                
                Section(header: Text("補足情報（任意）")) {
                    TextEditor(text: $additionalComment)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("通報する")
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("ユーザーを通報")
            .alert("通報を受け付けました", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("ご報告ありがとうございます。内容を確認の上、適切に対応いたします。")
            }
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        Task {
            do {
                try await viewModel.submitReport(
                    reportedUserId: reportedUserId,
                    reason: selectedReason,
                    additionalComment: additionalComment,
                    postId: postId
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

