# CLAUDE.md

## プロジェクト

**Starbucks Clone** (Flutter/Dart) | Riverpod 3.0 · go_router · Supabase · Google Maps | iOS・Android

## ルール（自動読み込み）

- `.claude/rules/flutter/implementation-guidelines.md`
- `.claude/rules/flutter/anti-patterns.md`
- `.claude/rules/flutter/riverpod-3-guidelines.md`
- `.claude/rules/flutter/code-quality-guidelines.md`
- `.claude/rules/repository-investigation.md`
- `.claude/rules/lsp-guidelines.md`

## スラッシュコマンド

`/session-start` `/session-update` `/session-end` `/session-current` `/session-list` `/session-help` `/fix-github-issue`

詳細: `docs/claude/slash-commands-guide.md`

## デフォルト判断基準

| 項目 | デフォルト |
|---|---|
| 状態管理 | Riverpod 3.0 Notifier API |
| ログ | `LoggerService.info()` / `LoggerService.warn()` |
| 画面 | `lib/screens/` |
| サービス | `lib/services/` または `lib/core/services/` |
| モデル | `lib/core/models/` または `lib/*/model(s)/` |
| 共通Widget | `lib/shared/widgets/` |
| ファイル名 | `snake_case.dart` |
| クラス名 | `PascalCase` |
| 変数・メソッド | `camelCase` |
| 環境変数 | `SCREAMING_SNAKE_CASE` |

上記から逸脱する場合のみユーザーに確認する。

## 重要ルール

- Riverpod 3.0 Notifier API 必須（StateNotifierProvider 禁止）
- 非同期処理後の `context` 使用前に `context.mounted` チェック必須
- サードパーティAPIは推測せず、ソースを読んで確認してから使う
- `// ignore:` は原則禁止（自動生成ファイルのみ許可）
- ログに機密情報（パスワード・APIキー）を出力しない
- 実装時に参照したサイト・Issue があれば開発者に伝える

## 詳細ドキュメント

| ドキュメント | 内容 |
|---|---|
| `docs/README.md` | プロジェクト全体概要 |
| `docs/claude/workflow.md` | Plan Mode・Subagent・自律修正・完了検証 |
| `docs/claude/quality-checklist.md` | API検証手順・品質チェック・Commit規約 |
| `docs/claude/slash-commands-guide.md` | スラッシュコマンド一覧・作成ガイド |

## important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
