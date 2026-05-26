# コードレビュー前チェックリスト

このチェックリストは、プルリクエスト作成前・コードレビュー依頼前に実施する品質チェック項目です。

## ✅ 基本チェック

### Lint警告

- [ ] `flutter analyze`を実行し、警告がゼロであることを確認
- [ ] `// ignore:` コメントが存在しないことを確認（または例外ケースのみ）
- [ ] 自動生成ファイル以外で`ignore_for_file`を使用していない

### コードフォーマット

- [ ] `dart format lib/`を実行し、コードがフォーマットされている
- [ ] 1行は100文字以内（`page_width: 100`）
- [ ] ファイル末尾に改行がある（`eol_at_end_of_file`）

## 🔍 Riverpod 3.0チェック

### Provider実装

- [ ] `Notifier<T>` または `@riverpod` を使用している
- [ ] `StateNotifierProvider`/`StateProvider` を使用していない
- [ ] `flutter_riverpod/legacy.dart` をインポートしていない
- [ ] `build()` メソッドで初期値を返している
- [ ] 状態更新は専用メソッド経由で行っている
- [ ] `.state` への直接アクセスを外部に公開していない
- [ ] 非同期処理は `build()` 外で実行している

### Legacy API検出

```bash
# 以下のコマンドで検出がゼロであることを確認
grep -r "StateNotifierProvider" lib/
grep -r "StateProvider" lib/
grep -r "flutter_riverpod/legacy.dart" lib/
```

## 🛡️ 非同期処理とContext

### use_build_context_synchronouslyチェック

- [ ] 非同期処理後にcontextを使用する全箇所で`context.mounted`チェック
- [ ] 複数の`await`がある場合、各`await`の後でチェック
- [ ] `Navigator.of(context)` の使用箇所を確認
- [ ] `ScaffoldMessenger.of(context)` の使用箇所を確認
- [ ] `Theme.of(context)` の使用箇所を確認
- [ ] エラーハンドリング（catch節）内でもmountedチェック

### 検証コード例

```dart
// ✅ 正しい実装
Future<void> _handleSubmit() async {
  try {
    await operation();
    if (!context.mounted) return;
    // 成功処理
  } catch (error) {
    if (!context.mounted) return; // catch内でも必要
    // エラー処理
  }
}
```

## 📐 レスポンシブデザイン

### responsiveDimensionsProviderチェック

- [ ] `MediaQuery.sizeOf(context)`を直接使用していない
- [ ] `ref.watch(responsiveDimensionsProvider)`を使用している
- [ ] 固定値ではなく、Providerの計算値を使用している
- [ ] 親Widgetで一度取得し、子Widgetにプロップスで渡している
- [ ] デバイス判定は`dimensions.isNarrowDevice`を使用

### 検出コマンド

```bash
# MediaQuery直接使用の検出（ゼロであることを確認）
grep -r "MediaQuery.sizeOf(context)" lib/ --exclude-dir=provider
```

## 🎨 Widget設計

### 責任の分離

- [ ] 1つのWidgetが1つの責任のみを持つ
- [ ] 大きなWidgetは小さなWidgetに分割されている
- [ ] プライベートWidgetは`_`プレフィックス付きで命名
- [ ] 共通Widgetは`lib/shared/widgets/`に配置

### ConsumerWidget使用

- [ ] StatefulWidgetが必要ない場合、ConsumerWidgetを使用
- [ ] Providerアクセスは親で一度のみ（子では毎回アクセスしない）

## 🗂️ go_routerチェック（バージョンアップ後）

### デフォルト値の引数

- [ ] `parentNavigatorKey: null` が削除されている
- [ ] `redirect: null` が削除されている
- [ ] その他のデフォルト値引数が省略されている

### 非推奨API

- [ ] `deprecated_member_use` 警告が出ていない
- [ ] 最新のAPIを使用している

### 検証コマンド

```bash
# デフォルト値の不要な指定を検出
grep -r "parentNavigatorKey: null" lib/
grep -r "redirect: null" lib/
```

## 📝 ログ出力

### LoggerService使用

- [ ] `print()`や`debugPrint()`を使用していない
- [ ] `LoggerService.info()`と`LoggerService.warn()`を中心に使用
- [ ] 例外・エラー発生箇所（throw前）で`LoggerService.warn()`を使用
- [ ] パスワード、APIキーなどの機密情報をログに出力していない

### ログレベルの適切性

- [ ] 正常フローの重要ポイント → `info`
- [ ] 例外・エラー発生 → `warn`
- [ ] デバッグ用の詳細情報 → `debug`

## 🧪 テスト

### テストの実行

- [ ] `flutter test`を実行し、全テストがパスする
- [ ] 新規実装に対応するテストを追加している
- [ ] 変更箇所に関連するテストを更新している

### テストカバレッジ

- [ ] 主要な機能がテストされている
- [ ] エッジケース・エラーケースがテストされている

## 🔒 セキュリティ（Androidのみ）

### AndroidManifest.xml

- [ ] `android:allowBackup="false"` が設定されている
- [ ] `android:usesCleartextTraffic="false"` が設定されている
- [ ] ネットワークセキュリティ設定が適切に構成されている

### Deep Link

- [ ] Deep Linkでホスト・パス・パラメータの検証が実装されている
- [ ] 不正なパラメータの処理が適切に実装されている

## 📚 ドキュメント

### コメント

- [ ] 複雑なロジックには説明コメントがある
- [ ] パブリックAPI（クラス、メソッド）にドキュメントコメントがある
- [ ] TODOコメントは最小限（issue番号付き）

### README/CHANGELOG

- [ ] 大きな機能追加の場合、README更新を検討
- [ ] 破壊的変更の場合、CHANGELOGに記載

## 🎯 最終確認

### コードレビュー前

- [ ] 上記の全チェック項目を確認
- [ ] `flutter analyze`で警告ゼロ
- [ ] `flutter test`で全テストパス
- [ ] アプリケーションが正常動作することを確認

### プルリクエスト作成時

- [ ] 変更内容の説明が明確
- [ ] スクリーンショット（UI変更の場合）
- [ ] 関連するissue番号を記載

---

**このチェックリストを実施することで、高品質なコードを維持し、レビューの効率を向上できます。**
