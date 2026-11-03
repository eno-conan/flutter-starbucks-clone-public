# Claude Code Hooks 検証ガイド

## 概要

- Claude Code Hooks が、正しく設定され、アクティブになっているかを確認する方法を説明する。

## Hooksとは

- **Hooks** は、Claude Code が特定のアクション（ツール使用など）の前後に、自動でコマンドを実行する機能。
- 公式ドキュメント: <https://code.claude.com/docs/ja/hooks>

### 本プロジェクトで使用しているHook

- **PostToolUse Hook**: `Edit` または `Write` ツールの使用後に、自動実行する。
- **目的**: Dart ファイルの、自動フォーマットと Lint 修正。
- **実行内容**:
    - `dart format`: コードフォーマット。
    - `dart fix --apply --code=prefer_relative_imports`: `lib/` 内の import を、相対パスに統一する。
    - `dart fix --apply --code=directives_ordering`: import の順序を直す。

## 設定ファイルの確認

### 1. Hook設定ファイルの存在確認

- 次のファイルが存在することを確認する。

```bash
# Hook設定
.claude/settings.json

# Hookスクリプト
.claude/hooks/dart-lint-format.sh
```

### 2. settings.jsonの確認

- `.claude/settings.json` に、次の設定が含まれていることを確認する。

??? example "コード例（16 行）"
    ```json
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [
              {
                "type": "command",
                "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/dart-lint-format.sh",
                "timeout": 30
              }
            ]
          }
        ]
      }
    }
    ```

### 3. スクリプトの実行権限確認

```bash
# 実行権限があるか確認
ls -la .claude/hooks/dart-lint-format.sh

# 実行権限がない場合は付与
chmod +x .claude/hooks/dart-lint-format.sh
```

## Hooksがアクティブか確認する方法

| 方法 | やること | 向いている場面 |
|---|---|---|
| 1. `/hooks` | 登録済み Hooks の一覧を見る | まず登録状況を知りたい |
| 2. 手動テスト | Hook スクリプトにテスト JSON を渡す | スクリプト単体の動作確認 |
| 3. 実際の編集 | Dart ファイルを編集して、実行ログを見る | 本番に近い確認 |
| 4. `git diff` | フォーマットが自動修正されたかを見る | 結果で確認 |

### 方法1: Claude Code内で確認

- Claude Code のセッション内で、次のコマンドを使う。

```
/hooks
```

- 登録されている Hooks の一覧が表示される。

### 方法2: 手動テスト

- Hook スクリプトを、手動で実行してテストする。

```bash
# テスト用JSONを作成してHookを実行
echo '{"tool_name":"Edit","tool_input":{"file_path":"lib/main.dart"},"tool_response":{"success":true}}' | bash .claude/hooks/dart-lint-format.sh
```

??? success "期待される出力"
    ```
    ✓ Formatted: lib/main.dart
    ✓ Fixed relative imports: lib/main.dart
    ✓ Fixed directive ordering: lib/main.dart
    ```

### 方法3: 実際の編集でテスト

1. Claude Code で、任意の Dart ファイルを編集する。
2. 編集後、`ctrl+o`（詳細モード）を押して、Hook の実行ログを確認する。
3. Hook が実行されていれば、次のようなメッセージが表示される。

    ```
    ✓ Formatted: <ファイルパス>
    ✓ Fixed relative imports: <ファイルパス>
    ✓ Fixed directive ordering: <ファイルパス>
    ```

### 方法4: git diffで確認

1. 意図的に、フォーマットが崩れた Dart ファイルを作る。
2. Claude Code で、そのファイルを編集する（小さな変更でよい）。
3. `git diff` で、フォーマットが自動修正されているか確認する。

```bash
# git diffで確認
git diff lib/path/to/edited_file.dart
```

!!! success "判定"
    自分の編集内容に加えて、フォーマット修正も含まれていれば、Hook は正常に動作している。

## トラブルシューティング

### Hooksが実行されない場合

??? question "1. Claude Code を再起動する"
    - Hooks の設定を変更した後は、Claude Code を再起動する。

    ```bash
    # Claude Codeを終了して再起動
    exit
    claude
    ```

??? question "2. 設定ファイルの JSON 構文を確認する"
    - JSON 構文エラーがないか確認する。
    - エラーが表示される場合は、JSON 構文を修正する。

    ```bash
    # JSONが正しいか検証
    python3 -m json.tool .claude/settings.json
    ```

??? question "3. スクリプトの実行権限を確認する"
    ```bash
    # 実行権限を確認
    ls -la .claude/hooks/dart-lint-format.sh

    # 実行権限がない場合
    chmod +x .claude/hooks/dart-lint-format.sh
    ```

??? question "4. スクリプトのパスを確認する"
    - `$CLAUDE_PROJECT_DIR` 環境変数が、正しく設定されているか確認する。
    - プロジェクトルートのパスが表示されれば、正常。

    ```bash
    # Claude Code内で確認
    echo $CLAUDE_PROJECT_DIR
    ```

??? question "5. デバッグモードで実行する"
    - Claude Code をデバッグモードで起動して、詳細ログを確認する。
    - このモードでは、Hook 実行の詳細情報が表示される。

    ```bash
    claude --debug
    ```

### Hookは実行されるが、フォーマットが適用されない場合

??? question "1. dart コマンドを確認する"
    ```bash
    # dartコマンドが使用可能か確認
    which dart
    dart --version
    ```

??? question "2. スクリプト内のエラーを確認する"
    - スクリプトを直接実行して、エラーメッセージを確認する。
    - `-x` オプションで、各行の実行内容が表示される。

    ```bash
    bash -x .claude/hooks/dart-lint-format.sh <<< '{"tool_input":{"file_path":"lib/main.dart"}}'
    ```

??? question "3. ファイルパスを確認する"
    - Hook に渡されるファイルパスが、正しいか確認する。
    - 存在しないファイルの場合は、何も出力されず、exit code 0 で終了するはず。

    ```bash
    # テスト実行で確認
    echo '{"tool_input":{"file_path":"存在しないファイル.dart"}}' | bash .claude/hooks/dart-lint-format.sh
    ```

## Hookの動作仕様

### 実行タイミング

- **トリガー**: `Edit` または `Write` ツールの使用後。
- **条件**: ツールが正常に完了した場合のみ。
- **対象**: `.dart` 拡張子のファイルのみ。

### 処理フロー

1. Claude Code がファイルを編集する（`Edit` または `Write` ツール）。
2. 編集が成功する。
3. **Hook が自動実行される。**
4. Hook がファイルパスを確認する。
5. `.dart` ファイルの場合:
    - `dart format` を実行する。
    - `dart fix --apply --code=prefer_relative_imports` を実行する。
    - `dart fix --apply --code=directives_ordering` を実行する。
6. 処理完了メッセージを出力する。
7. exit code 0 で終了する。

### 実行時間

- **タイムアウト**: 30 秒。
- **通常の実行時間**: 数秒以内。

### Hook入力データ

- Hook は、標準入力（stdin）から JSON 形式でデータを受け取る。

```json
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.dart",
    "old_string": "...",
    "new_string": "..."
  },
  "tool_response": {
    "filePath": "/path/to/file.dart",
    "success": true
  }
}
```

## 参考情報

### 関連ファイル

- **Hook設定**: `.claude/settings.json`
- **Hookスクリプト**: `.claude/hooks/dart-lint-format.sh`
- **元のスラッシュコマンド**: `.claude/commands/dart-lint-fix.md`
- **Issue**: [#485 Claude Code Hooksの導入](https://github.com/your-repo/issues/485)

### 公式ドキュメント

- [Claude Code Hooks ドキュメント](https://code.claude.com/docs/ja/hooks)
- [Claude Code 2025 Features](https://medium.com/@joe.njenga/claude-code-2025-summary-from-launch-to-beast-timeline-features-full-breakdown-45e5f3d8d5ff)

### 手動実行コマンド（従来の方法）

- Hooks を使わない場合は、次のコマンドで手動実行できる。

```bash
# スラッシュコマンド（Claude Code内）
/dart-lint-fix

# 手動実行（ターミナル）
dart fix --apply --code=prefer_relative_imports
dart fix --apply --code=directives_ordering
dart format .
```

## まとめ

- Hooks は `.claude/settings.json` で設定する。
- PostToolUse フックは、編集後に自動実行される。
- `/hooks` コマンドで、登録状況を確認できる。
- `ctrl+o` で、実行ログを確認できる。
- トラブル時は、Claude Code を再起動する。

!!! tip "効果"
    Hooks により、Dart ファイルの編集時に、自動でフォーマットと Lint 修正が適用され、コード品質が保たれる。
