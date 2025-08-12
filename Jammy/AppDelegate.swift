//
//  AppDelegate.swift
//  Jammy
//
//  Created by 堀田凌平 on 2024/09/17.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    // Firebase セットアップ
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebaseの設定
        FirebaseApp.configure()
        
        // isAuthrizationの初期化のための処理
//        do {
//            try Auth.auth().signOut()
//        } catch {
//            print("初期化失敗")
//        }
//        UserDefaults.standard.removeObject(forKey: "codeVerifier")
//        UserDefaults.standard.removeObject(forKey: "hasAgreedToTerms")
//        UserDefaults.standard.removeObject(forKey: "userName")
//        UserDefaults.standard.removeObject(forKey: "userSettings")
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
          return .portrait
      }
}
