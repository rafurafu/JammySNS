//
//  SafariView.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/11/18.
//

import SwiftUI
import SafariServices

// SafariViewをSwiftUIで使用するためのラッパー
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = UIColor(Color(red: 0.07, green: 0.21, blue: 0.49))
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
