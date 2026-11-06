# Claude Code スラッシュコマンド ガイド

## 概要

- 本プロジェクトで使っている、Claude Code のスラッシュコマンドの説明。
- **スラッシュコマンド**は、頻繁に使うプロンプトを Markdown ファイルとして定義し、短いコマンドで呼び出せる機能。
    - コマンドは `/` で始まる（例: `/session-start`, `/fix-github-issue`）。
    - `.claude/commands/` ディレクトリに、Markdown ファイルとして置く。
    - 引数を渡せる（`$ARGUMENTS` で受け取る）。

## 本プロジェクトのコマンド一覧

| コマンド | 説明 | 引数 |
|---|---|---|
| `/session-start` | 新規セッション開始 | `[name]`（任意） |
| `/session-update` | セッション更新 | `[notes]`（任意） |
| `/session-end` | セッション終了 | なし |
| `/session-current` | 現在のセッション表示 | なし |
| `/session-list` | 全セッション一覧 | なし |
| `/session-help` | ヘルプ表示 | なし |
| `/fix-github-issue` | GitHub Issue 修正 | `[issue-number]`（必須） |
| `/dev-loop` | 実装 → 自動レビュー → 修正を、品質ゲート通過まで回す | `[作業内容]`（必須） |

!!! warning "`project:` プレフィックスは付けない"
    - 元のリポジトリ（claude-sessions）のドキュメントは、`/project:session-start` のように `project:` を付けて書いている。
    - **実際は、`project:` を取り除いた形**で使う。

    | 形式 | 例 | 結果 |
    |---|---|---|
    | ❌ 元のドキュメントの記載 | `/project:session-start refactor-auth` | 動作しない |
    | ✅ 実際の使い方 | `/session-start refactor-auth` | 動く |

    - 理由:
        - `.claude/commands/` 直下に置いたファイルは、名前空間なしで呼び出される。
        - サブディレクトリ（例: `.claude/commands/project/`）に置いた場合にだけ、プレフィックスが必要になる。

## 1. Session 管理システム

- 開発セッションを、追跡・ドキュメント化するためのコマンド群。
- 元リポジトリ: [iannuttall/claude-sessions](https://github.com/iannuttall/claude-sessions)

??? info "`/session-start [name]` — 新しい開発セッションを開始する"
    - 使用例:

        ```
        /session-start issue485-hooks
        /session-start refactor-auth
        /session-start
        ```

    - 実行内容:
        - `.claude/sessions/` に、`YYYY-MM-DD-HHMM-[name].md` を作る。
        - セッション名・開始時刻・目標・進捗セクションを含むテンプレートを生成する。
        - `.claude/sessions/.current-session` に、アクティブセッションを記録する。
    - 引数: `name`（任意）。セッション名。

??? info "`/session-update [notes]` — 進捗や発見を記録する"
    - 使用例:

        ```
        /session-update Hooks実装完了
        /session-update Google OAuth制限を追加
        /session-update Next.js 15 params Promise問題を修正
        ```

    - 実行内容:
        - 現在アクティブなセッションファイルに、新しいエントリを追加する。
        - タイムスタンプ付きで記録する。
    - 引数: `notes`（任意）。記録する内容。

??? info "`/session-end` — セッションを終了し、サマリーを作る"
    - 使用例: `/session-end`
    - 実行内容:
        - セッションの完了マークを追加する。
        - 作業のサマリーと学びを記録する。
        - `.claude/sessions/.current-session` をクリアする。

??? info "`/session-current` — アクティブなセッションの状態を表示する"
    - 使用例: `/session-current`
    - 表示内容:
        - セッション名とファイル名。
        - 開始からの経過時間。
        - 最近の更新内容。
        - 現在の目標 / タスク。

??? info "`/session-list` — すべてのセッションを一覧表示する"
    - 使用例: `/session-list`
    - 表示内容:
        - `.claude/sessions/` 内のすべてのセッションファイル。
        - ファイル名・タイトル・日時・概要。
        - 現在アクティブなセッションのハイライト。
        - 最新のセッションから順に表示。

??? info "`/session-help` — Session 管理システムのヘルプを表示する"
    - 使用例: `/session-help`
    - 表示内容:
        - 利用可能なコマンド一覧。
        - 各コマンドの説明。
        - ベストプラクティス。
        - 使用例のワークフロー。

## 2. GitHub Issue 修正コマンド

### `/fix-github-issue [issue-number]`

- 指定された GitHub Issue を分析して修正する。
- 引数: `issue-number`（必須）。修正する Issue 番号。
- 使用例: `/fix-github-issue 485`
- 実行内容:
    1. `gh issue view` で、Issue の詳細を取得する。
    2. 問題を理解する。
    3. 関連ファイルを、コードベースから検索する。
    4. 必要な変更を実装する。
    5. わかりやすいコミットメッセージを作る。
    6. プッシュして、PR を作る。
- 参考: [Claude Code Best Practices - Custom Slash Commands](https://www.anthropic.com/engineering/claude-code-best-practices)

## 3. Loop Engineering コマンド

### `/dev-loop [作業内容]`

- 実装 → 自動レビュー → 修正のサイクルを、品質ゲートを通過するまで回す。
- 定義は `.claude/skills/dev-loop/SKILL.md`（スキル形式。`.claude/commands/` と同じく `/名前` で起動できる）。
- 引数: `作業内容`（必須）。実施したい作業、または Issue 番号。
- 使用例:

    ```
    /dev-loop 注文確定 RPC の認可チェックを追加する
    /dev-loop Issue 485 の対応（スキーマ変更を含む場合）
    ```

!!! warning "critical ティア専用"
    - 対象: スキーマ・サービス層・RPC・認証・CI。
    - 画面修正など standard 以下は、通常作業で行う。
    - `dart format` / `dart analyze` / `flutter test` は、Stop hook（`.claude/hooks/stop-gate.sh`）が自動で検証する。

実行内容:

| フェーズ | 担当 | モデル |
|---|---|---|
| 0. 影響度判定 | `.claude/scripts/impact-classify.sh` | （スクリプト） |
| 1. 計画・設計 | `plan-architect` | Opus |
| 2. 実装 | `implementer` / `docs-scribe` | Sonnet / Haiku |
| 3. レビュー | `code-reviewer` + `qa-agent` + `security-agent` | Sonnet |
| 4. 判定・修正 | Orchestrator | — |

- 影響度ティア（critical / standard / trivial）は、パスルールで決定論的に決まる。
- FAIL なら、実装フェーズに戻る。最大ラウンド数（critical / standard = 3、trivial = 2）で強制 STOP。
- 同じ修正の繰り返し（オシレーション）を検知したら、即 STOP してユーザーに判断を仰ぐ。
- 関連ルール:
    - `.claude/rules/model-routing.md`（影響度とモデルの対応）
    - `.claude/rules/quality-gate-layers.md`（Linter / pre-commit / CI / Hooks の責務分離）

## セッション管理のベストプラクティス

| 場面 | 推奨すること |
|---|---|
| **開始のタイミング** | 新機能の実装開始、重要なリファクタリング、Issue の修正開始、複雑な問題のデバッグ |
| **定期的な更新**（`/session-update`） | 重要な変更をしたとき、問題を発見したとき、解決策を見つけたとき、学びや発見があったとき |
| **終了時のサマリー** | 実装内容の要約、遭遇した問題と解決方法、未解決の課題、次のステップ、学んだこと・気づき |
| **過去セッションの参照**（`/session-list`） | 同じような問題の解決策の確認、以前の学びの活用、重複作業の回避（類似の作業を始める前に見る） |

## 実際の使用例

??? example "例 1: Issue 修正のワークフロー"
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

??? example "例 2: 開発セッションの追跡"
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

??? example "例 3: 複数セッションの管理"
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

独自のスラッシュコマンドも作れる。

### 基本的な構造

`.claude/commands/` に、Markdown ファイルを作る。

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

| キー | 内容 |
|---|---|
| `allowed-tools` | 使用可能なツールのリスト |
| `description` | コマンドの説明（自動補完で表示） |
| `argument-hint` | 引数のヒント（自動補完用） |
| `model` | 使用する Claude モデル |
| `disable-model-invocation` | `SlashCommand` ツールからの呼び出しを防止 |

### Bash コマンドの実行（動的コンテキスト取得）

- `!` プレフィックスでシェルコマンドを実行し、その出力をコンテキストに埋め込める。
- コマンドは、スラッシュコマンドの実行時に評価され、出力がプロンプトに挿入される。

```markdown
## Context
- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
```

### 引数の使用

- `$ARGUMENTS`: すべての引数を取得する。
- `$1`, `$2`, `$3`: 個別の引数を取得する。

??? example "例: Issue 番号を受け取るコマンド"
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

サブディレクトリで、コマンドを整理できる。

```
.claude/commands/
├── session-start.md         → /session-start
├── frontend/
│   └── component.md         → /component (表示: "project:frontend")
└── backend/
    └── api.md               → /api (表示: "project:backend")
```

### 参考資料

- [Claude Code Slash Commands 公式ドキュメント](https://code.claude.com/docs/en/slash-commands)
- 本プロジェクトの `.claude/CLAUDE.md` の「スラッシュコマンド作成ガイド」セクション

## セッションファイルの構造

セッションファイル（`.claude/sessions/YYYY-MM-DD-HHMM-name.md`）の基本構造:

??? info "セッションファイルのテンプレート"
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

??? question "コマンドが認識されない（`Unknown slash command: /session-start`）"
    - 解決方法:
        1. ファイルが `.claude/commands/` に存在するか確認する。
        2. ファイル名が正しいか確認する（`session-start.md`）。
        3. Claude Code を再起動する。

??? question "引数が渡されない（コマンド内で `$ARGUMENTS` が空）"
    - 解決方法:
        1. 引数の前にスペースを入れる: `/session-start issue485`。
        2. 引数を引用符で囲む必要がある場合: `/session-start "fix auth bug"`。

??? question "セッションファイルが作成されない（`/session-start` を実行しても、ファイルができない）"
    - 解決方法:
        1. `.claude/sessions/` ディレクトリが存在するか確認する。
        2. 書き込み権限があるか確認する。
        3. ディスク容量を確認する。

    ```bash
    # ディレクトリ作成
    mkdir -p .claude/sessions

    # 権限確認
    ls -la .claude/sessions/
    ```

## まとめ

- スラッシュコマンドは、頻繁に使うタスクを効率化する。
- Session 管理システムで、開発作業を体系的に記録できる。
- `project:` プレフィックスは不要（直接 `/session-xxx` で使う）。
- 独自コマンドを作って、ワークフローをカスタマイズできる。
- 過去のセッションを参照して、知識を蓄積できる。

### 関連ドキュメント

- **Hooks 検証ガイド**: `docs/claude/hooks-verification-guide.md`
- **プロジェクト指示**: `.claude/CLAUDE.md`
- **元リポジトリ**: [iannuttall/claude-sessions](https://github.com/iannuttall/claude-sessions)
