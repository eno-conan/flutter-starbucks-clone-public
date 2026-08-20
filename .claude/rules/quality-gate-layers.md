# 品質ゲートの責務分離（Linter / pre-commit / CI / Claude Hooks）

## 原則

**機械的に決まることは、できるだけ下の層で塞ぐ。**
Claude Hooks は最後の層であり、下層で塞げることを再実装しない。

理由: 下層（Linter・pre-commit・CI）は**人間にも Claude にも等しく効く**。
Claude Hooks は Claude にしか効かないため、ここだけに置いたルールは
「人間が暫定で対応したとき」「別の人が直接コミットしたとき」に素通りする。

```
Linter (analysis_options.yaml)       … 書いた瞬間に分かること
        ↓ 塞げないもの
pre-commit / commit-msg (.githooks/) … コミット単位で機械判定できること
        ↓ 塞げないもの
CI (.github/workflows/)              … 全体ビルド・テスト・複数環境での検証
        ↓ 塞げないもの
Claude Hooks (.claude/settings.json) … Claude 固有の事故のみ
```

## 各層の担当

| 層 | 対象 | 具体例 | 効く相手 |
|---|---|---|---|
| **Linter** | 構文・スタイル・静的に決まる規約 | フォーマット、import 順、`use_build_context_synchronously`、冗長引数 | 人間 + Claude + CI |
| **pre-commit** | コミット単位で機械判定できること | `dart format` 未適用、`dart analyze` エラー、`.env` の混入、APIキー文字列、`// ignore:` の混入、docs nav 未同期 | 人間 + Claude |
| **commit-msg** | コミットメッセージ規約 | `<type>: <説明>` 形式の強制 | 人間 + Claude |
| **CI** | 全体・複数環境での検証 | `flutter test`、ビルド、docs 同期チェック、依存監査 | 全員（マージ前の最終防衛） |
| **Claude Hooks** | **Claude 固有の事故** | シェルプロファイル/認証情報の読み取り（コンテキスト汚染）、ゲート迂回、破壊的コマンド、設定ファイルの無断変更、編集直後の即時フィードバック | Claude のみ |

## 新しいチェックを足したくなったときの判断フロー

```
そのチェックは静的解析ルールで表現できるか？
  YES → analysis_options.yaml に lint ルールを追加（Claude Hooks には書かない）
  NO  ↓
コミット時点のファイル内容だけで判定できるか？
  YES → .githooks/pre-commit に追加
  NO  ↓
ビルド・テスト全体の実行が必要か？
  YES → .github/workflows/ に追加
  NO  ↓
「Claude が実行するツール呼び出し」に固有の問題か？
  YES → .claude/settings.json の hooks に追加
  NO  → ルール文書（.claude/rules/）に書いて Claude に守らせる
```

## 現在の Claude Hooks 一覧と、そこに置いてある理由

| Hook | イベント | 置いてある理由（下層で塞げない理由） |
|---|---|---|
| `block-shell-profile-read.sh` | PreToolUse(Bash / Read・Grep・Glob) | `~/.bashrc` 等の**読み取り**はコミットされないため pre-commit では検知できない。値が会話コンテキストに入った時点で流出する |
| `block-gate-bypass.sh` | PreToolUse(Bash) | pre-commit 自身は迂回オプションを止められない。人間には緊急回避を残しつつ Claude だけ塞ぐ |
| `credential-guard.sh` | PreToolUse(Read) | 同上（読み取り時点の問題） |
| `exfil-guard.sh` | PreToolUse(Bash) | 外部送信はコミットを経由しない |
| 破壊的 git コマンドのブロック | PreToolUse(Bash) | 履歴・作業ツリーの破壊はコミット前に起きる |
| `analysis_options.yaml` / `pubspec.yaml` の変更制御 | PreToolUse(Edit/Write) | 「Claude が勝手にルール自体を緩める」ことの防止。人間の変更は許可したい |
| `post-tool-use-lint.sh` | PostToolUse(Edit/Write) | **pre-commit の代替ではなく高速フィードバック**。編集直後に 1 ファイルだけ検査してループを短くする |
| `check-git-hooks-installed.sh` | SessionStart | 下層ゲートが有効かの監視（下層そのものは再実装しない） |

## 迂回ポリシー

- **人間**: 緊急時はコミット時の検証スキップオプションで回避してよい（暫定対応を止めないため）
- **Claude**: 検証スキップと `core.hooksPath` の無効化は `block-gate-bypass.sh` でブロックされる。
  pre-commit が落ちたら迂回せず内容を修正する。どうしても必要ならユーザーに実行を依頼する

## セットアップ

```bash
bash scripts/install-git-hooks.sh   # core.hooksPath=.githooks を設定
```

未設定のセッションでは SessionStart hook が警告をコンテキストに注入する。

## 既知の注意点

Bash 用の PreToolUse hook は**コマンド文字列**を正規表現で検査するため、
危険コマンドを「例として文章中に書いた」だけでブロックされることがある
（本ドキュメントの執筆時に実際に発生した）。
そのためコマンド位置（行頭 / `;` `&&` `|` の直後）に限定した正規表現を使い、
ドキュメント本文では危険コマンドの逐語表記を避けている。
