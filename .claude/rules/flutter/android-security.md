---
description: Android セキュリティガイドライン（AndroidManifest.xml、Deep Link、権限管理）
paths:
  - "android/**/*"
---

# Android セキュリティガイドライン

Flutterアプリケーションにおけるしっかりしたセキュリティ実装のためのガイドライン

## 📋 概要

このドキュメントは、Flutter/Dartプロジェクトにおけるandroidセキュリティの実装と設定に関するガイドラインです。AndroidManifest.xmlの設定、Deep Link（App Links）のセキュリティ、ネットワークセキュリティ設定等について記載しています。

## 🔒 AndroidManifest.xml セキュリティ設定

### 1. バックアップ制御

```xml
<application
    android:allowBackup="false"
    ...>
```

**重要性**: ユーザーの機密情報（認証トークン、個人データ等）がAndroidのバックアップ機能により外部に流出することを防ぎます。

**推奨設定**:
- 本番環境: `false`（機密情報を扱うアプリでは必須）
- 開発環境: `false`（一貫性のため）

### 2. クリアテキストトラフィック制御

```xml
<application
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

**重要性**: HTTP通信を制限し、中間者攻撃（MITM）のリスクを軽減します。

**推奨設定**:
- 本番環境: `false`（HTTPS必須）
- 開発環境: `false` + network security configで例外管理

### 3. ネットワークセキュリティ設定

`android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 基本設定: HTTPS のみ -->
    <base-config cleartextTrafficPermitted="false" />

    <!-- 開発用の例外設定 -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">local.com</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

**利点**:
- 開発時のみHTTP接続を許可
- 本番環境では完全にHTTPS通信のみ
- 細かなドメイン単位での制御が可能

## 🔗 Deep Link（App Links）セキュリティ

### 1. AndroidManifest.xml設定

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    ...>

    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <!-- 開発用 -->
        <data
            android:scheme="http"
            android:host="local.com"
            android:pathPrefix="/register" />

        <!-- 本番用 -->
        <data
            android:scheme="https"
            android:host="${FIREBASE_HOSTING_DOMAIN}"
            android:pathPrefix="/register" />
    </intent-filter>
</activity>
```

### 2. Flutter側でのセキュリティ検証実装

`lib/app/app.dart`での実装例：

```dart
void openAppLink(Uri uri) {
  // 1. ホストの検証
  if (!_isValidHost(uri.host)) {
    if (kDebugMode) {
      print('Invalid host: ${uri.host}');
    }
    _router.go('/');
    return;
  }

  // 2. パスの検証
  final path = uri.path.isEmpty ? '/' : uri.path;
  if (path == '/register') {
    final token = uri.queryParameters['token'] ?? '';

    // 3. トークンの検証
    if (token.isEmpty || !_isValidToken(token)) {
      _router.go(SignUpError.routeName);
      return;
    }

    _router.go(SignUp.routeName, extra: {'token': token});
  } else {
    // 不正なパスの場合はホームページへ
    _router.go('/');
  }
}

/// ホストの妥当性を検証
bool _isValidHost(String host) {
  const allowedHosts = [
    'local.com',           // 開発用
    // 本番ホストは環境変数から取得
  ];

  return allowedHosts.contains(host);
}

/// トークンの基本的な検証
bool _isValidToken(String token) {
  // 長さ: 6-64文字
  if (token.length < 6 || token.length > 64) {
    return false;
  }

  // 文字種: 英数字とハイフン・アンダースコアのみ
  final tokenRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
  return tokenRegex.hasMatch(token);
}
```

### 3. Deep Linkセキュリティのベストプラクティス

**必須検証項目**:
1. **ホスト検証**: 許可されたホストからのリンクのみ処理
2. **パス検証**: サポートしているパスのみ処理
3. **パラメータ検証**: トークンや引数の形式・内容検証
4. **フォールバック**: 不正な場合の適切な処理（ホーム画面への遷移等）

**セキュリティリスク**:
- ❌ 検証なしのDeep Link処理
- ❌ 任意のホストからのリンクを処理
- ❌ 不正なパラメータの直接利用
- ❌ エラー時の情報漏洩

## 🔑 権限管理

### 1. 必要最小限の権限

現在のプロジェクトで使用中の権限：
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
```

### 2. 権限の検証と使用目的

| 権限 | 使用目的 | セキュリティレベル |
|-----|----------|-------------------|
| `INTERNET` | 通信機能 | 低 |
| `USE_BIOMETRIC` | 生体認証 | 中 |
| `ACCESS_FINE_LOCATION` | GPS（Maps機能） | 高 |
| `POST_NOTIFICATIONS` | プッシュ通知 | 低 |
| `RECEIVE_BOOT_COMPLETED` | 起動時の通知 | 中 |
| `VIBRATE` | 振動機能 | 低 |

**重要**: 各権限が本当に必要かを定期的に見直し、不要な権限は削除してください。

## 🛡️ API キー・シークレット管理

### 1. 環境変数での管理

```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />

<!-- Firebase App ID -->
<meta-data
    android:name="com.google.android.gms.appstate.APP_ID"
    android:value="${FIREBASE_APP_ID}" />
```

### 2. API キーの制限設定

**Google Maps API キー**:
- Android アプリの署名証明書（SHA-1/SHA-256）で制限
- 特定のパッケージ名での制限
- 必要なAPIのみ有効化

**Firebase設定**:
- プロジェクト固有の制限
- 適切なセキュリティルールの設定

## ⚠️ セキュリティチェックリスト

### リリース前の必須チェック項目

- [ ] `android:allowBackup="false"` が設定されている
- [ ] `android:usesCleartextTraffic="false"` が設定されている
- [ ] ネットワークセキュリティ設定が適切に構成されている
- [ ] Deep Linkでホスト・パス・パラメータの検証が実装されている
- [ ] 不要な権限が削除されている
- [ ] API キーが環境変数で管理されている
- [ ] API キーに適切な制限が設定されている
- [ ] エラーハンドリングで機密情報が漏洩しない

### 定期的な見直し項目

- [ ] 使用している権限の必要性
- [ ] API キーの制限設定
- [ ] Deep Link処理のセキュリティ
- [ ] サードパーティライブラリのセキュリティアップデート
- [ ] ネットワーク通信の暗号化状態

## 🔍 セキュリティテスト

### 1. Deep Linkテスト

```bash
# 正常なDeep Link
adb shell am start -W -a android.intent.action.VIEW -d "https://yourdomain.com/register?token=valid-token-123" com.yourpackage.name

# 不正なホストのテスト
adb shell am start -W -a android.intent.action.VIEW -d "https://malicious.com/register?token=valid-token-123" com.yourpackage.name

# 不正なトークンのテスト
adb shell am start -W -a android.intent.action.VIEW -d "https://yourdomain.com/register?token=<script>alert('xss')</script>" com.yourpackage.name
```

### 2. ネットワークセキュリティテスト

- Charles Proxy等でHTTP通信がブロックされることを確認
- 不正な証明書での接続が拒否されることを確認

## 📚 参考資料

- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [App Links の処理](https://developer.android.com/training/app-links)
- [Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)

## 🔧 実装時の注意点

### 1. 開発環境と本番環境の分離

- 開発時はHTTP通信を例外的に許可
- 本番環境では完全にHTTPS通信のみ
- 設定ファイルの環境毎の管理

### 2. エラーハンドリング

- セキュリティエラー時も適切なユーザー体験を提供
- デバッグ情報は開発環境でのみ表示
- ログに機密情報を出力しない

### 3. 継続的なセキュリティ改善

- セキュリティライブラリの定期的なアップデート
- 新しいセキュリティ脅威への対応
- セキュリティ設定の定期的な見直し
