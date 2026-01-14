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
│  │     Email Login Form        │    │ EmailPasswordLoginForm
│  └─────────────────────────────┘    │
│                                     │
│  ────────────────────────────────   │ Divider
│                                     │
│  ┌─────────────────────────────┐    │
│  │    Google Login Button      │    │ GoogleLoginButton
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### 1.2 コンポーネント詳細

#### 1.2.1 AppBar
```dart
AppBar(
  scrolledUnderElevation: 0,
  backgroundColor: Colors.white,
  leading: IconButton(icon: Icons.arrow_back_ios_new)
)
```

- **背景色**: 白色 (`Color(0xFFFFFFFF)`)
- **戻るボタン**: iOS スタイルの戻るアイコン
- **影**: スクロール時の影を無効化

#### 1.2.2 Header
```dart
Container(
  width: double.infinity,
  color: Color(0xFFFFFFFF),
  padding: EdgeInsets.only(left: 15, right: 15, bottom: 10),
  child: Text('会員ログイン', fontSize: 28)
)
```

- **タイトル**: "会員ログイン"
- **フォントサイズ**: 28
- **影**: Material elevation 1.0

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
```dart
TextFormField(
  key: Key('login_form_email'),
  decoration: InputDecoration(
    labelText: 'メールアドレス',
    border: UnderlineInputBorder(),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: MyColors.loginFormField)
    )
  ),
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty == true 
    ? 'メールアドレスを入力してください' : null
)
```

- **キーボードタイプ**: EmailAddress
- **バリデーション**: 必須入力チェック
- **フォーカス時**: カスタムカラーのアンダーライン

#### 2.2.2 パスワードフィールド
```dart
TextFormField(
  key: Key('login_form_password'),
  decoration: InputDecoration(
    labelText: 'パスワード',
    border: UnderlineInputBorder(),
    suffixIcon: GestureDetector(
      onTap: _togglePasswordView,
      child: Icon(_isHiddenPassword ? Icons.visibility : Icons.visibility_off)
    )
  ),
  obscureText: _isHiddenPassword,
  validator: (value) => value?.isEmpty == true 
    ? 'パスワードを入力してください' : null
)
```

- **表示制御**: タップで表示/非表示切り替え
- **バリデーション**: 必須入力チェック
- **アイコン**: visibility / visibility_off

### 2.3 ログインボタン

```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: _isFormValid ? MyColors.greenButton : Colors.grey,
    padding: EdgeInsets.symmetric(horizontal: 20)
  ),
  onPressed: _isFormValid ? _handleAuthentication : null,
  child: Text('ログイン', style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w700
  ))
)
```

- **サイズ**: 150x50
- **有効時**: 緑色背景 (`MyColors.greenButton`)
- **無効時**: グレー背景、タップ無効
- **テキスト**: 白色、太字

### 2.4 パスワードリセットリンク

```dart
Text(
  'パスワードをお忘れの方',
  style: TextStyle(
    decoration: TextDecoration.underline,
    color: Color(0xFF9B9B9B)
  )
)
```

- **スタイル**: アンダーライン付き
- **色**: グレー (`Color(0xFF9B9B9B)`)
- **動作**: Starbucks Webページへ遷移

## 3. GoogleLoginButton

### 3.1 ボタンデザイン

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    elevation: 1,
    backgroundColor: Colors.white,
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
- **角の丸み**: 30px
- **影**: elevation 1
- **アイコン**: Googleロゴ（24px）
- **テキスト**: "Googleログイン" (16px)

## 4. ローディング状態

### 4.1 全画面ローディング

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

### 4.2 生体認証ローディング（準備済み）

```dart
Column(
  mainAxisAlignment: .center,
  children: [
    CircularProgressIndicator(),
    SizedBox(height: 16),
    Text('指紋認証を行っています...', fontSize: 16)
  ]
)
```

## 5. レスポンシブ対応

### 5.1 画面サイズ対応
- **パディング**: 水平15px
- **固定要素**: ヘッダー高さ100px
- **キーボード**: `resizeToAvoidBottomInset: false`

### 5.2 フォーカス管理
- **フォーカス解除**: 認証処理時に`FocusScope.of(context).unfocus()`
- **キーボード外観**: `keyboardAppearance: Brightness.light`

## 6. アクセシビリティ

### 6.1 キー識別子
- メールフィールド: `Key('login_form_email')`
- パスワードフィールド: `Key('login_form_password')`

### 6.2 フォーカス順序
1. メールアドレスフィールド
2. パスワードフィールド
3. ログインボタン
4. Googleログインボタン

## 7. カスタムカラー定義

| 要素 | カラー定数 | 用途 |
|------|-----------|------|
| フォーカス時ボーダー | `MyColors.loginFormField` | フォーム入力フィールド |
| ログインボタン | `MyColors.greenButton` | 有効時ボタン背景 |
| プログレスインジケーター | `MyColors.circularProgressIndicatorColor` | ローディング |
| 区切り線 | `MyColors.settingDivider` | セクション区切り |