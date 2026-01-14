# Claude Code Hooks 検証ガイド

## 概要

このドキュメントでは、Claude Code Hooksが正しく設定され、アクティブになっているかを確認する方法を説明します。

## Hooksとは

**Hooks**は、Claude Codeが特定のアクション（ツール使用など）の前後に自動的にコマンドを実行する機能です。

https://code.claude.com/docs/ja/hooks

### 本プロジェクトで使用しているHook

- **PostToolUse Hook**: `Edit`または`Write`ツール使用後に自動実行
- **目的**: Dartファイルの自動フォーマットとLint修正
- **実行内容**:
  - `dart format` - コードフォーマット
  - `dart fix --apply --code=always_use_package_imports` - パッケージimport修正
  - `dart fix --apply --code=directives_ordering` - import順序修正

## 設定ファイルの確認

### 1. Hook設定ファイルの存在確認

以下のファイルが存在することを確認してください：

```bash
# Hook設定
.claude/settings.json

# Hookスクリプト
.claude/hooks/dart-lint-format.sh
```

### 2. settings.jsonの確認

`.claude/settings.json`に以下の設定が含まれていることを確認：

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

### 方法1: Claude Code内で確認

Claude Codeセッション内で以下のコマンドを使用：

```
/hooks
```

このコマンドで登録されているHooksの一覧が表示されます。

### 方法2: 手動テスト

Hookスクリプトを手動で実行してテストします：

```bash
# テスト用JSONを作成してHookを実行
echo '{"tool_name":"Edit","tool_input":{"file_path":"lib/main.dart"},"tool_response":{"success":true}}' | bash .claude/hooks/dart-lint-format.sh
```

**期待される出力:**
```
✓ Formatted: lib/main.dart
✓ Fixed package imports: lib/main.dart
✓ Fixed directive ordering: lib/main.dart
```

### 方法3: 実際の編集でテスト

1. Claude Codeで任意のDartファイルを編集
2. 編集後、`ctrl+o`（詳細モード）を押してHook実行ログを確認
3. Hookが実行されていれば、以下のようなメッセージが表示されます：
   ```
   ✓ Formatted: <ファイルパス>
   ✓ Fixed package imports: <ファイルパス>
   ✓ Fixed directive ordering: <ファイルパス>
   ```

### 方法4: git diffで確認

1. 意図的にフォーマットが崩れたDartファイルを作成
2. Claude Codeでそのファイルを編集（小さな変更でOK）
3. `git diff`でフォーマットが自動修正されているか確認

```bash
# git diffで確認
git diff lib/path/to/edited_file.dart
```

自分の編集内容に加えて、フォーマット修正も含まれていれば、Hookは正常に動作しています。

## トラブルシューティング

### Hooksが実行されない場合

#### 1. Claude Codeの再起動

Hooks設定を変更した後は、Claude Codeを再起動してください：

```bash
# Claude Codeを終了して再起動
exit
claude
```

#### 2. 設定ファイルの確認

JSON構文エラーがないか確認：

```bash
# JSONが正しいか検証
python3 -m json.tool .claude/settings.json
```

エラーが表示される場合は、JSON構文を修正してください。

#### 3. スクリプトの実行権限確認

```bash
# 実行権限を確認
ls -la .claude/hooks/dart-lint-format.sh

# 実行権限がない場合
chmod +x .claude/hooks/dart-lint-format.sh
```

#### 4. スクリプトのパス確認

`$CLAUDE_PROJECT_DIR`環境変数が正しく設定されているか確認：

```bash
# Claude Code内で確認
echo $CLAUDE_PROJECT_DIR
```

プロジェクトルートのパスが表示されれば正常です。

#### 5. デバッグモードで実行

Claude Codeをデバッグモードで起動して詳細ログを確認：

```bash
claude --debug
```

このモードではHook実行の詳細情報が表示されます。

### Hookは実行されるが、フォーマットが適用されない場合

#### 1. dartコマンドの確認

```bash
# dartコマンドが使用可能か確認
which dart
dart --version
```

#### 2. スクリプト内のエラー確認

スクリプトを直接実行してエラーメッセージを確認：

```bash
bash -x .claude/hooks/dart-lint-format.sh <<< '{"tool_input":{"file_path":"lib/main.dart"}}'
```

`-x`オプションで各行の実行内容が表示されます。

#### 3. ファイルパスの確認

Hookに渡されるファイルパスが正しいか確認：

```bash
# テスト実行で確認
echo '{"tool_input":{"file_path":"存在しないファイル.dart"}}' | bash .claude/hooks/dart-lint-format.sh
```

存在しないファイルの場合は何も出力されず、exit code 0で終了するはずです。

## Hookの動作仕様

### 実行タイミング

- **トリガー**: `Edit`または`Write`ツールの使用後
- **条件**: ツールが正常に完了した場合のみ
- **対象**: `.dart`拡張子のファイルのみ

### 処理フロー

1. Claude Codeがファイルを編集（EditまたはWriteツール）
2. 編集が成功
3. **Hookが自動実行**
4. Hookがファイルパスを確認
5. `.dart`ファイルの場合:
   - `dart format`実行
   - `dart fix --apply --code=always_use_package_imports`実行
   - `dart fix --apply --code=directives_ordering`実行
6. 処理完了メッセージを出力
7. exit code 0で終了

### 実行時間

- **タイムアウト**: 30秒
- **通常の実行時間**: 数秒以内

### Hook入力データ

Hookは標準入力（stdin）からJSON形式でデータを受け取ります：

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

Hooksを使用しない場合、以下のコマンドで手動実行可能：

```bash
# スラッシュコマンド（Claude Code内）
/dart-lint-fix

# 手動実行（ターミナル）
dart fix --apply --code=always_use_package_imports
dart fix --apply --code=directives_ordering
dart format .
```

## まとめ

- Hooksは`.claude/settings.json`で設定
- PostToolUseフックは編集後に自動実行
- `/hooks`コマンドで登録状況を確認
- `ctrl+o`で実行ログを確認
- トラブル時はClaude Codeを再起動

Hooksにより、Dartファイルの編集時に自動的にフォーマットとLint修正が適用され、コード品質が保たれます。
