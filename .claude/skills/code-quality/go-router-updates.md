# go_router バージョンアップガイド

このドキュメントは、go_routerのバージョンアップ時に発生する警告への対処法と、安全な移行手順を説明します。

## 📋 バージョンアップの準備

### Step 1: CHANGELOGの確認

```bash
# オンラインでCHANGELOGを確認
# https://pub.dev/packages/go_router/changelog

# または、ローカルのpubspec.lockから現在のバージョンを確認
grep "go_router:" pubspec.lock -A 2
```

**確認ポイント:**
1. **BREAKING CHANGES**: 破壊的変更があるか
2. **Deprecated**: 非推奨になったAPIはあるか
3. **New Features**: 新機能の追加があるか

### Step 2: 破壊的変更の検索

```bash
# CHANGELOGから破壊的変更を検索
curl -s https://pub.dev/packages/go_router/changelog | grep -i "breaking"

# または、手動でCHANGELOGを確認
# 例: 16.x → 17.x の変更点をチェック
```

## 🔄 よくある移行パターン

### パターン1: avoid_redundant_argument_values警告

**原因**: go_routerのバージョンアップで、パラメータのデフォルト値が`null`に変更された

#### Before（警告が出る）
```dart
GoRoute(
  path: '/profile',
  parentNavigatorKey: null, // デフォルト値と同じなので警告
  builder: (context, state) => ProfileScreen(),
)
```

#### After（修正後）
```dart
GoRoute(
  path: '/profile',
  // parentNavigatorKeyは省略（デフォルトでnull）
  builder: (context, state) => ProfileScreen(),
)
```

### パターン2: 非推奨APIの置き換え

#### 例1: redirect のシグネチャ変更

**Before（16.x）**
```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    if (!isAdmin) return '/login';
    return null;
  },
  builder: (context, state) => AdminScreen(),
)
```

**After（17.x）** - 変更がない場合もありますが、CHANGELOGを確認

```dart
// シグネチャが変更されていないか確認
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    if (!isAdmin) return '/login';
    return null;
  },
  builder: (context, state) => AdminScreen(),
)
```

### パターン3: ShellRouteのオブザーバー通知

**Before（古いパターン）**
```dart
final router = GoRouter(
  observers: [MyNavigationObserver()], // 全体に適用
  routes: [
    ShellRoute(
      routes: [
        GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      ],
    ),
  ],
);
```

**After（推奨パターン）**
```dart
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

## ✅ バージョンアップ後のチェックリスト

### 1. Lint警告の確認

```bash
# 全体のLint警告を確認
flutter analyze

# go_router関連の警告のみ抽出
flutter analyze | grep -E "GoRoute|GoRouter|ShellRoute"
```

**よくある警告:**
- `avoid_redundant_argument_values`: デフォルト値の引数削除
- `deprecated_member_use`: 非推奨APIの置き換え
- `prefer_const_constructors`: constコンストラクターの使用

### 2. デフォルト値の引数削除

```bash
# 削除候補を検索
grep -r "parentNavigatorKey: null" lib/
grep -r "redirect: null" lib/
grep -r "pageBuilder: null" lib/
```

**削除する引数:**
- `parentNavigatorKey: null`
- `redirect: null`（デフォルトでnullの場合）
- その他、デフォルト値と同じ引数

### 3. ルーティングのテスト

- [ ] **基本的な画面遷移**: 各画面への遷移が正しく動作するか
- [ ] **Deep Link**: App Linksが正しく動作するか
- [ ] **リダイレクト**: 認証フローなどのリダイレクトが動作するか
- [ ] **戻るボタン**: 戻る操作が正しく動作するか
- [ ] **ShellRoute**: ネストされたナビゲーションが動作するか

### 4. 動作確認のテストコード例

```dart
testWidgets('GoRouter navigation test', (tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );

  // 初期画面が表示されることを確認
  expect(find.byType(HomeScreen), findsOneWidget);

  // プロフィール画面への遷移
  router.go('/profile');
  await tester.pumpAndSettle();

  // プロフィール画面が表示されることを確認
  expect(find.byType(ProfileScreen), findsOneWidget);
});
```

## 🚨 よくあるトラブルと対処法

### トラブル1: 大量のavoid_redundant_argument_values警告

**症状**: バージョンアップ後、多数の`avoid_redundant_argument_values`警告が発生

**原因**: go_routerのパラメータのデフォルト値が変更された

**対処法:**
1. 手動で各箇所を確認（自動置換は推奨しない）
2. 以下のパターンを検索して削除

```bash
# 削除候補を検索
grep -rn "parentNavigatorKey: null," lib/
grep -rn "redirect: null," lib/
```

3. 各箇所で以下を確認:
   - 本当にデフォルト値と同じか?
   - カスタムの値を指定している場合は削除しない

### トラブル2: redirectが動作しない

**症状**: 認証リダイレクトなどが正しく動作しない

**原因**: redirectのシグネチャが変更された可能性

**対処法:**
1. CHANGELOGでredirectの変更を確認
2. デバッグログを追加して動作確認

```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    LoggerService.debug('Redirect called: path=${state.uri}');
    if (!isAdmin) {
      LoggerService.debug('Redirecting to /login');
      return '/login';
    }
    return null;
  },
  builder: (context, state) => AdminScreen(),
)
```

### トラブル3: ShellRouteのナビゲーションが壊れた

**症状**: ShellRoute内のナビゲーションが正しく動作しない

**原因**: ShellRouteのAPI変更

**対処法:**
1. ShellRouteのドキュメントを確認
2. observers, navigatorKey, pageBuilderの使用方法を見直す

```dart
// 推奨パターン
ShellRoute(
  navigatorKey: _shellNavigatorKey,
  observers: [MyNavigationObserver()],
  builder: (context, state, child) {
    return ScaffoldWithNavBar(child: child);
  },
  routes: [
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
  ],
)
```

## 📝 移行手順のテンプレート

### Step-by-Step 移行手順

#### 1. 現在のバージョンを記録

```bash
grep "go_router:" pubspec.lock -A 2 > go_router_version_before.txt
```

#### 2. バックアップ作成

```bash
git checkout -b go_router_update_$(date +%Y%m%d)
git add .
git commit -m "chore: backup before go_router update"
```

#### 3. バージョンアップ実行

```bash
# pubspec.yamlのgo_routerバージョンを更新
# 例: go_router: ^16.0.0 → go_router: ^17.0.0

flutter pub upgrade go_router
```

#### 4. Lint警告の確認と修正

```bash
flutter analyze > analyze_output.txt
cat analyze_output.txt | grep -E "avoid_redundant_argument_values|deprecated_member_use"
```

#### 5. デフォルト値の引数削除

```bash
# 削除候補を確認
grep -r "parentNavigatorKey: null," lib/ | wc -l
grep -r "redirect: null," lib/ | wc -l
```

手動で各箇所を確認して削除

#### 6. テスト実行

```bash
flutter test
```

#### 7. 動作確認

- アプリケーションを起動
- 主要な画面遷移を確認
- Deep Linkをテスト（adbコマンド使用）
- リダイレクトをテスト

#### 8. コミット

```bash
git add .
git commit -m "chore: update go_router to v17.x and fix lint warnings"
```

## 🔗 参考リソース

- [go_router CHANGELOG](https://pub.dev/packages/go_router/changelog)
- [go_router Documentation](https://pub.dev/packages/go_router)
- [プロジェクト内ガイドライン](../../rules/flutter/code-quality-guidelines.md)

## 📊 移行の優先度

### 優先度: 最高
- [ ] Lint警告の修正（特に`deprecated_member_use`）
- [ ] 認証リダイレクトの動作確認
- [ ] Deep Linkの動作確認

### 優先度: 高
- [ ] `avoid_redundant_argument_values`の修正
- [ ] ShellRouteの動作確認
- [ ] テストの実行と修正

### 優先度: 中
- [ ] コードの最適化（型安全なルーティングの導入など）
- [ ] ドキュメントの更新

---

**このガイドに従うことで、go_routerのバージョンアップを安全かつ効率的に実施できます。**
