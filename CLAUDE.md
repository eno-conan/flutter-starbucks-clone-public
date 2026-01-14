# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📚 ドキュメント参照

### コアルール（自動読み込み）

以下のルールは**全てのセッションで自動的に読み込まれます**：

**Flutter開発**: `.claude/rules/flutter/`
- `implementation-guidelines.md` - Widget設計、状態管理、推奨パターン
- `anti-patterns.md` - 避けるべき実装パターン
- `riverpod-3-guidelines.md` - Riverpod 3.0ガイド

### スラッシュコマンド（必要時に呼び出し）

特定の作業時に必要なガイドラインは、スラッシュコマンドで呼び出せます：

**Flutter開発ガイド**:
- `/screens` - 画面・Widget実装ガイドライン
- `/services` - サービス層ガイドライン
- `/models` - データモデルガイドライン
- `/logging` - LoggerServiceログ出力ルール
- `/linting` - Lintルール解説

**Android開発**:
- `/android-security` - セキュリティガイドライン

**プロジェクト管理**:
- `/dev-setup` - 開発環境設定
- `/testing` - テスト実装ガイドライン

**メインドキュメント**: `/docs/README.md`

## 💡 重要原則

- **Riverpod 3.0**: 状態管理は必ず最新のNotifier APIを使用
- **LoggerService**: ログ出力は`LoggerService.info()`と`LoggerService.warn()`を中心に使用
- **アンチパターン回避**: 実装前にアンチパターンをチェック
- **参考情報**: 実装時に参照したサイトやGithub Issue/Repositoryがあれば開発者に伝える

## 🔧 スラッシュコマンド作成ガイド

スラッシュコマンドは、頻繁に使用するプロンプトをMarkdownファイルとして定義できる機能です。

### コマンドの配置場所

- **プロジェクトコマンド**: `.claude/commands/` - チーム全体で共有
- **個人コマンド**: `~/.claude/commands/` - 全プロジェクトで利用可能

### ファイル構造とフロントマター

```markdown
---
allowed-tools: Bash(git add:*), Bash(git status:*)
argument-hint: [message]
description: Create a git commit
model: claude-3-5-haiku-20241022
disable-model-invocation: false
---

## Context
- Current git status: !`git status`
- Current git diff: !`git diff HEAD`

## Your task
Create a git commit with message: $ARGUMENTS
```

### フロントマターフィールド

| フィールド | 用途 | デフォルト |
|-----------|------|----------|
| `allowed-tools` | コマンドが使用できるツールのリスト | 会話から継承 |
| `argument-hint` | 自動補完用の引数ヒント | なし |
| `description` | コマンドの簡潔な説明 | プロンプトの最初の行 |
| `model` | 使用するClaudeモデル | 会話から継承 |
| `disable-model-invocation` | `SlashCommand`ツールからの呼び出しを防止 | false |

### 引数の使用

**全引数を取得**: `$ARGUMENTS`
```markdown
Fix issue #$ARGUMENTS following our coding standards
```

**個別引数を取得**: `$1`, `$2`, `$3`...
```markdown
---
argument-hint: [pr-number] [priority] [assignee]
---
Review PR #$1 with priority $2 and assign to $3.
```

### 高度な機能

**Bashコマンド実行**: `!` プレフィックスを使用
```markdown
Current git status: !`git status`
Current branch: !`git branch --show-current`
```

**ファイル参照**: `@` プレフィックスを使用
```markdown
Review the implementation in @src/utils/helpers.js
```

### 名前空間

サブディレクトリを使用してコマンドを整理：
- `.claude/commands/frontend/component.md` → `/component` (表示: "project:frontend")
- `.claude/commands/backend/api.md` → `/api` (表示: "project:backend")

### 参考資料

詳細な情報は公式ドキュメントを参照：
- **公式ガイド**: https://code.claude.com/docs/en/slash-commands

## ✏️ Commit Message

Commit messageは修正内容が分かる形にすること。

#### 悪い例
> Merge pull request #329 from eno-conan/claude/issue-325-20251025-0140
#### 良い例
> docs: add Android security guidelines for AndroidManifest.xml improve…

## 📊 トークン使用量・コスト表示

Claude Code実行後には、以下の情報を必ず表示してください：

- **Input Tokens**: 入力トークン数
- **Output Tokens**: 出力トークン数  
- **Total Cost**: 合計コスト（USD）

例：
```
📊 Token Usage Summary:
• Input Tokens: 1,234
• Output Tokens: 567
• Total Cost: $0.0123 USD
```

## important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.