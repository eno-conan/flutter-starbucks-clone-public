#!/bin/bash
# Read ツールが認証情報ファイルを開こうとしたときユーザー確認を求める
# .env* は settings.json の deny で既にブロック済み → 追加パターンをカバー
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# token.json 系
if echo "$BASENAME" | grep -qiE '^token.*\.json$'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"⚠️ OAuthトークンファイルを読み取ろうとしています。"}}'
  exit 0
fi

# credentials / secret / key / pem 系
if echo "$BASENAME" | grep -qiE '(credential|secret|private[_.]key|\.pem$|\.key$|api[_.]key|client_secret)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"⚠️ 認証情報・秘密鍵ファイルを読み取ろうとしています。"}}'
  exit 0
fi

exit 0
