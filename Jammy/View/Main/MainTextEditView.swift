//
//  MainTextEditView.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/10/15.
//

import SwiftUI

struct MainTextEditView: View {
    @StateObject private var viewModel = CommentViewModel()
    var body: some View {
        TextField("コメントを入力...", text: $viewModel.newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .ignoresSafeArea(.keyboard, edges: .all)
    }
}

#Preview {
    MainTextEditView()
}
