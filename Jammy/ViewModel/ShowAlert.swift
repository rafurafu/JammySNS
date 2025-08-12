//
//  showAlert.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/07/05.
//

import SwiftUI

struct ShowAlert {
    // OKと返せるアラートを表示する関数
    func showOKAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    // アクション付きアラートの表示
     func showActionAlert(
         title: String,
         message: String,
         primaryButton: AlertButton,
         secondaryButton: AlertButton? = nil  // オプショナルな二つ目のボタン
     ) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         
         // プライマリーボタン
         alert.addAction(UIAlertAction(
             title: primaryButton.title,
             style: primaryButton.style,
             handler: { _ in
                 primaryButton.action()
             }
         ))
         
         // セカンダリーボタン（存在する場合）
         if let secondaryButton = secondaryButton {
             alert.addAction(UIAlertAction(
                 title: secondaryButton.title,
                 style: secondaryButton.style,
                 handler: { _ in
                     secondaryButton.action()
                 }
             ))
         }
         
         DispatchQueue.main.async {
             UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
         }
     }
    // アラートボタンの設定を保持する構造体
    struct AlertButton {
        let title: String
        let style: UIAlertAction.Style
        let action: () -> Void
        
        // デフォルトスタイルのボタン
        static func `default`(title: String, action: @escaping () -> Void) -> AlertButton {
            AlertButton(title: title, style: .default, action: action)
        }
        
        // キャンセルスタイルのボタン
        static func cancel(title: String = "キャンセル", action: @escaping () -> Void = {}) -> AlertButton {
            AlertButton(title: title, style: .cancel, action: action)
        }
        
        // 破壊的なアクションのボタン
        static func destructive(title: String, action: @escaping () -> Void) -> AlertButton {
            AlertButton(title: title, style: .destructive, action: action)
        }
    }
}
