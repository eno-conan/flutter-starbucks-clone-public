# ログイン機能 UI仕様書

## 1. 画面構成

### 1.1 LoginPage（メイン画面）

```
┌─────────────────────────────────────┐
│ [←] ← Back Button                   │ AppBar
├─────────────────────────────────────┤
│            会員ログイン              │ Header
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │  パスキーでログイン          │    │ PasskeyLoginButton
│  └─────────────────────────────┘    │ （パスキーが使える端末のみ）
│  ────────────────────────────────   │ Divider（パスキー表示時のみ）
│                                     │
│  ┌─────────────────────────────┐    │
│  │    Google Login Button      │    │ GoogleLoginButton
│  └─────────────────────────────┘    │
│                                     │
│  ────────────────────────────────   │ Divider
│                                     │
│  ┌─────────────────────────────┐    │
│  │     Email Login Form        │    │ EmailPasswordLoginForm
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

- 本文は縦にスクロールできる（`SingleChildScrollView`）。
- 並び順の方針は、[0002: ログイン手段の整理](../../design/0002-login-methods-organization.md) を参照。
- 認証手段ごとの部品は、`lib/screens/starbucks_user_side/signin/` 配下のファイルに分けて置く。

| ファイル | 内容 |
|---|---|
| `login.dart` | `LoginPage`（画面の状態・遷移・ローディング）と `_Header` |
| `widgets/passkey_login_button.dart` | `PasskeyLoginButton` |
| `widgets/google_login_button.dart` | `GoogleLoginButton` |
| `widgets/email_password_login_form.dart` | `EmailPasswordLoginForm` |
| `widgets/reset_password_link.dart` | `ResetPasswordLink`（`EmailPasswordLoginForm` の下に表示） |

#### 1.1.1 認証手段の並び順

| 順 | 手段 | 表示条件 |
|---|---|---|
| 1 | パスキーでログイン | この端末でパスキーが使える場合のみ |
| 2 | Google ログイン | 常に表示（店舗側から来たとき、つまりクエリ `redirect` が許可されたときは表示しない） |
| 3 | メールアドレス・パスワード | 常に表示（折り畳まない） |

- 指紋・顔認証は、独立した手段ではない。パスキーを使うときに OS が出す解錠の画面。

### 1.2 コンポーネント詳細

#### 1.2.1 AppBar

```dart
AppBar(
  scrolledUnderElevation: 0,
  backgroundColor: _isLoading ? Colors.black38 : DesignTokens.colorSemanticBackgroundSurface,
  leading: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
)
```

- **背景色**: `DesignTokens.colorSemanticBackgroundSurface`（白）。ローディング中だけ `Colors.black38`（全画面のオーバーレイと同じ色）
- **戻るボタン**: iOS スタイルの戻るアイコン。タップで `context.pop()`
- **影**: スクロール時の影を無効化

#### 1.2.2 Header

```dart
Material(
  elevation: 1.0,
  child: Container(
    width: double.infinity,
    color: DesignTokens.colorSemanticBackgroundSurface,
    padding: EdgeInsets.only(left: 15, right: 15, bottom: 10),
    child: MyCustomText(text: '会員ログイン', fontSize: 28),
  ),
)
```

- **タイトル**: "会員ログイン"（`LoginPage.title` の既定）
    - 店舗側から来たとき（クエリ `redirect` が許可されたとき。Google ログインを出さないときと同じ条件）は、"店舗ログイン"（`LoginPage.storeSideTitle`）。会員側と同じ画面を使うため、区別を出す。
- **フォントサイズ**: 28
- **背景色**: `DesignTokens.colorSemanticBackgroundSurface`
- **影**: Material elevation 1.0

#### 1.2.3 PasskeyLoginButton

- **表示条件**: この端末でパスキーが使える場合のみ（`passkeyStateProvider` の `canUsePasskey`）。
- **ラベル**: "パスキーでログイン"（指紋アイコン付き）。
- **サイズ**: 240x50、角の丸み 25px、背景は `MyColors.backgroundGold`。
- **起動**: 画面表示時の自動起動はしない。必ずボタンのタップを起点にする。
- **キャンセル**: 何も表示せず、同じ画面に戻る。他の手段をそのまま選べる。
- **失敗**: SnackBar にメッセージを表示する。他の手段をそのまま選べる。
- **成功**: Home 画面へ遷移する（店舗側から来た場合は、クエリ `redirect` が指す店舗側の注文一覧へ戻る）。FCM トークン登録は `FcmTokenSyncService` が行う（この画面では呼ばない）。

## 2. EmailPasswordLoginForm

### 2.1 フォーム構成

```
┌─────────────────────────────────────┐
│  メールアドレス                      │ TextFormField
│  ___________________________        │ UnderlineInputBorder
│                                     │
│  パスワード                  [👁]    │ TextFormField + Visibility Icon
│  ___________________________        │ UnderlineInputBorder
│                                     │
│        ┌─────────────┐              │
│        │  ログイン   │              │ FilledButton
│        └─────────────┘              │
│                                     │
│     パスワードをお忘れの方           │ Link (Underlined Text)
└─────────────────────────────────────┘
```

### 2.2 フィールド仕様

#### 2.2.1 メールアドレスフィールド

??? example "コード例（14 行）"
    ```dart
    TextFormField(
      key: Key('login_form_email'),
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'メールアドレス',
        border: UnderlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      keyboardAppearance: Brightness.light,
      validator: (value) {
        if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
        return null;
      },
    )
    ```

- **キーボードタイプ**: EmailAddress
- **バリデーション**: 必須入力チェック
- **フォーカス時**: `DesignTokens.colorSemanticActionPrimary`（緑）のアンダーライン
    - このフォームでは指定しない。アプリ共通テーマ（`app.dart` の `inputDecorationTheme.focusedBorder`）が付ける。

#### 2.2.2 パスワードフィールド

??? example "コード例（17 行）"
    ```dart
    TextFormField(
      key: Key('login_form_password'),
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'パスワード',
        border: UnderlineInputBorder(),
        suffixIcon: GestureDetector(
          onTap: _togglePasswordView,
          child: Icon(_isHiddenPassword ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      obscureText: _isHiddenPassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'パスワードを入力してください';
        return null;
      },
    )
    ```

- **表示制御**: タップで表示/非表示切り替え
- **バリデーション**: 必須入力チェック
- **アイコン**: visibility / visibility_off

### 2.3 ログインボタン

??? example "コード例（14 行）"
    ```dart
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _isFormValid ? MyColors.greenButton : Colors.grey,
        padding: EdgeInsets.symmetric(horizontal: 20),
      ),
      onPressed: _isFormValid
          ? () {
              if (_formKey.currentState!.validate()) {
                _handleAuthenticationByEmailAndPassword();
              }
            }
          : null,
      child: MyCustomText(text: 'ログイン', textColor: Colors.white, fontWeight: FontWeight.w700),
    )
    ```

- **サイズ**: 150x50
- **有効時**: 緑色背景 (`MyColors.greenButton`)
- **無効時**: グレー背景、タップ無効
- **テキスト**: 白色、太字
- **ログイン済みで押したとき**: サインインではなく、サインアウトして SnackBar「サインアウトしました。」を出す（`retrieveLoginUser()` が `null` 以外のとき。3.2 の注記と同じ挙動）

### 2.4 パスワードリセットリンク

```dart
Text(
  'パスワードをお忘れの方',
  style: TextStyle(
    decoration: TextDecoration.underline,
    color: DesignTokens.colorSemanticTextMuted,
  ),
)
```

- **スタイル**: アンダーライン付き
- **色**: グレー (`DesignTokens.colorSemanticTextMuted`)
- **動作**: Starbucks Webページへ遷移

## 3. GoogleLoginButton

### 3.1 ボタンデザイン

??? example "コード例（16 行）"
    ```dart
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: DesignTokens.colorSemanticTextPrimary,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
      ),
      child: Row(
        children: [
          Image.asset('assets/google_logo.png', height: 24),
          SizedBox(width: 15),
          Text('Googleログイン', fontSize: 16)
        ]
      )
    )
    ```

- **背景色**: 白色
- **文字色**: `DesignTokens.colorSemanticTextPrimary`
    - 共通テーマの `ElevatedButton` は文字色が白（緑ボタン用）なので、白地では見えない。そのため明示する。
- **角の丸み**: 30px
- **影**: elevation 1
- **アイコン**: Googleロゴ（24px）
- **テキスト**: "Googleログイン" (16px)

### 3.2 タップ時の動作

1. ボタンをタップすると、`signInWithGoogleOAuth()` が呼び出される。
2. ブラウザが起動し、Google OAuth 認証画面が表示される。
3. ブラウザが起動した時点で、ローディング表示は解除される。
4. 認証完了後、アプリがカスタムスキームのディープリンク（`testingapp://callback`）を受信する。
    - `redirectTo` は debug / release 共通で `testingapp://callback`（`AuthService.signInWithGoogleOAuth`）。
    - 理由: Chrome Custom Tab 内では、HTTPS の App Links が確実に動かないため。
    - 受信側（`app.dart`）は HTTPS の `/callback` も処理できるが、現在の `redirectTo` では使わない。
5. セッションの確立は、`supabase_flutter` のディープリンク処理が行う。
    - `app.dart` の `_handleOAuthCallback()` は、`onAuthStateChange` の `signedIn` を最大 5 秒待つ。
    - セッションを確認できたら、Home 画面へ遷移する。確認できなければ、遷移しない（[エラーハンドリング仕様書](./error-handling.md) の 3.2）。

!!! note "ログイン済みで押すと、サインインではなくサインアウトする"
    - `LoginPage` が持つ `email`（`onAuthStateChange` で更新する）が `null` でないとき、ボタンは `signOutWithEmailAndPassword()` を呼び、SnackBar「サインアウトしました。」を出す。ラベルは空文字になる。
    - ログインの FAB は未ログイン時だけ表示する（`auth_state_fab.dart`）。そのため通常の導線では到達せず、この画面が開いたままログイン済みになった場合に限る。
    - 通常のログアウトは、設定画面から行う（[設計書 0005](../../design/0005-login-and-session.md) の 3.5）。

## 4. ローディング状態

### 4.1 全画面ローディング

??? example "コード例（10 行）"
    ```dart
    Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: CircularProgressIndicator(
            color: MyColors.circularProgressIndicatorColor
          )
        )
      )
    )
    ```

- **オーバーレイ**: 半透明黒背景
- **インジケーター**: カスタムカラーの円形プログレス
- **表示条件**: `_isLoading = true`

## 5. レスポンシブ対応

### 5.1 画面サイズ対応

- **パディング**: 水平15px
- **ヘッダーとの重なり**: ヘッダー（`_Header`）は本文に重ねて表示する。本文の先頭に高さ 100 の余白（`SizedBox(height: 100)`）を置き、本文が隠れないようにしている。
- **キーボード**: 本文が `SingleChildScrollView` のため、キーボード表示時は本文の高さが縮み、フォーカスした入力欄が見える位置までスクロールする（`Scaffold` の既定の `resizeToAvoidBottomInset`）。
    - メールアドレス・パスワードは画面の最下部にあるため、この挙動で入力欄がキーボードに隠れないようにしている。

### 5.2 フォーカス管理

- **フォーカス解除**: 認証処理時に`FocusScope.of(context).unfocus()`
- **キーボード外観**: `keyboardAppearance: Brightness.light`

## 6. アクセシビリティ

### 6.1 キー識別子

- メールフィールド: `Key('login_form_email')`
- パスワードフィールド: `Key('login_form_password')`

### 6.2 フォーカス順序

1. パスキーでログインボタン（表示されている場合）
2. Googleログインボタン
3. メールアドレスフィールド
4. パスワードフィールド
5. ログインボタン

## 7. カスタムカラー定義

| 要素 | カラー定数 | 用途 |
|------|-----------|------|
| AppBar・ヘッダーの背景 | `DesignTokens.colorSemanticBackgroundSurface` | 画面上部 |
| フォーカス時ボーダー | `DesignTokens.colorSemanticActionPrimary` | フォーム入力フィールド（アプリ共通テーマで指定） |
| ログインボタン | `MyColors.greenButton`（`DesignTokens.colorSemanticActionPrimary` の別名） | 有効時ボタン背景 |
| パスキーボタン | `MyColors.backgroundGold`（`DesignTokens.colorBrandGold` の別名） | ボタン背景 |
| Google ボタンの文字 | `DesignTokens.colorSemanticTextPrimary` | 白地での文字色 |
| パスワードリセットリンク | `DesignTokens.colorSemanticTextMuted` | 補助的なリンク文字 |
| プログレスインジケーター | `MyColors.circularProgressIndicatorColor` | ローディング |
| 区切り線 | `MyColors.settingDivider` | セクション区切り |