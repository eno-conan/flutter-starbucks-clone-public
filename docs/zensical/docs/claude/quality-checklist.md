# 品質チェックリスト

## サードパーティAPI使用前の必須検証

**原則**: 推測や過去の記憶でAPIを使わない。必ず以下を実施すること。

1. **実際のパッケージソースを読む**
   - `.pub-cache/` 配下のソースファイルを `Read` ツールで確認
   - メソッドシグネチャ・戻り値の型・必須パラメータを正確に把握

2. **検証対象の例**
   - `go_router` のルーティングAPI (`onEnter`, `redirect` など)
   - `Riverpod` のプロバイダーAPI
   - `Supabase` のクライアントAPI
   - `Google Maps` の地図表示API

3. **検証方法**
   - `Read` ツールでパッケージのソースファイルを読む
   - 公式ドキュメントを確認（`WebFetch` ツール使用）
   - インストールされているバージョンと一致するAPIドキュメントを参照

## その他の品質チェック

- **mounted チェック**: 非同期処理後の `context` 使用時は必ず `context.mounted` で確認
- **冗長引数の削除**: `avoid_redundant_argument_values` 警告が出たらデフォルト値と同じ引数を削除
- **機密情報の保護**: パスワード・APIキー・個人情報をログに出力しない

## Commit Message ガイド

Commit message は修正内容が分かる形にすること。

**悪い例**
```
Merge pull request #329 from eno-conan/claude/issue-325-20251025-0140
```

**良い例**
```
docs: add Android security guidelines for AndroidManifest.xml
fix: store status incorrectly shown as closed during business hours
```

## トークン使用量・コスト表示

Claude Code 実行後には以下の情報を必ず表示してください：

```
📊 Token Usage Summary:
• Input Tokens: 1,234
• Output Tokens: 567
• Total Cost: $0.0123 USD
```
