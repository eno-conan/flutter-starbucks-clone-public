# ログイン機能 エラーハンドリング仕様書

## 1. エラーハンドリング概要

- 対象: 認証プロセス、ネットワーク通信、ユーザー入力バリデーションなどで起きうるエラー。
- 方針: エラーを適切に処理し、ユーザーにわかりやすいフィードバックを返す。
- 各エラーの実装コードは、折り畳み（`コード例`）の中にある。

## 2. エラー分類

### 2.1 バリデーションエラー（クライアントサイド）

| エラータイプ | 発生条件 | エラーメッセージ | 対処方法 |
|-------------|---------|-----------------|---------|
| 必須入力エラー（メール） | メールアドレス未入力 | "メールアドレスを入力してください" | フォームバリデーション |
| 必須入力エラー（パスワード） | パスワード未入力 | "パスワードを入力してください" | フォームバリデーション |

#### 実装詳細

??? example "コード例（15 行）"
    ```dart
    // メールアドレスバリデーター
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'メールアドレスを入力してください';
      }
      return null;
    }

    // パスワードバリデーター  
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'パスワードを入力してください';
      }
      return null;
    }
    ```

### 2.2 認証エラー（サーバーサイド）

#### 2.2.1 メール・パスワード認証エラー

??? example "コード例（21 行）"
    ```dart
    Future<void> _handleAuthenticationByEmailAndPassword() async {
      try {
        await widget.authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } on PlatformException catch (e) {
        if (mounted) {
          widget.onLoadingStateChanged(false);
        }
        if (kDebugMode) {
          LoggerService.warn('ログイン処理でエラー発生: $e');
        }
        widget.showSnackBar('認証処理に失敗しました(メールアドレス)');
      } catch (err) {
        if (mounted) {
          widget.onLoadingStateChanged(false);
        }
        widget.showSnackBar('$err:認証処理に失敗(メールアドレス)');
      }
    }
    ```

- `AuthService.signInWithEmailAndPassword` は、失敗すると Crashlytics にエラーの種類だけを記録して `rethrow` する。
- メールアドレスとパスワードの値は、記録しない。

#### 2.2.2 Google認証エラー

??? example "コード例（30 行）"
    ```dart
    Future<void> _handleAuthenticationByGoogle(BuildContext context) async {
      onLoadingStateChanged(true);
      try {
        if (email != null) {
          await authService.signOutWithEmailAndPassword();
          showSnackBar('サインアウトしました。');
        } else {
          // ブラウザを開いて Google OAuth 認証（コールバックは app.dart で処理）
          await authService.signInWithGoogleOAuth();
          // ブラウザが開いたのでローディングを解除（認証完了はディープリンクで処理）
          if (context.mounted) {
            onLoadingStateChanged(false);
          }
          return;
        }
      } on PlatformException catch (e) {
        if (context.mounted) {
          onLoadingStateChanged(false);
        }
        if (kDebugMode) {
          LoggerService.warn(email != null ? 'ログアウト処理でエラー発生: $e' : 'ログイン処理でエラー発生: $e');
        }
        showSnackBar('認証処理に失敗しました(PlatformException)');
      } catch (err) {
        if (context.mounted) {
          onLoadingStateChanged(false);
        }
        showSnackBar('$err:認証処理に失敗しました(OtherException)');
      }
    }
    ```

## 3. Google OAuth 固有エラー

### 3.1 ブラウザ起動エラー

- `signInWithGoogleOAuth()` は、`supabase.auth.signInWithOAuth()` を呼んでブラウザを起動する。
- ブラウザが起動できない場合（`PlatformException`）は、呼び出し元でキャッチされる。

```dart
Future<void> signInWithGoogleOAuth() async {
  // Chrome Custom Tab 内では HTTPS App Links が確実に動作しないため、
  // カスタムスキームを debug/release 共通で使用する
  await _supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'testingapp://callback');
}
```

### 3.2 OAuthコールバックタイムアウトエラー

- 発生条件: ディープリンクの受信時にセッションが無く、`signedIn` イベントが 5 秒以内に来ない。
- 動作: Home 画面への遷移は行われない。`kDebugMode` のときだけ、Warning ログを出す。

??? example "コード例（15 行）"
    ```dart
    // app.dart の _handleOAuthCallback() から抜粋
    try {
      final authData = await supabase.auth.onAuthStateChange
          .where((data) => data.event == AuthChangeEvent.signedIn && data.session != null)
          .first
          .timeout(const Duration(seconds: 5));
      session = authData.session;
    } catch (e) {
      LoggerService.warn('OAuth セッション確立待機エラー: $e');
    }

    if (session == null) {
      LoggerService.warn('OAuth session が存在しません');
      // ホーム画面への遷移は行われない
    }
    ```

### 3.3 セッション未確立エラー

- 発生条件: ディープリンクの受信後も、セッションが確立されない。
- 動作:
    - 3.2 と同じく、Home 画面へは遷移しない。
    - ユーザーは、再度ログインを試みる必要がある。

!!! danger "`app.dart` から `getSessionFromUrl()` を呼ばない"
    - URL からのセッション確立は、`supabase_flutter` のディープリンク処理が行う。
    - PKCE の flow state は一度しか使えない。二重に呼ぶと、後から来たほうが `flow_state_not_found` で失敗する。
    - 失敗は未捕捉の非同期エラーとして Crashlytics に残る。

## 4. パスキー認証エラー

- パスキーの失敗は、`PasskeyAuthService` が `PasskeyException`（種別 `PasskeyFailureType` とユーザー向けメッセージ）に変換する。
- 画面（`LoginPage._signInWithPasskey`）は、`passkeys` パッケージの例外型を知らずに、種別だけで分岐する。
- 設計の背景は [設計書 0001](../../design/0001-passkey-introduction.md) を参照。

### 4.1 失敗種別と表示

| 種別 | 発生条件 | 表示（SnackBar） |
|------|---------|----------------|
| `cancelled` | ユーザーが OS のダイアログをキャンセル | 何も表示しない |
| `noCredentials` | この端末に使えるパスキーが無い | "この端末にパスキーがありません。メールアドレスでログインしてください" |
| `unsupported` | 端末・OS が非対応 | "この端末はパスキーに対応していません" |
| `osAccountRequired` | Google アカウント未設定など、OS 側の前提が不足 | "端末に Google アカウントと画面ロックを設定してからお試しください" |
| `notConfigured` | `assetlinks.json` / `apple-app-site-association` の不備 | "パスキーを利用できません。メールアドレスでログインしてください" |
| `server` | Supabase 側の検証失敗 | "パスキーでのログインに失敗しました" |
| `unknown` | 上記以外 | "パスキーでのログインに失敗しました" |
| （想定外の例外） | `PasskeyException` 以外が `LoginPage` まで届いた | "パスキーでのログインに失敗しました"。`LoggerService.warn` に記録する |

- `alreadyRegistered`（この端末に登録済み）は、登録時にだけ起きる。ログイン画面には出ない。

### 4.2 画面側の扱い

- いずれの失敗でも、ローディングを解除する。
- キャンセルのときは、何も表示せず同じ画面に戻る。他の手段をそのまま選べる。
- それ以外は SnackBar にメッセージを出す。他の手段をそのまま選べる。
- 非同期処理のあとは、`mounted` を確認してから画面を操作する。
- チャレンジ・資格情報・パスキー ID は機密のため、ログに出さない。ログに残すのは、操作名と例外の種別だけ。

## 5. FCMトークン関連エラー

### 5.1 トークンリフレッシュ時のエラー

- トークンの更新は、`FcmTokenSyncService.start()` が `onTokenRefresh` を購読して登録し直す（アプリ起動時に 1 回だけ。[設計書 0003](../../design/0003-push-notification.md)）。
- ログイン画面では購読しない。認証イベントのたびにリスナーが増えるため。
- 登録処理の例外は、`_registerFcmToken` で握りつぶし、`LoggerService.warn` に記録する。キューを壊すと、以降の登録が一切走らなくなるため。

??? example "コード例（9 行）"
    ```dart
    // fcm_token_sync_service.dart の _registerFcmToken() から抜粋
    try {
      if (_supabase.auth.currentSession == null) {
        return;
      }
      await _notificationService.requestPermissionAfterLogin();
    } catch (error) {
      LoggerService.warn('FCMトークン登録に失敗しました: 契機=$reason', error);
    }
    ```

### 5.2 トークン設定エラー

- 未ログインのときは、Warning ログを出してスキップする。
- 登録に失敗したときは、Crashlytics に記録して `rethrow` する。

??? example "コード例（28 行）"
    ```dart
    Future<void> setFcmTokenAndNotifySetting(
      String fcmToken,
      bool isNotify, {
      required String deviceId,
      String? deviceName,
    }) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.warn('FCMトークン登録: ユーザーが未ログインのためスキップ');
        return;
      }
      try {
        await _userFcmTokenRepository.upsertFcmToken(
          userId: userId,
          deviceId: deviceId,
          deviceName: deviceName,
          fcmToken: fcmToken,
          isNotify: isNotify,
        );
      } catch (error) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          StackTrace.current,
          reason: 'FCM token registration failed',
        );
        rethrow;
      }
    }
    ```

## 6. 初期化エラー

!!! note "Supabase セッションのチェックに、明示的な初期化は不要"
    - Supabase セッションのチェックは、`onAuthStateChange` で自動的に行われる。
    - そのため、`initializeGoogleSignIn()` のような明示的な初期化処理は不要。

## 7. ユーザー状態関連エラー

### 7.1 未認証ユーザーエラー

```dart
String getUserId() {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) {
    LoggerService.warn('ユーザーが認証されていません');
    // 通常のログインチェック失敗なので Crashlytics には記録しない
    throw Exception('ユーザーが認証されていません');
  }
  return userId;
}
```

- 例外を出したくない場面（ディープリンク処理など）では、`checkUserLoginStatus()` を使う。ユーザー ID または `null` を返す。

### 7.2 セッション取得エラー

```dart
Future<String?> retrieveLoginUser() async {
  try {
    final User? user = _supabase.auth.currentUser;
    return user?.email;
  } catch (error) {
    rethrow;
  }
}
```

## 8. Widget状態関連エラー

### 8.1 マウント状態チェック

```dart
if (!mounted) {
  return; // Widgetが既に破棄されている場合は処理を中断
}

void _navigateToHome() {
  if (mounted) {
    context.go(Home.routeName);
  }
}
```

### 8.2 フォーム状態エラー

```dart
void _validateForm() {
  final newFormValid = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  // 状態が変わった場合のみ setState を実行
  if (_isFormValid != newFormValid) {
    setState(() {
      _isFormValid = newFormValid;
    });
  }
}
```

- 両方の入力欄に値があるときだけ、ログインボタンを有効にする。
- 値が変わるたびに呼ばれるため（コントローラーのリスナー）、状態が変わるときだけ `setState` する。

## 9. エラーメッセージ表示

### 9.1 SnackBar実装

```dart
void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3)
    )
  );
}
```

### 9.2 エラーメッセージ一覧

| カテゴリ | メッセージ | 表示タイミング |
|---------|-----------|---------------|
| バリデーション | "メールアドレスを入力してください" | メールフィールド未入力時 |
| バリデーション | "パスワードを入力してください" | パスワードフィールド未入力時 |
| メール認証 | "認証処理に失敗しました(メールアドレス)" | メール認証失敗時 |
| Google OAuth | "認証処理に失敗しました(PlatformException)" | ブラウザ起動失敗時 |
| Google OAuth | "認証処理に失敗しました(OtherException)" | OAuth認証その他例外 |
| パスキー | 4.1 の表を参照 | パスキーでのログイン失敗時（キャンセルを除く） |
| ログアウト | "サインアウトしました。" | ログアウト成功時 |

## 10. デバッグモード対応

### 10.1 デバッグ専用ログ出力

```dart
if (kDebugMode) {
  LoggerService.warn('ログイン処理でエラー発生: $e');
  LoggerService.info('デバイストークン登録');
}
```

- ログは `LoggerService` で出す。`print()` は使わない（`avoid_print`）。

### 10.2 本番環境でのエラー情報制限

- デバッグ詳細情報は`kDebugMode`でラップ
- ユーザーには技術的詳細を含まない簡潔なメッセージを表示
- スタックトレース等の機密情報は本番では出力しない

## 11. ローディング状態管理

### 11.1 エラー時のローディング解除

```dart
try {
  // 認証処理
} catch (error) {
  widget.onLoadingStateChanged(false); // 必ずローディングを解除
  widget.showSnackBar('エラーメッセージ');
}
```

### 11.2 ローディング状態の初期化

```dart
@override
void initState() {
  super.initState();
  // 初期状態でローディングは無効
  // _isLoading = false (デフォルト)
}
```

## 12. エラー復旧戦略

### 12.1 自動リトライ機能

!!! note "現在の実装に、自動リトライ機能はない"
    将来的な実装に向けた、考慮事項を挙げる。

- ネットワーク一時的なエラー時のリトライ
- トークンリフレッシュ失敗時の再試行
- 認証タイムアウト時の再認証

### 12.2 ユーザーアクション推奨

- 認証失敗時：入力内容の確認を促すメッセージ
- ネットワークエラー時：接続状況の確認を促すメッセージ
- プラットフォームエラー時：アプリ再起動を促すメッセージ

## 13. ログ収集とモニタリング

### 13.1 エラー情報の収集

- ログは `LoggerService` で出す。リリースビルドでは、コンソールには出さない。
- `LoggerService.warn` 以上は、リリースビルドで Crashlytics にも送る（`logger_service.dart`）。
    - 例外オブジェクトを渡したとき: 非致命エラーとして記録する。
    - メッセージだけのとき: Crashlytics のログ（パンくず）に留める。
- `AuthService` は、次の失敗を Crashlytics に直接記録する。
    - メール・パスワードのサインイン失敗（資格情報は含めない）
    - サインアウトの失敗
    - FCM トークン登録の失敗
- ログイン成功時は、Crashlytics にユーザー識別子（UUID）を設定する。サインアウト時にクリアする。

??? info "ログイン手段ごとの記録の違い"
    | 手段 | リリースビルドでの記録 |
    |---|---|
    | メール・パスワード | `AuthService` が非致命エラーを記録（上記） |
    | Google | `GoogleLoginButton` のログは `kDebugMode` のときだけ。リリースでは記録されない |
    | パスキー | `notConfigured` / `server` / `unknown` は、例外付きの `warn` で非致命エラーになる。`noCredentials` / `unsupported` / `osAccountRequired` は、メッセージだけなのでパンくずに留まる。キャンセルは `info` のため記録しない |

!!! warning "未実装の検討事項"
    - カスタムログ収集システムの実装
    - パフォーマンスメトリクスの追跡

### 13.2 監視指標

- 認証成功/失敗率
- 各認証方式の利用率
- エラーレスポンス時間
- ユーザー離脱率（認証失敗後）