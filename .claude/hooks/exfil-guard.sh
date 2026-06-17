#!/bin/bash
# Bash コマンドがデータ漏洩（認証情報の外部送信）を試みていないか検出してブロック
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 安全なコマンドはスキップ
PRIMARY_CMD=$(echo "$COMMAND" | sed 's/^[[:space:]]*//' | cut -d' ' -f1 | sed 's|.*/||')
case "$PRIMARY_CMD" in
  git|gh|docker|flutter|dart|npm|yarn|pip|python|python3|node|make)
    exit 0 ;;
esac

# ネットワーク系コマンドがなければ OK
if ! echo "$COMMAND" | grep -qiE '(curl|wget|nc[[:space:]]|netcat|ssh[[:space:]]|scp[[:space:]])'; then
  exit 0
fi

# ネットワーク + 認証情報パターン → deny
CRED_PATTERN='(\.env|token\.json|client_secret|api[_.]key|credential|\.pem|\.key)'
if echo "$COMMAND" | grep -qiE "$CRED_PATTERN"; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"🚫 ネットワーク送信と認証情報アクセスの組み合わせを検出。ブロックしました。"}}'
  exit 0
fi

# base64 + ネットワーク → deny（難読化による漏洩を検出）
if echo "$COMMAND" | grep -qiE 'base64' && echo "$COMMAND" | grep -qiE '(curl|wget|http)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"🚫 base64エンコードとネットワーク送信の組み合わせを検出。ブロックしました。"}}'
  exit 0
fi

exit 0
