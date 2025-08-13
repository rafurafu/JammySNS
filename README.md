# Jammy

Spotify連携機能を持つ音楽SNSアプリ

## 概要

JammyはSwiftUIで開発されたiOS向け音楽SNSアプリケーションです。Spotifyアカウントと連携して、音楽の共有やコミュニケーションを楽しむことができます。

## 主な機能

###  音楽機能
- Spotify連携による音楽再生
- プレイリスト共有
- お気に入りアーティスト管理
- 楽曲レコメンド機能

###  SNS機能
- 投稿（テキスト・音楽付き）
- コメント・いいね機能
- フォロー・フォロワー機能
- ユーザー検索

###  プロフィール機能
- プロフィール編集
- 投稿履歴表示
- お気に入り楽曲・アーティスト表示

###  設定機能
- プライバシー設定
- 通知設定
- ブロック機能
- アカウント管理

## 技術スタック

- **開発言語**: Swift
- **フレームワーク**: SwiftUI
- **外部サービス**: Spotify Web API
- **認証**: Firebase Authentication
- **データベース**: Firebase Firestore
- **開発環境**: Xcode

## セットアップ

### 必要要件
- Xcode 15.0以上
- iOS 16.0以上
- Spotifyアカウント
- Firebase プロジェクト

### インストール手順

1. リポジトリをクローン
```bash
git clone https://github.com/[username]/JammySNS.git
cd JammySNS
```

2. Xcodeでプロジェクトを開く
```bash
open Jammy.xcodeproj
```

3. 必要な設定ファイルを配置
   - `GoogleService-Info.plist` をプロジェクトルートに配置
   - Spotify Developer Dashboardでアプリケーションを登録

4. 依存関係を解決
   - Xcode上でSwift Package Managerの依存関係を解決

5. ビルドして実行

## プロジェクト構成

```
Jammy/
├── JammyApp.swift          # アプリケーションエントリーポイント
├── Model/                  # データモデル
│   ├── UserProfile.swift
│   ├── PostModel.swift
│   └── ...
├── View/                   # UI画面
│   ├── Main/               # メイン画面
│   ├── Login/              # ログイン・認証
│   ├── Profile/            # プロフィール
│   ├── Post/               # 投稿機能
│   └── Setting/            # 設定画面
└── ViewModel/              # ビジネスロジック
    ├── AuthViewModel.swift
    ├── PostViewModel.swift
    └── ...
```

## 開発状況

現在開発中のプロジェクトです。以下の機能が実装済みです：

- ✅ ユーザー認証システム
- ✅ Spotify連携
- ✅ 基本的なSNS機能
- ✅ プロフィール管理
- ✅ 投稿・コメント機能
- ✅ フォロー機能
- ✅ 設定画面

## ライセンス

このプロジェクトは個人開発プロジェクトです。


---

💡 **Note**: このアプリを使用するには有効なSpotifyアカウントが必要です。
