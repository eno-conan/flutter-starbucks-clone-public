# スターバックス公式アプリ クローン

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44.0-blue?style=for-the-badge&logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%3E%3D3.10.0-blue?style=for-the-badge&logo=dart"/>
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-BaaS-green?style=for-the-badge&logo=supabase"/>
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Analytics%20%26%20Push-orange?style=for-the-badge&logo=firebase"/>
</p>

## 📖 プロジェクト概要

スターバックス公式モバイルアプリを可能な限り忠実に再現したFlutterアプリケーションです。**モバイル注文、決済、店舗検索、リワードプログラム**など、実際のアプリの主要機能を網羅的に実装しており、エンタープライズレベルのモバイル開発手法とアーキテクチャパターンを実証します。

**ポートフォリオのハイライト:**
- 🏗️ **Riverpod 3.0** による最新の状態管理アーキテクチャ
- 🔐 **セキュリティファースト** の設計（SSL Pinning、認証、暗号化）
- 📱 **ネイティブ機能統合**（位置情報、プッシュ通知、生体認証）
- ⚡ **高性能**（効率的なデータキャッシュ、リアルタイム更新）
- 🧪 **品質保証**（包括的テストスイート、CI/CD）

## 🛠️ 技術スタック

### フレームワーク・言語
| 技術 | バージョン | 用途 |
|------|----------|------|
| **Flutter** | 3.44.0 | UIフレームワーク |
| **Dart** | >=3.10.0 | プログラミング言語 |
| **FVM** | Latest | Flutterバージョン管理 |

### バックエンド・データベース
| 技術 | 用途 |
|------|------|
| **Supabase** | BaaS (認証、データベース、ストレージ) |
| **PostgreSQL** | リレーショナルデータベース |
| **Row Level Security** | 高度なセキュリティポリシー |

### 状態管理・アーキテクチャ
| 技術 | 用途 |
|------|------|
| **Riverpod 3.0** | 状態管理（Notifier API使用） |
| **go_router** | 宣言的ルーティング |
| **get_it** | 依存性注入 |

### 外部サービス・API
| サービス | 用途 |
|---------|------|
| **Firebase** | Analytics、Crashlytics、Performance、Push通知 |
| **Google Maps** | マップ表示、位置情報 |
| **Google Sign-In** | OAuth認証 |

### セキュリティ・品質
| 技術/手法 | 用途 |
|-----------|------|
| **flutter_secure_storage** | 機密データ暗号化保存 |
| **local_auth** | 生体認証 |
| **MobSF** | セキュリティスキャン |

## 📚 ドキュメント

> [!NOTE]
> ドキュメントは [Zensical](https://zensical.org/) による静的サイトへ移行中です。
> 現在は `docs/project/` 配下のファイルを `docs/zensical-docs/` で管理しています。

### ローカルでドキュメントサイトを確認する

```bash
cd docs/zensical-docs
uv run zensical serve
# → http://localhost:8000
```

## 🎯 技術的ハイライト

### エンタープライズレベル開発
- **Clean Architecture** - レイヤー分離によるテスタブルな設計
- **SOLID原則** - 保守性の高いコード構造
- **型安全性** - Dartの強力な型システムを活用
- **エラーハンドリング** - 包括的なエラー処理とユーザーフィードバック

### モバイル最適化
- **レスポンシブデザイン** - 様々な画面サイズへの対応
- **ネイティブ機能活用** - プラットフォーム固有機能の適切な統合
- **バッテリー効率** - 位置情報サービスの最適化
- **オフライン機能** - ネットワーク断絶時の適切な動作

---

**このプロジェクトは実際のスターバックス公式アプリを参考に、モダンなモバイル開発技術とベストプラクティスを目指したリポジトリです。**
