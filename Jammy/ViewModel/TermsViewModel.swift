//
//  TermsViewModel.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/11/29.
//

import Foundation

// 利用規約同意処理
class TermsViewModel: ObservableObject {
    @Published var hasAgreedToTerms: Bool {
        didSet {
            UserDefaults.standard.set(hasAgreedToTerms, forKey: "hasAgreedToTerms")
        }
    }
    
    init() {
        self.hasAgreedToTerms = UserDefaults.standard.bool(forKey: "hasAgreedToTerms")
    }
}
