# 開発環境セットアップ

## クイックスタート

### 必須要件

- Flutter 3.47.7（FVM での管理を推奨）
- Dart >=3.10.0
- Android Studio / Xcode
- Firebase プロジェクト
- Supabase プロジェクト

### セットアップ手順

1. **リポジトリをクローンする**

    ```bash
    git clone https://github.com/eno-conan/flutter-starbucks-clone.git
    cd flutter-starbucks-clone
    ```

2. **FVM をセットアップする**

    ```bash
    dart pub global activate fvm
    fvm install
    fvm use --force
    ```

3. **依存関係をインストールする**

    ```bash
    fvm flutter pub get
    ```

4. **環境設定をする**

    ```bash
    # Firebase設定
    flutterfire configure

    # Supabase設定（環境変数）
    cp .env.example .env
    # .envファイルを編集してSupabase認証情報を追加
    ```

5. **アプリを実行する**

    ```bash
    # デバッグ実行
    fvm flutter run

    # リリースビルド
    fvm flutter build apk --release
    ```

## Flutter SDKバージョン管理（FVM）

- このプロジェクトでは、[FVM (Flutter Version Management)](https://fvm.app/) で、Flutter SDK のバージョンを管理している。

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

- FVM をインストールした後は、通常の `flutter` コマンドの代わりに、`fvm flutter` を使う。

```sh
# 例：パッケージ取得
fvm flutter pub get

# 例：アプリ実行
fvm flutter run

# 例：ビルド
fvm flutter build apk
```

!!! tip "エイリアス設定（推奨）"
    頻繁に使う場合は、シェルのエイリアスを設定すると便利。

    ```sh
    # ~/.bashrc または ~/.zshrc に追加
    alias flutter="fvm flutter"
    alias dart="fvm dart"
    ```

### VS Code設定

- `.vscode/settings.json` に、すでに FVM 設定が追加されている。
- そのため、VS Code は自動的に FVM の Flutter SDK を使う。
- **固定される Flutter バージョン**: `3.47.7`

## 依存関係管理

### 依存関係確認

- 関連 Issue: [#163](https://github.com/eno-conan/flutter-starbucks-clone/issues/163)
- パッケージの依存関係を確認したい場合は、次のコマンドで情報を収集する。

```sh
flutter pub deps > deps.txt
```

### 依存関係上書き

- ローカル開発で `envied` の修正版を使う場合は、`pubspec_overrides.yaml` を作成する。

```yaml
dependency_overrides:
  envied:
    path: /path/to/your/envied/packages/envied
  envied_generator:
    path: /path/to/your/envied/packages/envied_generator
```

!!! note "このファイルは `.gitignore` 対象"
    `pubspec_overrides.yaml` は、コミットされない。

## 環境変数の扱い

- [参考記事](https://codewithandrea.com/articles/flutter-api-keys-dart-define-env-files/)
- [Notion](https://www.notion.so/16b8580db1958025bc09e33accf7dcca)

## 各種シークレットの設定値

??? info "シークレット一覧（17 件）"
    | シークレット | 設定値 |
    |---|---|
    | `SSL_SHA256_FINGER_PRINT` | App Distribution のドメインで、証明書発行時の SHA256 ハッシュ |
    | `ANTHROPIC_API_KEY` | `sk-xxx` |
    | `FIREBASE_APP_ID` | Firebase の APP ID |
    | `FIREBASE_HOSTING_DOMAIN` | `{APPID}.web.app` |
    | `GOOGLE_CLIENT_ID` | Google Cloud のページから、「API とサービス」 > 認証情報 > 種類が Android のもの |
    | `GOOGLE_WEB_SERVER_CLIENT_ID` | Google Cloud のページから、「API とサービス」 > 認証情報 > 種類がウェブアプリケーションのもの |
    | `KEYSTORE_PASSWORD` | `android\key.properties` のパスワード |
    | `KEY_ALIAS` | `android\key.properties` のエイリアス |
    | `KEY_PASSWORD` | `android\key.properties` のパスワード |
    | `MAPS_API_KEY` | Google Cloud のページから、「API とサービス」 > 認証情報 > Google Map |
    | `STARBUCKS_WEB_URL` | Vercel 上にデプロイしたプロジェクトの URL |
    | `SUPABASE_ANON_KEY` | Supabase ダッシュボードから取得 |
    | `SUPABASE_URL` | Supabase ダッシュボードから取得 |
    | `GOOGLE_SERVICES_JSON` | `android\app\google-services.json` を base64 でデコードした文字列 |
    | `FIREBASE_HOSTING_DEPLOY_SERVICE_ACCOUNT_JSON` | サービスアカウント `only-firebasehosting-admin` の json ファイル（`assetlinks.json` 更新時に自動デプロイ） |
    | `RELEASE_KEYSTORE` | `release.keystore` を base64 でデコードした文字列 |
    | `CREDENTIAL_FILE_CONTENT` | Firebase サービスアカウントの JSON ファイル（これはそのまま） |
