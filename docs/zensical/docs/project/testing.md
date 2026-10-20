# テスト

## テスト戦略

- **単体テスト** - ビジネスロジック、ユーティリティ関数
- **ウィジェットテスト** - UI コンポーネント
- **結合テスト** - 画面フロー、API連携
- **Golden テスト** - UI回帰テスト

### コード品質コマンド

```bash
# 静的解析
fvm flutter analyze

# フォーマット
fvm flutter format .

# テスト実行
fvm flutter test

# カバレッジ測定
fvm flutter test --coverage
```

---

https://codelabs.developers.google.com/codelabs/flutter-app-testing?hl=ja

上記リンクの内容にのっとり、以下テストの基本的な書き方を学習予定
- プロバイダの単体テスト
- ウィジェットのテスト
- 統合テスト
- パフォーマンステスト

## テスト実行
```sh
flutter test
flutter test test/x.dart
```

### 失敗の内容まで読みたいとき

`flutter test` の出力は ok/ng が分かる程度で「何が NG だったか」を追いにくい。
`scripts/run-tests.sh` は機械可読な JSON レポートを併産し、失敗の要点だけに
圧縮したダイジェスト（テスト名 / 位置 / Expected / Actual / スタック / 失敗分類）を出す。

```sh
bash scripts/run-tests.sh                    # 単体・Widget テスト
bash scripts/run-tests.sh integration_test/  # 統合テスト（要 実機/エミュレータ）
bash scripts/run-tests.sh test/provider      # 対象を絞る
```

| 出力 | 内容 |
|---|---|
| `build/reports/test.json` | `--file-reporter=json:` の生レポート |
| `build/reports/digest.md` | 失敗ダイジェスト（CI の artifact 用） |

詳細は [統合テストガイド](../flutter/integration-test-guide.md) の「失敗した理由を読み取る」を参照。

### CI での自動実行

`.github/workflows/test.yml` が main への push と Pull Request で自動実行される。
対象は**実機が要らない層（単体 / Widget）のみ**。統合テストは実機・エミュレータが必要なため含まない。

| ステップ | 内容 |
|---|---|
| Resolve and verify Flutter version | `pubspec.yaml` と fvm の pin が一致するか検証し、食い違えば失敗させる |
| Analyze | `dart analyze --no-fatal-warnings`（error のみで落とす） |
| Run tests | `bash scripts/run-tests.sh` |
| Publish digest to job summary | 失敗ダイジェストを実行ページに出力 |
| Upload test reports | `digest.md` / `test.json` を artifact 化（7日保持） |

**失敗ダイジェストは実行ページの Summary で直接読める。** ログをダウンロードしなくても
「何が NG だったか」と失敗の分類が分かる。

`dart analyze` は `integration_test/` も対象に含む。`flutter test` は `test/` しか実行しないため、
**統合テストのコードに対する構文・型チェックはこのステップが唯一の防衛線**になる。

なお配布用の `app.yml`（APK ビルド + Firebase App Distribution）は手動実行のままで、
このワークフローとは分離している。

## カバレッジ出力
- [参考記事](https://fredgrott.medium.com/lcov-on-windows-7c58dda07080)
```bash
flutter test --coverage
perl %GENHTML% -o coverage\html coverage\lcov.info
```

## IconやTextの複数検証
あるKeyで取得した要素でIconが3つあり、各内容を検証したい。
```dart
final navigationSection =
          find.byKey(ValueKey('top_page_navigation_section'));
expect(navigationSection, findsOneWidget);
// 各アイコンの検証
final iconsFinder = find.descendant(
  of: navigationSection,
  matching: find.byType(Icon),
);
expect(iconsFinder, findsNWidgets(3));
// 複数の要素について検証したい場合
final actualIcons = iconsFinder
    .evaluate()
    .map((element) => element.widget as Icon)
    .toList();
expect(actualIcons[0].icon, Icons.confirmation_number_outlined);
// 2つ目のアイコンの検証
expect(actualIcons[1].icon, Icons.mail);
expect(actualIcons[1].color, Colors.green);
// 3つ目のアイコンの検証
expect(actualIcons[2].icon, Icons.settings);
```

## Golden test
- [大変参考になった記事](https://zenn.dev/and_ai/articles/03e4bd6736a24b)
- [タグ付けによる実行時間短縮](https://codewithandrea.com/tips/unit-widget-test-tags-flutter/)

テスト実行コマンド
```bash
flutter test --update-goldens --tags=golden
```
