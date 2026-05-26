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

## ✨ 主要機能

### 🔐 認証・ユーザー管理
- **Google OAuth認証** - Supabase統合によるセキュアなユーザー認証
- **生体認証** - 指紋認証
- **アカウント管理** - プロフィール編集、メール設定、ニックネーム管理

### 📱 モバイル注文システム
- **商品カタログ** - カテゴリー別商品表示、詳細情報、カスタマイズオプション
- **ショッピングカート** - 商品追加・削除、数量調整、カート保存
- **注文カスタマイズ** - サイズ、温度、追加オプションの選択
- **受け取り方法** - 店内飲食・テイクアウト・ドライブスルー対応
- **注文履歴** - 過去の注文確認、再注文機能

### 💳 決済・ポイントシステム
- **スターバックスカード** - 残高管理、チャージ機能
- **スターポイント** - 購入による獲得、リワード交換
- **決済方法** - カード決済、ポイント利用
- **チケット管理** - eTicket発行、利用履歴

### 🗺️ 店舗検索・マップ
- **位置情報連携** - 現在地からの距離計算
- **店舗詳細** - 営業時間、設備情報、アクセス情報
- **お気に入り店舗** - 店舗ブックマーク機能
- **Google Maps統合** - インタラクティブマップ表示

### 📧 通知・コミュニケーション
- **プッシュ通知** - 注文状況、キャンペーン情報
- **受信トレイ** - アプリ内メッセージ管理

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

## 🏗️ プロジェクト構成

```
lib/
├── app/                    # アプリケーション初期化
├── config/                 # 設定・ルーティング
├── constants/              # 定数定義
├── core/                   # コアモデル・サービス
│   ├── models/             # データモデル
│   └── services/           # コアサービス
├── data/repository/        # データアクセス層
├── provider/               # Riverpod Provider定義
├── screens/                # 画面実装
│   ├── starbucks_user_side/    # ユーザー向け画面
│   └── starbucks_store_side/   # 店舗側画面（QRスキャナ等）
├── services/               # ビジネスロジック
└── shared/                 # 共通ウィジェット・ユーティリティ
```

### Riverpod 3.0 アーキテクチャ例

```dart
@riverpod
class AuthState extends _$AuthState {
  @override
  User? build() {
    return null;
  }

  Future<void> signIn(String email, String password) async {
    // 認証ロジック実装
    state = await authRepository.signIn(email, password);
  }
}

// 使用例
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState != null 
      ? HomeScreen() 
      : SignInForm();
  }
```

## 🚀 開発環境セットアップ

### 必須要件
- Flutter 3.44.0 (FVMでの管理推奨)
- Dart >=3.10.0
- Android Studio / Xcode
- Firebase プロジェクト
- Supabase プロジェクト

### セットアップ手順

1. **リポジトリクローン**
```bash
git clone https://github.com/eno-conan/flutter-starbucks-clone.git
cd flutter-starbucks-clone
```

2. **FVMセットアップ**
```bash
# FVMインストール
dart pub global activate fvm

# プロジェクトのFlutterバージョン適用
fvm install
fvm use --force
```

3. **依存関係インストール**
```bash
fvm flutter pub get
```

4. **環境設定**
```bash
# Firebase設定
flutterfire configure

# Supabase設定（環境変数）
cp .env.example .env
# .envファイルを編集してSupabase認証情報を追加
```

5. **アプリ実行**
```bash
# デバッグ実行
fvm flutter run

# リリースビルド
fvm flutter build apk --release
```

## 🧪 品質保証・テスト

### テスト戦略
- **単体テスト** - ビジネスロジック、ユーティリティ関数
- **ウィジェットテスト** - UI コンポーネント
- **結合テスト** - 画面フロー、API連携
- **Golden テスト** - UI回帰テスト

### コード品質
```bash
# 静的解析
fvm flutter analyze

# フォーマット
fvm flutter format .

# テスト実行
fvm flutter test

# カバレッジ測定
fvm flutter test --coverage
```

## 🔐 セキュリティ対策

- **SSL Certificate Pinning** - 中間者攻撃防止
- **暗号化ストレージ** - 機密データの安全な保存
- **API認証** - JWT トークンベース認証
- **入力バリデーション** - SQLインジェクション等の防止
- **OWASP Mobile Top 10** 準拠
- **MobSF セキュリティスキャン** 定期実行

## 📊 性能・監視

- **Firebase Performance** - アプリパフォーマンス監視
- **Crashlytics** - エラー追跡・分析
- **データキャッシュ** - オフライン対応・高速化
- **画像最適化** - WebP形式、遅延読み込み

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

### ドキュメント一覧

| ドキュメント | 内容 |
|------------|------|
| [開発環境セットアップ](docs/zensical-docs/docs/project/setup.md) | FVM、依存関係管理、環境変数、シークレット設定 |
| [テスト](docs/zensical-docs/docs/project/testing.md) | テスト実行、カバレッジ、Golden test |
| [CI/CD](docs/zensical-docs/docs/project/cicd.md) | GitHub Actionsワークフローの詳細 |
| [Firebase](docs/zensical-docs/docs/project/firebase.md) | App Distribution、App Links |
| [Supabase](docs/zensical-docs/docs/project/supabase.md) | ローカル開発、Edge Function、Google認証 |
| [セキュリティ](docs/zensical-docs/docs/project/security.md) | MobSF、セキュリティベストプラクティス |

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

**このプロジェクトは実際のスターバックス公式アプリを参考に、モダンなモバイル開発技術とベストプラクティスを実証するために作成されたポートフォリオ作品です。**