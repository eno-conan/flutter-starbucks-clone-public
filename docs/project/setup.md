# 開発環境セットアップ

## Flutter SDKバージョン管理（FVM）

このプロジェクトでは[FVM (Flutter Version Management)](https://fvm.app/)を使用してFlutter SDKバージョンを管理しています。

### FVMのインストール

```sh
# Dart pub経由でインストール
dart pub global activate fvm

# または Homebrew経由（macOS）
brew tap leoafarias/fvm
brew install fvm
```

### プロジェクトのセットアップ

```sh
# プロジェクトディレクトリで実行
fvm install

# Flutter SDKを有効化
fvm use --force
```

### Flutter コマンドの実行

FVMをインストール後は、通常の`flutter`コマンドの代わりに`fvm flutter`を使用します：

```sh
# 例：パッケージ取得
fvm flutter pub get

# 例：アプリ実行
fvm flutter run

# 例：ビルド
fvm flutter build apk
```

**エイリアス設定（推奨）**：
頻繁に使用する場合は、シェルのエイリアスを設定すると便利です：

```sh
# ~/.bashrc または ~/.zshrc に追加
alias flutter="fvm flutter"
alias dart="fvm dart"
```

### VS Code設定

VS Codeでは、`.vscode/settings.json`に既にFVM設定が追加されているため、自動的にFVMのFlutter SDKを使用します。

**固定されるFlutterバージョン**: `3.38.5`

## 依存関係管理

### 依存関係確認
[関連issue](https://github.com/eno-conan/flutter-starbucks-clone/issues/163)
何かパッケージの依存関係を確認したい場合は以下コマンドで情報収集。
```sh
flutter pub deps > deps.txt
```

### 依存関係上書き
ローカル開発でenviedの修正版を使う場合、`pubspec_overrides.yaml`を作成してください：
```yaml
dependency_overrides:
  envied:
    path: /path/to/your/envied/packages/envied
  envied_generator:
    path: /path/to/your/envied/packages/envied_generator
```

**注意**: このファイルは`.gitignore`対象

## 環境変数の扱い
- [参考記事](https://codewithandrea.com/articles/flutter-api-keys-dart-define-env-files/)
- [Notion](https://www.notion.so/16b8580db1958025bc09e33accf7dcca)

## 各種シークレットの設定値
- `SSL_SHA256_FINGER_PRINT`:App Distributionのドメインで証明書発行時のSHA256ハッシュ
- `ANTHROPIC_API_KEY`:sk-xxx
- `FIREBASE_APP_ID`:FirebaseのAPPID
- `FIREBASE_HOSTING_DOMAIN`:{APPID}.web.app
- `GOOGLE_CLIENT_ID`:Google cloudのページから「APIとサービス」 > 認証情報 > 種類がAndroidのもの
- `GOOGLE_WEB_SERVER_CLIENT_ID`:Google cloudのページから「APIとサービス」 > 認証情報 > 種類がウェブアプリケーションのもの
- `KEYSTORE_PASSWORD`:`android\key.properties`のパスワード
- `KEY_ALIAS`:`android\key.properties`のエイリアス
- `KEY_PASSWORD`:`android\key.properties`のパスワード
- `MAPS_API_KEY`:Google cloudのページから「APIとサービス」 > 認証情報 > Google Map
- `STARBUCKS_WEB_URL`:Vercel上にデプロイしたプロジェクトのURL
- `SUPABASE_ANON_KEY`:Supabaseダッシュボードから取得
- `SUPABASE_URL`:Supabaseダッシュボードから取得
- `GOOGLE_SERVICES_JSON`:`android\app\google-services.json`をbase64でデコードした文字列
- `FIREBASE_HOSTING_DEPLOY_SERVICE_ACCOUNT_JSON`:サービスアカウント：`only-firebasehosting-admin`のjsonファイル（`assetlinks.json`更新時に自動デプロイ）
- `RELEASE_KEYSTORE`:`release.keystore`をbase64でデコードした文字列
- `CREDENTIAL_FILE_CONTENT`:FirebaseサービスアカウントのJSONファイル（これはそのまま）
