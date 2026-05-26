---
name: code-quality
description: |
  Flutter/Dartプロジェクトにおけるコード品質維持とLint警告の適切な対処法を提供。
  対応警告: use_build_context_synchronously, avoid_redundant_argument_values, avoid_dynamic_calls, inference_failure_on_function_invocation
  トリガーワード: lint, 警告, ignore, flutter analyze, go_router更新, コード品質, リファクタリング
  典型的なユーザー質問: "このLint警告を修正してください", "ignoreコメントを使っていいですか", "go_routerを更新したら警告が出ました"
  【対象外】: アプリケーションロジックの実装、UIデザイン、データベース設計
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Bash(flutter analyze)
license: MIT
compatibility: |
  - Flutter SDK 3.0+
  - Riverpod 2.0+
  - go_router 任意バージョン
metadata:
  author: flutter-starbucks-clone
  version: 1.0.0
  last-updated: 2025-02-11
argument-hint: [warning-type] [file-path]
---

# コード品質管理スキル

このスキルは、Flutter/Dartプロジェクトにおけるコード品質維持とLint警告の適切な対処法を提供します。

## 📋 使用場面

- Lint警告が発生した時
- コードレビュー前のチェック
- go_routerのバージョンアップ後
- `// ignore:` コメントの適切性確認

## 引数による実行

このスキルは引数をサポートしています。

**基本形式**: `/code-quality [warning-type] [file-path]`

**引数**:
- `$1` (warning-type): 対処したい警告の種類
  - `use_build_context_synchronously` - 非同期処理後のcontext使用警告
  - `avoid_redundant_argument_values` - デフォルト値引数警告
  - `avoid_dynamic_calls` - dynamic呼び出し警告
  - `inference_failure_on_function_invocation` - 型推論失敗警告
  - `all` - 全ての警告を対象
- `$2` (file-path): 対象ファイルパス（オプション）
  - 特定のファイルのみを対象とする場合に指定
  - 省略時はプロジェクト全体を対象

**実行例**:
```bash
# 特定の警告を特定のファイルで確認
/code-quality use_build_context_synchronously lib/screens/login.dart

# 特定の警告をプロジェクト全体で確認
/code-quality avoid_dynamic_calls

# 全ての警告を特定のディレクトリで確認
/code-quality all lib/screens/
```

### 実行フロー

引数が指定された場合:
1. 引数1（$ARGUMENTS または $1）から警告タイプを取得
2. 引数2（$2）が指定されていればファイルパスを取得
3. 該当する警告のみをスキャン
4. 対処法を提示

## 🚫 基本原則: ignoreコメント使用禁止

**現在のプロジェクト状態**: !`flutter analyze`

**警告数の確認**: !`flutter analyze | grep -c "warning"`

**ignoreコメント使用箇所**: !`grep -r "// ignore:" lib/ --exclude-dir=generated | wc -l`

**`// ignore:` コメントは原則として使用禁止です。**

### 例外ケース（許可）

1. **自動生成ファイル**: Mockito等のコード生成ツール
2. **外部ライブラリの型制約**: JSONパース等でやむを得ない場合
3. **テストコードの特殊インポート**: `implementation_imports`

### 禁止パターン

```dart
// ❌ ファイル全体の警告抑制
// ignore_for_file: use_build_context_synchronously

// ❌ 一時的な対処
// ignore: use_build_context_synchronously // TODO: 後で修正

// ❌ go_router警告の無視
// ignore: avoid_redundant_argument_values
parentNavigatorKey: null, // デフォルト値
```

## 🔧 よくあるLint警告と対処法

### 1. use_build_context_synchronously

**プロジェクト内の該当箇所数**: !`flutter analyze | grep use_build_context_synchronously | wc -l`

**具体的な箇所**: !`grep -r "Navigator.of(context)" lib/ | grep -B 3 "await"`

**問題**: 非同期処理後にcontextを使用すると警告

```dart
// ❌ 問題のあるコード
Future<void> _handleLogin() async {
  await authService.login(email, password);
  Navigator.of(context).pushReplacementNamed('/home'); // 警告
}
```

**✅ 解決策1: context.mountedチェック（推奨）**

```dart
Future<void> _handleLogin() async {
  await authService.login(email, password);

  if (!context.mounted) return; // チェック

  Navigator.of(context).pushReplacementNamed('/home');
}
```

**✅ 解決策2: 非同期処理前にNavigatorを取得**

```dart
Future<void> _handleLogin() async {
  final navigator = Navigator.of(context); // 先に取得

  await authService.login(email, password);

  navigator.pushReplacementNamed('/home');
}
```

**チェックポイント:**
- [ ] `await`の後に必ず`context.mounted`チェック
- [ ] 複数の`await`がある場合、各`await`の後でチェック
- [ ] `ScaffoldMessenger`や`Theme`などの他のcontext依存操作も保護

### 2. avoid_redundant_argument_values

**プロジェクト内の該当箇所数**: !`flutter analyze | grep avoid_redundant_argument_values | wc -l`

**go_routerバージョン**: !`grep "go_router:" pubspec.yaml`

**問題**: デフォルト値と同じ引数を明示的に指定

```dart
// ❌ 問題のあるコード
GoRoute(
  path: '/profile',
  parentNavigatorKey: null, // デフォルトがnullなのに明示
  builder: (context, state) => ProfileScreen(),
)
```

**✅ 解決策: デフォルト値の引数を削除**

```dart
GoRoute(
  path: '/profile',
  // parentNavigatorKeyは省略（デフォルトでnull）
  builder: (context, state) => ProfileScreen(),
)
```

**デフォルト値の確認方法:**
1. クラス名を右クリック → "Go to Definition"
2. コンストラクターのパラメータ定義を確認
3. `= 値`があればそれがデフォルト値、なければ`null`

### 3. avoid_dynamic_calls

**問題**: dynamicな値へのアクセス

```dart
// ❌ 問題のあるコード
Map<String, dynamic> json = jsonDecode(response.body);
final value = json['nested']['deep']['value']; // 警告
```

**✅ 解決策1: モデルクラスで型安全に（推奨）**

```dart
class UserResponse {
  UserResponse({required this.data});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      data: UserData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  final UserData data;
}

// 使用時
final response = UserResponse.fromJson(jsonDecode(responseBody));
final name = response.data.user.profile.name; // 型安全
```

**✅ 解決策2: 一時的な扱い（許容）**

```dart
// ✅ 許容: 深くネストされたJSONの一時的な扱い
Map<String, dynamic> json = jsonDecode(response.body);
// ignore: avoid_dynamic_calls
final deepValue = json['data']['user']['profile']['name'];
```

**原則**: 一時的なignoreは許容されますが、可能な限りモデルクラスを使用

### 4. inference_failure_on_function_invocation (Supabase RPC)

**問題**: Supabase `.rpc()`メソッドの型引数が推論できない

**発生箇所**: `lib/data/repository/` 内のRPC呼び出し

**エラーメッセージ**: `The type argument(s) of the function 'rpc' can't be inferred`

#### ❌ 問題のあるコード

```dart
// Repository層でのRPC呼び出し
class UserRepository {
  Future<List<User>> getUsers() async {
    final response = await _supabase.rpc(
      Rpcs.getUserData,
      params: {'user_id': userId},
    );
    // ⚠️ 警告: 型引数が推論できない

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => User.fromJson(json)).toList();
  }
}
```

#### ✅ 解決策: 型引数を明示的に指定

```dart
class UserRepository {
  Future<List<User>> getUsers() async {
    // 型引数を明示的に指定
    final response = await _supabase.rpc<List<Map<String, dynamic>>>(
      Rpcs.getUserData,
      params: {'user_id': userId},
    );

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }
}
```

**さらに型安全にする場合**:

```dart
class UserRepository {
  Future<List<User>> getUsers() async {
    final response = await _supabase.rpc<List<Map<String, dynamic>>>(
      Rpcs.getUserData,
      params: {'user_id': userId},
    );

    // レスポンスを明示的にキャスト
    final List<Map<String, dynamic>> responseList =
        (response as List<dynamic>).cast<Map<String, dynamic>>();

    // 型安全なメソッドに渡す
    return _convertToUsers(responseList);
  }

  // メソッド引数の型を明示
  List<User> _convertToUsers(List<Map<String, dynamic>> dataList) {
    return dataList.map((dataMap) => User.fromJson(dataMap)).toList();
  }
}
```

**参考実装**: `lib/data/repository/cart.dart:29`

#### チェックポイント:
- [ ] 全ての`.rpc()`呼び出しに型引数`<List<Map<String, dynamic>>>`を指定
- [ ] レスポンスを適切な型にキャスト（`.cast<Map<String, dynamic>>()`）
- [ ] メソッド引数の型を`List<Map<String, dynamic>>`に明示
- [ ] `avoid_dynamic_calls`警告も同時に解消される

**関連警告**:
このパターンを適用すると、以下の関連警告も同時に解消されます:
- `avoid_dynamic_calls` - 動的呼び出しの回避
- `argument_type_not_assignable` - 型代入エラーの解消

**詳細**: `.claude/rules/flutter/services.md` の「Repository層の型安全性パターン」セクション

## 🛤️ go_router バージョンアップ対応

### 更新前の準備

```bash
# CHANGELOGを確認
# https://pub.dev/packages/go_router/changelog

# 破壊的変更を検索
grep -i "breaking" CHANGELOG.md

# 非推奨APIを検索
grep -i "deprecated" CHANGELOG.md
```

### 更新後のチェックリスト

- [ ] `flutter analyze`で新しい警告を確認
- [ ] `avoid_redundant_argument_values`: デフォルト値の引数を削除
- [ ] `deprecated_member_use`: 非推奨APIを新しいAPIに置き換え
- [ ] ルーティングのテスト実行
- [ ] Deep Linkのテスト実行
- [ ] リダイレクトのテスト実行

## 📊 Lint警告の検出と修正フロー

### Step 1: 警告の検出

```bash
# 全体のLint警告を確認
flutter analyze

# 特定のルールの警告を検索
grep -r "ignore: use_build_context_synchronously" lib/
```

### Step 2: 対処法の選択

```
Lintエラーが発生
     ↓
┌─────────────────────────────────────┐
│ use_build_context_synchronously?    │
└─────────────────────────────────────┘
     ↓ YES
     ├→ context.mountedチェックを追加
     ↓ NO
┌─────────────────────────────────────┐
│ avoid_redundant_argument_values?    │
└─────────────────────────────────────┘
     ↓ YES
     ├→ デフォルト値の引数を削除
     ↓ NO
┌─────────────────────────────────────┐
│ avoid_dynamic_calls?                │
└─────────────────────────────────────┘
     ↓ YES
     ├→ モデルクラスで型安全に
     ├→ または妥当な理由があればignore許可
     ↓ NO
┌─────────────────────────────────────┐
│ その他のLintエラー                   │
└─────────────────────────────────────┘
     ↓
     ├→ linting.mdで該当ルールを確認
     └→ 根本的な修正を実施
```

### Step 3: 修正の実施

1. 該当箇所を特定
2. このスキルまたは詳細ガイドラインで対処法を確認
3. 修正を実施
4. `flutter analyze`で確認

### Step 4: テスト

- [ ] 修正後も正しく動作することを確認
- [ ] 関連する画面・機能をテスト

## ✅ コードレビューチェックリスト

### ignoreコメント使用のレビュー

- [ ] ignoreコメントが存在するか?
- [ ] 例外ケースに該当するか?
  - 自動生成ファイル → OK
  - 外部ライブラリの型制約 → 可能なら型安全な方法を提案
  - テスト用の特殊インポート → OK
  - それ以外 → 却下（修正を依頼）
- [ ] 代替手段が存在するか?

### use_build_context_synchronouslyのレビュー

- [ ] 非同期処理後にcontextを使用しているか?
- [ ] mountedチェックが実装されているか?
- [ ] 全ての非同期処理後でチェックされているか?
- [ ] context依存の操作が全て保護されているか?
- [ ] エラーハンドリング内でもmountedチェックされているか?

### go_router使用のレビュー

- [ ] デフォルト値の引数が省略されているか?
- [ ] 非推奨APIを使用していないか?
- [ ] 型安全なルーティングを使用しているか?（推奨）

## 🔗 詳細ドキュメント

- [コード品質管理ガイドライン](../../rules/flutter/code-quality-guidelines.md) - 761行の詳細リファレンス
- [Lintルール解説](../../rules/flutter/linting.md)
- [チェックリスト](./checklist/pre-review-checklist.md)
- [go_router更新ガイド](./go-router-updates.md)

## 🚨 よくある質問

### Q1: 既存コードに大量の警告がある場合は?

**A**: 段階的に修正してください。

1. 優先度の高い画面から修正（認証、決済など）
2. パターン化されているコードは一括修正
3. 新規実装では必ず遵守

```bash
# 警告の数を確認
flutter analyze | grep use_build_context_synchronously | wc -l
```

### Q2: go_router更新後、大量の`avoid_redundant_argument_values`が出た

**A**: 手動での確認をおすすめしますが、以下のパターンは比較的安全に削除できます:

```bash
# 検索パターン（手動で各箇所を確認）
grep -n "parentNavigatorKey: null," lib/
```

**注意**: 自動置換ツールは使わず、各箇所を目視で確認

### Q3: JSONパースで毎回モデルクラスを作るのは大変では?

**A**: 以下の判断基準で対応:

- **重要なデータ** → モデルクラス作成（推奨）
  - ユーザー情報、商品情報、注文情報など
- **一時的なデータ** → `ignore: avoid_dynamic_calls`で許容
  - デバッグ用のAPI、アナリティクス送信など

---

**関連スキル:**
- `/riverpod-3` - Riverpod 3.0実装ガイド
- `/flutter-patterns` - Widget設計パターン
- `/responsive-design` - レスポンシブ実装
