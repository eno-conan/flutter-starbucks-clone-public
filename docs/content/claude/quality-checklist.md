# 品質チェックリスト

## サードパーティAPI使用前の必須検証

!!! warning "推測や過去の記憶で API を使わない"
    必ず、次の検証を実施する。

1. **実際のパッケージソースを読む**
    - `.pub-cache/` 配下のソースファイルを、`Read` ツールで確認する。
    - メソッドシグネチャ・戻り値の型・必須パラメータを、正確に把握する。

2. **検証対象の例**
    - `go_router` のルーティング API（`onEnter`, `redirect` など）
    - `Riverpod` のプロバイダー API
    - `Supabase` のクライアント API
    - `Google Maps` の地図表示 API

3. **検証方法**
    - `Read` ツールで、パッケージのソースファイルを読む。
    - 公式ドキュメントを確認する（`WebFetch` ツール使用）。
    - インストールされているバージョンと一致する、API ドキュメントを参照する。

## その他の品質チェック

- **mounted チェック**: 非同期処理後の `context` 使用時は、必ず `context.mounted` で確認する。
- **冗長引数の削除**: `avoid_redundant_argument_values` 警告が出たら、デフォルト値と同じ引数を削除する。
- **機密情報の保護**: パスワード・API キー・個人情報を、ログに出力しない。

## Commit Message ガイド

- Commit message は、修正内容が分かる形にする。
- 形式は、`.githooks/commit-msg` が機械的に検査する（`<type>: <説明>`）。

=== "❌ 悪い例"

    ```
    Merge pull request #329 from eno-conan/claude/issue-325-20251025-0140
    ```

=== "✅ 良い例"

    ```
    docs: add Android security guidelines for AndroidManifest.xml
    fix: store status incorrectly shown as closed during business hours
    ```

### 対話でメッセージを組み立てる

- 人が手でコミットを切るときは、規約を対話で満たす補助スクリプトを使える。

```bash
bash scripts/commit.sh
```

- 順に聞かれる項目: type の選択・scope・説明・本文・関連 Issue。
- 内容を確認してから、コミットする。
- ステージ済みの変更をそのままコミットするだけで、`git add` はしない。

!!! tip "hook は迂回しない"
    pre-commit / commit-msg で落ちた場合は、内容を直して再実行する。

## トークン使用量・コスト表示

!!! warning "Claude Code 実行後は、次の情報を必ず表示する"
    - 入力トークン数
    - 出力トークン数
    - 合計コスト

```
📊 Token Usage Summary:
• Input Tokens: 1,234
• Output Tokens: 567
• Total Cost: $0.0123 USD
```
