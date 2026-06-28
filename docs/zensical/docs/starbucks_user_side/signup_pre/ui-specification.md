# 仮会員登録機能 UI仕様書

## 1. 概要

このドキュメントは、仮会員登録画面のUI/UX仕様に関する詳細を記載します。

## 2. 画面構成

### 2.1 全体レイアウト

```
┌─────────────────────────────────┐
│  AppBar (戻るボタン)            │
├─────────────────────────────────┤
│  Header (「会員登録」タイトル)   │
├─────────────────────────────────┤
│  Form Container                 │
│  ┌─────────────────────────────┐ │
│  │ 説明文                      │ │
│  │ メールアドレス入力欄        │ │
│  │ 受信設定に関する注意事項    │ │
│  │ 利用規約同意チェックボックス │ │
│  │ 確認メッセージ              │ │
│  │ 送信ボタン                  │ │
│  └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 2.2 コンポーネント詳細

#### AppBar
- **背景色**: `Colors.white`
- **Elevation**: `scrolledUnderElevation: 0`
- **戻るボタン**: `Icons.arrow_back_ios_new`
- **動作**: `context.pop()`

#### Header（_Header）
- **背景色**: `Colors.white`
- **Elevation**: `1.0`
- **パディング**: `EdgeInsets.only(left: 15, right: 15, bottom: 10)`
- **タイトル**: 「会員登録」（フォントサイズ: 28）

## 3. フォーム要素

### 3.1 メールアドレス入力欄

#### 基本設定
```dart
TextFormField(
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  cursorColor: MyColors.greenText,
)
```

#### デザイン仕様
- **ラベル**: 「メールアドレス」（フォントサイズ: 16）
- **フォーカスカラー**: `MyColors.greenText`
- **エナブルボーダー**: `UnderlineInputBorder` グレー
- **フォーカスボーダー**: `UnderlineInputBorder` グリーン
- **エラーテキストカラー**: `Colors.red`

#### インタラクション
- **リアルタイム更新**: 入力時に`setState()`でUIを更新
- **バリデーション**: フィールド送信時・編集完了時に実行
- **エラー表示**: 「不正なメールアドレス」メッセージ

### 3.2 利用規約同意

#### チェックボックス仕様
```dart
Transform.scale(
  scale: 1.6,
  child: Checkbox(
    side: BorderSide(color: MyColors.greenButton, width: 0.8),
    activeColor: MyColors.greenButton,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
)
```

- **スケール**: 1.6倍
- **ボーダー**: グリーン、幅0.8
- **アクティブカラー**: `MyColors.greenButton`
- **形状**: 角丸（radius: 4）

#### ラベル仕様
- **メインテキスト**: 「以下の利用規約に同意する」（フォントサイズ: 16）
- **リンクテキスト**: 「My Starbucks利用規約」（フォントサイズ: 16、色: `Colors.green`）

### 3.3 送信ボタン（_ButtonSendEmail）

#### デザイン仕様
```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: isFormValid ? MyColors.greenButton : Color(0xFF999999),
    minimumSize: const Size(0, 60),
    padding: const EdgeInsets.symmetric(horizontal: 25),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  ),
)
```

- **高さ**: 60px
- **パディング**: 水平25px
- **角丸**: 30px
- **有効時背景色**: `MyColors.greenButton`
- **無効時背景色**: `Color(0xFF999999)`
- **テキスト**: 「送信する」（白色、フォントサイズ: 18、ウェイト: 500）

## 4. 状態管理とUI連動

### 4.1 フォーム有効性表示

#### 条件
- メールアドレス形式が正しい
- 利用規約に同意している

#### UI反映
- **ボタン色変更**: グレー → グリーン
- **ボタン有効化**: `onPressed: null` → 実際の処理関数

### 4.2 入力内容確認表示

#### 表示条件
```dart
if (_emailController.text.isNotEmpty)
  MyCustomText(
    text: _emailController.text,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  )
```

- **位置**: 「こちらでよろしいでしょうか」の下
- **フォント**: 太字、サイズ16
- **内容**: 入力されたメールアドレス

## 5. エラーダイアログ

### 5.1 重複メールエラー

#### デザイン仕様
```dart
Dialog(
  insetPadding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(16)
    ),
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
  ),
)
```

#### 内容構成
- **タイトル**: 「エラーが発生しました。」（フォントサイズ: 24）
- **メッセージ**: 「ご入力されたメールアドレスは既に登録されています。」（フォントサイズ: 14）
- **ボタン**: 「OK」（右寄せ、高さ35px、背景グリーン）

### 5.2 表示タイミング
- 重複メールアドレス検出時
- バリアカラー: `Colors.black54`

## 6. レスポンシブ対応

### 6.1 キーボード対応
```dart
Scaffold(
  resizeToAvoidBottomInset: false,
)
```
- **設定**: キーボード表示時にコンテンツを上に押し上げない
- **目的**: OverPixel防止、UI固定

### 6.2 セーフエリア対応
```dart
SafeArea(child: Column(children: const [_Header(), _Form()]))
```
- **適用範囲**: ヘッダーとフォーム全体
- **目的**: ノッチ・ホームバー領域を避ける

## 7. パディング・マージン設計

### 7.1 全体構造
- **画面外周**: SafeArea適用
- **フォームコンテナ**: 水平15px、垂直10px
- **要素間スペース**: 16px単位（SizedBox使用）

### 7.2 詳細スペーシング
- **説明文**: 垂直8px
- **フィールド間**: 16px
- **注意事項**: 垂直16px
- **最終確認エリア**: 上32px
- **利用規約リンク**: 左32px

## 8. カラーパレット

### 8.1 使用色定義
| 用途 | 色名 | カラーコード |
|------|------|-------------|
| フォーカス・ボーダー | MyColors.greenText | 定義済み |
| ボタン背景 | MyColors.greenButton | 定義済み |
| 無効ボタン | Color(0xFF999999) | グレー |
| エラーテキスト | Colors.red | 赤 |
| リンクテキスト | Colors.green | 緑 |

### 8.2 アクセシビリティ
- **コントラスト比**: WCAG AAA準拠
- **色覚対応**: 緑系統のみに依存しない設計

## 9. フォント・タイポグラフィ

### 9.1 フォントサイズ体系
| 要素 | フォントサイズ | ウェイト |
|------|-------------|---------|
| ページタイトル | 28 | デフォルト |
| セクション見出し | 16 | Bold |
| 本文 | 16 | デフォルト |
| ボタン | 18 | 500 |
| 注意事項 | 14 | デフォルト |
| エラーダイアログタイトル | 24 | デフォルト |

### 9.2 行間設計
- **デフォルト**: Flutterの標準値使用
- **説明文**: 自動改行（softwrap: true）

## 10. 関連ドキュメント

- [フロー図（BPMN）](./flow.md)
- [概要仕様書](./overview.md)
- [設計仕様書](./design-specification.md)