# コード品質管理ガイドライン

## 📋 概要

このドキュメントは、Flutter/Dartプロジェクトにおけるコード品質を維持するためのポリシーと、Lintエラーへの適切な対処法を定義します。特に`// ignore:`コメントの使用制御、`use_build_context_synchronously`への対処、go_routerバージョンアップ時の指針を提供します。

---

## 🚫 セクション1: ignoreコメント使用ポリシー

### 基本原則

**`// ignore:`コメントは原則として使用禁止です。**

Lintルールはコード品質を保つための重要なガイドラインです。警告を無視するのではなく、根本的な問題を修正することで、保守性と可読性の高いコードを維持します。

### 例外ケース（使用が許可される場合）

以下の**限定的なケース**でのみ、ignoreコメントの使用を許可します:

#### 1. 自動生成ファイル
```dart
// ✅ 許可: Mockitoなどのコード生成ツールによる自動生成ファイル
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import
```

#### 2. 外部ライブラリの型制約
```dart
// ✅ 許可: 外部ライブラリの制約でdynamic型を使わざるを得ない場合
Map<String, dynamic> json = jsonDecode(response.body);
// ignore: avoid_dynamic_calls
final value = json['nested']['deep']['value'];
```

ただし、可能な限り型安全なアクセス方法を優先してください（後述）。

#### 3. テストコードの特殊インポート
```dart
// ✅ 許可: テスト用の内部実装へのアクセス
// ignore: implementation_imports
import 'package:some_package/src/internal.dart';
```

### 禁止パターン

#### ❌ ファイル全体の警告抑制
```dart
// ❌ 禁止: ファイル全体でルールを無効化
// ignore_for_file: use_build_context_synchronously

class MyWidget extends StatelessWidget {
  // このファイル内の全てのuse_build_context_synchronously警告が無視される
}
```

**理由**: 個別の問題を適切に修正すべきです。

#### ❌ 一時的な対処としての使用
```dart
// ❌ 禁止: 後で修正するつもりでignoreを使用
Future<void> _onPressed() async {
  await someAsyncOperation();
  // ignore: use_build_context_synchronously // TODO: 後で修正
  Navigator.of(context).pop();
}
```

**理由**: TODOコメントは忘れられがちです。その場で正しく修正してください。

#### ❌ go_router更新時のデフォルト値警告の無視
```dart
// ❌ 禁止: go_routerのバージョンアップで出た警告をignoreで回避
GoRoute(
  path: '/home',
  // ignore: avoid_redundant_argument_values
  parentNavigatorKey: null, // デフォルト値と同じ
  builder: (context, state) => HomeScreen(),
)
```

**理由**: デフォルト値の引数は削除すべきです（後述）。

### ignoreコメントの発見と対処

#### 検索コマンド
```bash
# プロジェクト内の全ignoreコメントを検索
grep -r "// ignore" lib/ --exclude-dir=generated

# 特定のルールのignoreを検索
grep -r "ignore: use_build_context_synchronously" lib/
```

#### 対処フロー
1. **例外ケースに該当するか確認**
   - 自動生成、外部制約、テスト用？ → 許可
   - それ以外 → 修正が必要

2. **該当するLintルールの修正方法を確認**
   - このガイドラインのセクション2を参照
   - `.claude/rules/flutter/linting.md`を参照

3. **根本的な修正を実施**
   - ignoreコメントを削除
   - 適切なコードパターンで書き直し

4. **テストで動作確認**
   - 修正後も正しく動作することを確認

---

## 🔧 セクション2: Lintエラーへの正しい対処法

### 2.1 use_build_context_synchronously

#### 問題のあるパターン

```dart
// ❌ 問題: 非同期処理後に直接contextを使用
Future<void> _handleLogin() async {
  await authService.login(email, password);
  Navigator.of(context).pushReplacementNamed('/home'); // 警告が出る
}
```

**なぜ問題か?**
- 非同期処理中にWidgetがunmount（破棄）される可能性がある
- unmount後にcontextを使用すると、エラーや予期しない動作が発生する

#### 正しい対処法1: `context.mounted`チェック（推奨）

```dart
// ✅ 推奨: mountedをチェックしてから使用
Future<void> _handleLogin() async {
  await authService.login(email, password);

  if (!context.mounted) return; // Widgetがまだ存在するか確認

  Navigator.of(context).pushReplacementNamed('/home');
}
```

**使用場面**:
- 単一の非同期処理後にcontextを使用する場合
- シンプルな画面遷移やSnackBar表示

#### 正しい対処法2: 非同期処理前にNavigatorを取得

```dart
// ✅ 推奨: 非同期処理前にNavigatorを取得
Future<void> _handleLogin() async {
  final navigator = Navigator.of(context); // 先に取得

  await authService.login(email, password);

  navigator.pushReplacementNamed('/home'); // 取得済みのインスタンスを使用
}
```

**使用場面**:
- Navigatorのみを使用する場合
- mountedチェックが不要な場合（画面遷移が確実に実行される場合）

#### 正しい対処法3: go_routerでのmountedチェック

```dart
// ✅ 推奨: go_routerでもmountedチェック
Future<void> _handleLogin(BuildContext context) async {
  await authService.login(email, password);

  if (!context.mounted) return;

  context.go('/home');
}
```

**使用場面**:
- go_routerを使用している場合
- 複数のcontext依存操作がある場合

#### 実装時のチェックポイント

- [ ] `await`の後に必ず`context.mounted`チェックを入れたか？
- [ ] 複数の非同期処理がある場合、各`await`の後でチェックしているか？
- [ ] `ScaffoldMessenger`や`Theme`などの他のcontext依存操作も同様に保護されているか？

```dart
// ✅ 完全な実装例
Future<void> _handleSubmit() async {
  try {
    // 1. 非同期処理
    await apiService.submitData(data);

    // 2. mountedチェック
    if (!context.mounted) return;

    // 3. context依存の操作（全て保護されている）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('送信が完了しました')),
    );
    context.go('/success');

  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('エラー: $error')),
    );
  }
}
```

### 2.2 avoid_redundant_argument_values

#### 問題: デフォルト値と同じ引数の明示

```dart
// ❌ 問題: デフォルト値と同じ値を明示的に指定
GoRoute(
  path: '/profile',
  parentNavigatorKey: null, // デフォルト値がnullなのに明示
  builder: (context, state) => ProfileScreen(),
)

Container(
  alignment: Alignment.center,
  clipBehavior: Clip.none, // デフォルト値がClip.noneなのに明示
  child: Text('Hello'),
)
```

#### 対処法: デフォルト値の引数を削除

```dart
// ✅ 正しい: デフォルト値の引数は省略
GoRoute(
  path: '/profile',
  // parentNavigatorKeyは省略（デフォルトでnull）
  builder: (context, state) => ProfileScreen(),
)

Container(
  alignment: Alignment.center,
  // clipBehaviorは省略（デフォルトでClip.none）
  child: Text('Hello'),
)
```

#### go_router更新時の注意事項

**go_routerのバージョンアップでこの警告が大量に発生する理由:**

1. **デフォルト値の変更**: パラメータのデフォルト値が`null`に変更された
2. **既存コードでの明示**: 以前は必須だったパラメータが、デフォルト値を持つオプショナルパラメータになった

**対応手順:**
1. 警告が出ているパラメータを特定
2. そのパラメータのデフォルト値を確認（APIドキュメントまたはソースコード）
3. 指定している値がデフォルト値と同じなら削除
4. 異なる値を指定している場合は残す

#### デフォルト値の確認方法

```dart
// ライブラリのソースコードを確認（例: GoRoute）
class GoRoute {
  GoRoute({
    required this.path,
    this.name,
    this.builder,
    this.parentNavigatorKey, // ← デフォルト値なし = null
    this.redirect,
  });
}

// デフォルト値がある場合の例
class Container {
  Container({
    this.alignment,
    this.padding,
    this.clipBehavior = Clip.none, // ← デフォルト値: Clip.none
    this.child,
  });
}
```

**確認方法:**
1. コード内でクラス名を右クリック → "Go to Definition"
2. コンストラクターのパラメータ定義を確認
3. `= 値`があればそれがデフォルト値、なければ`null`

### 2.3 avoid_dynamic_calls

#### 妥当な使用例: JSONパース

```dart
// ✅ 許容: 深くネストされたJSONの一時的な扱い
Map<String, dynamic> json = jsonDecode(response.body);
// ignore: avoid_dynamic_calls
final deepValue = json['data']['user']['profile']['name'];
```

**理由**: 外部APIのJSONレスポンスは型が不定なため、一時的に`dynamic`を扱う必要があります。

#### より良い対処法: 型安全なアクセス

```dart
// ✅ 推奨: モデルクラスで型安全に扱う
class UserResponse {
  UserResponse({required this.data});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      data: UserData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  final UserData data;
}

class UserData {
  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final User user;
}

// 使用時
final response = UserResponse.fromJson(jsonDecode(responseBody));
final name = response.data.user.profile.name; // 型安全
```

**利点:**
- コンパイル時に型チェック
- IDEの補完が効く
- リファクタリングが安全

**原則**: JSON解析で一時的に`ignore: avoid_dynamic_calls`を使うことは許容されますが、可能な限りモデルクラスで型安全に扱ってください。

---

## 🛤️ セクション3: go_router特有のガイドライン

### 3.1 バージョンアップ時の対応指針

#### 更新前の準備

```bash
# 1. CHANGELOGを確認
# https://pub.dev/packages/go_router/changelog

# 2. 破壊的変更（BREAKING CHANGES）を検索
grep -i "breaking" CHANGELOG.md

# 3. 非推奨（Deprecated）APIを検索
grep -i "deprecated" CHANGELOG.md
```

#### 更新後のチェックリスト

- [ ] **Lintエラーの確認**: `flutter analyze`で新しい警告を確認
- [ ] **avoid_redundant_argument_values**: デフォルト値の引数を削除
- [ ] **deprecated_member_use**: 非推奨APIを新しいAPIに置き換え
- [ ] **ルーティングのテスト**: 各画面への遷移が正しく動作するか確認
- [ ] **Deep Linkのテスト**: App Linksが正しく動作するか確認
- [ ] **リダイレクトのテスト**: 認証フローなどのリダイレクトが動作するか確認

#### 実装例: go_router 16.x → 17.x の移行

**変更前（16.x）:**
```dart
GoRoute(
  path: '/profile',
  parentNavigatorKey: null, // 明示的にnullを指定していた
  builder: (context, state) => ProfileScreen(),
)
```

**変更後（17.x）:**
```dart
GoRoute(
  path: '/profile',
  // parentNavigatorKeyはデフォルトでnullなので省略
  builder: (context, state) => ProfileScreen(),
)
```

### 3.2 非推奨APIの置き換え方針

#### GoRouteDataの使用（推奨パターン）

```dart
// ✅ 推奨: GoRouteDataを使用した型安全なルーティング
class ProfileRoute extends GoRouteData {
  const ProfileRoute({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProfileScreen(userId: userId);
  }
}

// ルート定義
TypedGoRoute<ProfileRoute>(
  path: '/profile/:userId',
)
```

**利点:**
- 型安全なパラメータ受け渡し
- IDEの補完が効く
- リファクタリングが容易

#### ShellRouteのオブザーバー通知

```dart
// ✅ 推奨: ShellRouteでのナビゲーションオブザーバー
final router = GoRouter(
  routes: [
    ShellRoute(
      observers: [MyNavigationObserver()], // ShellRoute単位で指定
      routes: [
        GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      ],
    ),
  ],
);
```

### 3.3 パラメータのデフォルト値扱い

#### 必須パラメータとオプショナルパラメータ

```dart
// ✅ 明確な方針
GoRoute(
  path: '/details',
  // 必須: 必ず指定する（デフォルト値がない）
  builder: (context, state) => DetailsScreen(),

  // オプショナル: 必要な場合のみ指定（デフォルト値がある、またはnull）
  redirect: customRedirect, // デフォルト値と異なる場合のみ指定
  // parentNavigatorKey: 省略（nullがデフォルト）
)
```

#### コード例: 適切な使い分け

```dart
final router = GoRouter(
  routes: [
    // ケース1: 全てデフォルトのまま
    GoRoute(
      path: '/simple',
      builder: (context, state) => SimpleScreen(),
    ),

    // ケース2: 一部のパラメータをカスタマイズ
    GoRoute(
      path: '/custom',
      builder: (context, state) => CustomScreen(),
      redirect: (context, state) {
        // カスタムリダイレクトロジック
        return isLoggedIn ? null : '/login';
      },
      // parentNavigatorKeyは省略（デフォルトのnull）
    ),

    // ケース3: ShellRouteで複数画面を共通レイアウトに配置
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
        GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
      ],
    ),
  ],
);
```

---

## ✅ セクション4: コードレビューチェックリスト

### ignoreコメント使用のレビュー

レビュアーは以下を確認してください:

- [ ] **ignoreコメントが存在するか?**
  - 存在しない → OK
  - 存在する → 次のステップへ

- [ ] **例外ケースに該当するか?**
  - 自動生成ファイル → OK
  - 外部ライブラリの型制約（JSON等） → 可能なら型安全な方法を提案
  - テスト用の特殊インポート → OK
  - それ以外 → 却下（修正を依頼）

- [ ] **代替手段が存在するか?**
  - セクション2の対処法を参照
  - 具体的な修正方法をコメント

### use_build_context_synchronouslyのレビュー

- [ ] **非同期処理後にcontextを使用しているか?**
  - 使用していない → OK
  - 使用している → 次のステップへ

- [ ] **mountedチェックが実装されているか?**
  ```dart
  if (!context.mounted) return;
  ```

- [ ] **全ての非同期処理後でチェックされているか?**
  - 複数の`await`がある場合、各`await`の後でチェック

- [ ] **context依存の操作が全て保護されているか?**
  - `Navigator.of(context)`
  - `ScaffoldMessenger.of(context)`
  - `Theme.of(context)`
  - `MediaQuery.of(context)`
  - `context.go()` / `context.push()`

- [ ] **エラーハンドリング内でもmountedチェックされているか?**
  ```dart
  try {
    await operation();
    if (!context.mounted) return;
    // 成功処理
  } catch (error) {
    if (!context.mounted) return; // catch内でも必要
    // エラー処理
  }
  ```

### go_router使用のレビュー

- [ ] **デフォルト値の引数が省略されているか?**
  - `parentNavigatorKey: null` → 削除
  - `redirect: null` → 削除

- [ ] **非推奨APIを使用していないか?**
  - `deprecated_member_use`警告が出ていないか確認
  - 新しいAPIへの置き換えを提案

- [ ] **型安全なルーティングを使用しているか?**（推奨）
  - `GoRouteData`の使用を検討
  - 文字列リテラルの代わりに定数やクラスを使用

---

## 🔗 セクション5: 既存ルールとの関連

このガイドラインは、以下の既存ルールと連携して機能します:

### implementation-guidelines.mdとの関連

- **Widget設計**: [implementation-guidelines.md](.claude/rules/flutter/implementation-guidelines.md)でWidget構造の推奨パターンを参照
- **状態管理**: 非同期処理はRiverpod 3.0のNotifier APIで実装（詳細は同ファイル参照）
- **相互補完**:
  - implementation-guidelines: 「こう書く」（推奨パターン）
  - code-quality-guidelines: 「なぜこう書くか」「警告への対処」

### anti-patterns.mdとの関連

- **避けるべきパターン**: [anti-patterns.md](.claude/rules/flutter/anti-patterns.md)で以下が定義済み
  - `// ignore:`コメントの濫用
  - `context.mounted`チェックなしの非同期処理後のcontext使用
- **相互補完**:
  - anti-patterns: 「こう書かない」（禁止パターン）
  - code-quality-guidelines: 「代わりにこう修正する」（対処法）

### linting.mdとの関連

- **Lintルール詳細**: [linting.md](.claude/rules/flutter/linting.md)で`analysis_options.yaml`の全ルールを解説
- **相互補完**:
  - linting: ルールの存在と基本的な例
  - code-quality-guidelines: 実践的な対処法とgo_router特有の対応

### 参照の優先順位

1. **警告が出た場合**: まず`code-quality-guidelines.md`（このファイル）で対処法を確認
2. **推奨パターンを知りたい場合**: `implementation-guidelines.md`を参照
3. **避けるべきパターンを確認したい場合**: `anti-patterns.md`を参照
4. **Lintルール全体を確認したい場合**: `linting.md`を参照

---

## ⚡ セクション6: 実装時のクイックリファレンス

### チェックフロー図

```
Lintエラーが発生
     ↓
┌─────────────────────────────────────┐
│ use_build_context_synchronously?    │
└─────────────────────────────────────┘
     ↓ YES
     ├→ context.mountedチェックを追加 (2.1参照)
     ↓ NO
┌─────────────────────────────────────┐
│ avoid_redundant_argument_values?    │
└─────────────────────────────────────┘
     ↓ YES
     ├→ デフォルト値の引数を削除 (2.2参照)
     ↓ NO
┌─────────────────────────────────────┐
│ avoid_dynamic_calls?                │
└─────────────────────────────────────┘
     ↓ YES
     ├→ モデルクラスで型安全に (2.3参照)
     ├→ または妥当な理由があればignore許可
     ↓ NO
┌─────────────────────────────────────┐
│ その他のLintエラー                   │
└─────────────────────────────────────┘
     ↓
     ├→ linting.mdで該当ルールを確認
     └→ 根本的な修正を実施
```

### よくある質問（FAQ）

#### Q1: 既存コードに大量の`use_build_context_synchronously`警告がある場合、どう対処すべきか？

**A**: 段階的に修正してください。

1. **優先度の高い画面から修正**（認証、決済など）
2. **パターン化されているコードは一括修正**
3. **新規実装では必ず遵守**

```bash
# 警告の数を確認
flutter analyze | grep use_build_context_synchronously | wc -l

# 影響範囲を特定
grep -r "await.*Navigator\|await.*context\." lib/ --include="*.dart"
```

#### Q2: go_routerのバージョンアップ後、`avoid_redundant_argument_values`が大量に出た。一括で修正できるか？

**A**: 手動での確認をおすすめしますが、以下のパターンは比較的安全に削除できます:

```bash
# 検索パターン（手動で各箇所を確認）
grep -n "parentNavigatorKey: null," lib/

# 削除候補
- parentNavigatorKey: null,  # デフォルトでnullなので削除可能
- redirect: null,            # デフォルトでnullなので削除可能
```

**注意**: 自動置換ツールは使わず、各箇所を目視で確認してから削除してください。

#### Q3: JSONパースで`avoid_dynamic_calls`警告が出るが、毎回モデルクラスを作るのは大変では？

**A**: 以下の判断基準で対応してください:

- **アプリ全体で使う重要なデータ** → モデルクラス作成（推奨）
  - ユーザー情報、商品情報、注文情報など

- **一時的なレスポンス、ログ送信用データ** → `ignore: avoid_dynamic_calls`で許容
  - デバッグ用のAPI、アナリティクス送信など

```dart
// ✅ 一時的なデータはignore許容
void sendAnalytics(Map<String, dynamic> event) {
  // ignore: avoid_dynamic_calls
  analytics.logEvent(event['name'], parameters: event['params']);
}
```

#### Q4: `// ignore_for_file:`を使っている既存ファイルをどう修正すべきか？

**A**: ファイル全体の警告抑制は推奨されません。以下のステップで段階的に修正してください:

1. **`// ignore_for_file:`を削除**
2. **`flutter analyze`で警告を確認**
3. **各警告を個別に修正**
4. **修正できない正当な理由がある場合のみ、行単位の`// ignore:`を使用**

```dart
// ❌ 修正前
// ignore_for_file: use_build_context_synchronously

class MyScreen extends StatelessWidget {
  // 複数の問題が隠蔽されている
}

// ✅ 修正後
class MyScreen extends StatelessWidget {
  Future<void> _onPressed() async {
    await operation();
    if (!context.mounted) return; // 個別に修正
    Navigator.pop(context);
  }
}
```

#### Q5: テストコードでもこれらのルールは適用すべきか？

**A**: 基本的には適用しますが、テスト特有の柔軟性も認めます:

- **`use_build_context_synchronously`**: テストでも`pumpAndSettle()`後は`mounted`不要な場合がある
- **`avoid_dynamic_calls`**: モックオブジェクトやテストデータでは`dynamic`を許容
- **`implementation_imports`**: テスト用の内部実装アクセスは許可

```dart
// ✅ テストでの許容例
testWidgets('画面遷移のテスト', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(); // mountedチェック不要

  expect(find.byType(NextScreen), findsOneWidget);
});
```

---

## 📚 参考資料

- **公式Lint Rules**: https://dart.dev/tools/linter-rules
- **Flutter Best Practices**: https://docs.flutter.dev/perf/best-practices
- **go_router Documentation**: https://pub.dev/packages/go_router
- **プロジェクト内ルール**:
  - [implementation-guidelines.md](.claude/rules/flutter/implementation-guidelines.md)
  - [anti-patterns.md](.claude/rules/flutter/anti-patterns.md)
  - [linting.md](.claude/rules/flutter/linting.md)

---

## 🎯 まとめ

### 重要ポイント

1. **`// ignore:`は原則禁止** → 根本的な修正を優先
2. **`use_build_context_synchronously`** → `context.mounted`チェック必須
3. **`avoid_redundant_argument_values`** → デフォルト値の引数は削除
4. **go_router更新時** → CHANGELOGを確認し、計画的に対応
5. **コードレビュー** → チェックリストを活用して品質を維持

### 実装時の心構え

- ⚠️ **警告は無視せず、理解して修正する**
- 🔍 **ドキュメントとソースコードを確認する習慣をつける**
- 🤝 **レビューで学び合い、チーム全体の品質を向上させる**
- 📈 **段階的な改善を継続し、技術的負債を減らしていく**

---

**このガイドラインを遵守することで、保守性が高く、長期的に維持しやすいFlutterアプリケーションを開発できます。**
