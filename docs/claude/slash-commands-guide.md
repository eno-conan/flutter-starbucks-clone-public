# Claude Code スラッシュコマンド ガイド

## 概要

このドキュメントでは、本プロジェクトで使用しているClaude Codeのスラッシュコマンドについて説明します。

## スラッシュコマンドとは

**スラッシュコマンド**は、頻繁に使用するプロンプトをMarkdownファイルとして定義し、短いコマンドで呼び出せる機能です。

- コマンドは `/` で始まる形式（例: `/session-start`, `/fix-github-issue`）
- `.claude/commands/` ディレクトリにMarkdownファイルとして配置
- 引数を渡すことも可能（`$ARGUMENTS` で受け取り）

## 本プロジェクトで使用しているコマンド

### 1. Session管理システム

開発セッションを追跡・ドキュメント化するためのコマンド群です。
**元リポジトリ**: [iannuttall/claude-sessions](https://github.com/iannuttall/claude-sessions)

#### `/session-start [name]`

新しい開発セッションを開始します。

**使用例:**
```
/session-start issue485-hooks
/session-start refactor-auth
/session-start
```

**実行内容:**
- `.claude/sessions/` に `YYYY-MM-DD-HHMM-[name].md` ファイルを作成
- セッション名、開始時刻、目標、進捗セクションを含むテンプレートを生成
- `.claude/sessions/.current-session` にアクティブセッションを記録

**引数:**
- `name` (オプション): セッション名（省略可能）

#### `/session-update [notes]`

現在のセッションに進捗や発見を記録します。

**使用例:**
```
/session-update Hooks実装完了
/session-update Google OAuth制限を追加
/session-update Next.js 15 params Promise問題を修正
```

**実行内容:**
- 現在アクティブなセッションファイルに新しいエントリを追加
- タイムスタンプ付きで記録

**引数:**
- `notes` (オプション): 記録する内容

#### `/session-end`

現在のセッションを終了し、包括的なサマリーを作成します。

**使用例:**
```
/session-end
```

**実行内容:**
- セッションの完了マークを追加
- 作業のサマリーと学びを記録
- `.claude/sessions/.current-session` をクリア

#### `/session-current`

現在アクティブなセッションのステータスを表示します。

**使用例:**
```
/session-current
```

**表示内容:**
- セッション名とファイル名
- 開始からの経過時間
- 最近の更新内容
- 現在の目標/タスク

#### `/session-list`

すべての開発セッションを一覧表示します。

**使用例:**
```
/session-list
```

**表示内容:**
- `.claude/sessions/` 内のすべてのセッションファイル
- ファイル名、タイトル、日時、概要
- 現在アクティブなセッションをハイライト表示
- 最新のセッションから順に表示

#### `/session-help`

Session管理システムのヘルプを表示します。

**使用例:**
```
/session-help
```

**表示内容:**
- 利用可能なコマンド一覧
- 各コマンドの説明
- ベストプラクティス
- 使用例ワークフロー

### 2. GitHub Issue修正コマンド

#### `/fix-github-issue [issue-number]`

指定されたGitHub Issueを分析して修正します。

**使用例:**
```
/fix-github-issue 485
/fix-github-issue 123
```

**実行内容:**
1. `gh issue view` でIssue詳細を取得
2. 問題を理解
3. 関連ファイルをコードベースから検索
4. 必要な変更を実装
5. わかりやすいコミットメッセージを作成
6. プッシュしてPRを作成

**引数:**
- `issue-number` (必須): 修正するIssue番号

**参考:**
- [Claude Code Best Practices - Custom Slash Commands](https://www.anthropic.com/engineering/claude-code-best-practices)

## ⚠️ 重要な注意点

### 名前空間プレフィックスについて

元のリポジトリ（claude-sessions）のドキュメントでは、コマンドに `project:` プレフィックスを付けた形式で記載されています：

```
❌ 元のドキュメント記載（動作しない）:
/project:session-start refactor-auth
/project:session-update notes
/project:session-end
```

しかし、**実際には `project:` プレフィックスを取り除いた形式**で使用します：

```
✅ 実際の使用方法:
/session-start refactor-auth
/session-update notes
/session-end
```

**理由:**
- `.claude/commands/` 直下に配置されたファイルは名前空間なしで呼び出される
- サブディレクトリ（例: `.claude/commands/project/`）に配置した場合のみプレフィックスが必要

## セッション管理のベストプラクティス

### 1. セッション開始のタイミング

以下のような場合にセッションを開始することを推奨します：

- 新しい機能の実装を開始するとき
- 重要なリファクタリングを行うとき
- Issueの修正作業を開始するとき
- 複雑な問題のデバッグを行うとき

### 2. 定期的な更新

作業中は定期的に `/session-update` で進捗を記録：

- 重要な変更を行ったとき
- 問題を発見したとき
- 解決策を見つけたとき
- 学びや発見があったとき

### 3. セッション終了時のサマリー

セッション終了時には以下を含めることを推奨：

- 実装した内容の要約
- 遭遇した問題と解決方法
- 未解決の課題
- 次のステップ
- 学んだこと・気づき

### 4. 過去セッションの参照

類似の作業を始める前に `/session-list` で過去のセッションを確認：

- 同じような問題の解決策を確認
- 以前の学びを活用
- 重複作業を避ける

## 実際の使用例

### 例1: Issue修正のワークフロー

```bash
# 1. セッション開始
/session-start issue485-hooks

# 2. Issue内容確認
/fix-github-issue 485

# 3. 作業中の更新
/session-update Hooks実装方法を調査完了
/session-update PostToolUse Hook作成完了
/session-update テスト実行成功

# 4. セッション終了
/session-end
```

### 例2: 開発セッションの追跡

```bash
# セッション開始
/session-start refactor-auth-system

# 進捗更新
/session-update 認証フロー図を作成
/session-update SupabaseからFirebaseへの移行計画を策定
/session-update 既存コードのリファクタリング完了

# 現在のステータス確認
/session-current

# セッション終了
/session-end
```

### 例3: 複数セッションの管理

```bash
# すべてのセッションを一覧表示
/session-list

# 新しいセッション開始
/session-start performance-optimization

# 作業...

# 現在のセッション確認
/session-current

# セッション終了
/session-end
```

## スラッシュコマンドの作成方法

独自のスラッシュコマンドを作成することも可能です。

### 基本的な構造

`.claude/commands/` にMarkdownファイルを作成：

```markdown
---
allowed-tools: Bash(dart:*), Bash(flutter:*)
description: コマンドの簡潔な説明
argument-hint: [argument-name]
---

## Context
- 必要なコンテキスト情報

## Your task
実行してほしいタスクの詳細説明

引数は $ARGUMENTS で参照可能
```

### フロントマター（オプション）

- `allowed-tools`: 使用可能なツールのリスト
- `description`: コマンドの説明（自動補完で表示）
- `argument-hint`: 引数のヒント（自動補完用）
- `model`: 使用するClaudeモデル
- `disable-model-invocation`: `SlashCommand`ツールからの呼び出しを防止

### 引数の使用

- `$ARGUMENTS`: すべての引数を取得
- `$1`, `$2`, `$3`: 個別の引数を取得

**例:**
```markdown
---
argument-hint: [issue-number]
---

Please fix GitHub issue #$ARGUMENTS by:
1. Analyzing the issue
2. Implementing the fix
3. Creating a PR
```

### 名前空間（サブディレクトリ）

サブディレクトリを使用してコマンドを整理可能：

```
.claude/commands/
├── session-start.md         → /session-start
├── frontend/
│   └── component.md         → /component (表示: "project:frontend")
└── backend/
    └── api.md               → /api (表示: "project:backend")
```

### 参考資料

詳細な情報は以下を参照：
- [Claude Code Slash Commands 公式ドキュメント](https://code.claude.com/docs/en/slash-commands)
- 本プロジェクトの `.claude/CLAUDE.md` の「スラッシュコマンド作成ガイド」セクション

## セッションファイルの構造

セッションファイル（`.claude/sessions/YYYY-MM-DD-HHMM-name.md`）の基本構造：

```markdown
# Development Session: session-name

**Started:** YYYY-MM-DD HH:MM

## Session Overview

セッションの概要説明

## Goals

- [ ] 目標1
- [ ] 目標2
- [x] 完了した目標3

## Progress

### YYYY-MM-DD HH:MM - セクションタイトル

進捗の詳細内容

### YYYY-MM-DD HH:MM - 次のセクション

次の進捗内容

---

## Notes

メモや気づき

## References

- 参考リンク1
- 参考リンク2
```

## トラブルシューティング

### コマンドが認識されない

**症状:**
```
Unknown slash command: /session-start
```

**解決方法:**
1. ファイルが `.claude/commands/` に存在するか確認
2. ファイル名が正しいか確認（`session-start.md`）
3. Claude Codeを再起動

### 引数が渡されない

**症状:**
引数を指定してもコマンド内で `$ARGUMENTS` が空

**解決方法:**
1. 引数の前にスペースを入れる: `/session-start issue485`
2. 引数を引用符で囲む必要がある場合: `/session-start "fix auth bug"`

### セッションファイルが作成されない

**症状:**
`/session-start` を実行してもファイルが作成されない

**解決方法:**
1. `.claude/sessions/` ディレクトリが存在するか確認
2. 書き込み権限があるか確認
3. ディスク容量を確認

```bash
# ディレクトリ作成
mkdir -p .claude/sessions

# 権限確認
ls -la .claude/sessions/
```

## まとめ

- スラッシュコマンドは頻繁に使用するタスクを効率化
- Session管理システムで開発作業を体系的に記録
- `project:` プレフィックスは不要（直接 `/session-xxx` で使用）
- 独自コマンドを作成してワークフローをカスタマイズ可能
- 過去のセッションを参照して知識を蓄積

### 本プロジェクトのコマンド一覧

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/session-start` | 新規セッション開始 | `[name]` (オプション) |
| `/session-update` | セッション更新 | `[notes]` (オプション) |
| `/session-end` | セッション終了 | なし |
| `/session-current` | 現在のセッション表示 | なし |
| `/session-list` | 全セッション一覧 | なし |
| `/session-help` | ヘルプ表示 | なし |
| `/fix-github-issue` | GitHub Issue修正 | `[issue-number]` (必須) |

### 関連ドキュメント

- **Hooks検証ガイド**: `docs/claude/hooks-verification-guide.md`
- **プロジェクト指示**: `.claude/CLAUDE.md`
- **元リポジトリ**: [iannuttall/claude-sessions](https://github.com/iannuttall/claude-sessions)
