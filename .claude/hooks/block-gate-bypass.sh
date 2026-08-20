#!/usr/bin/env bash
# PreToolUse(Bash) hook: 一次品質ゲート（pre-commit / commit-msg）の迂回をブロックする。
#
# 設計意図: pre-commit は人間・Claude 双方に効くゲート。人間は緊急時に
# `git commit --no-verify` で暫定回避できるが、Claude が自己判断で迂回すると
# 「Claude だけがゲートを通っていない」状態になり、レビュー前提が崩れる。
# そのため Claude 側だけ機械的に塞ぐ。
set -u

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi

[ -z "$COMMAND" ] && exit 0

deny() {
  if command -v jq >/dev/null 2>&1; then
    REASON_JSON=$(printf '%s' "$1" | jq -Rs .)
  else
    REASON_JSON=$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "\"%s\\n\"", $0}' | tr -d '\n')
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}' "$REASON_JSON"
  exit 0
}

# git commit/push の --no-verify、git commit -n
if printf '%s' "$COMMAND" | grep -Eq 'git[[:space:]]+([a-z-]+[[:space:]]+)*(commit|push)([[:space:]]|$)'; then
  if printf '%s' "$COMMAND" | grep -Eq '(--no-verify|(^|[[:space:]])-n([[:space:]]|$))'; then
    deny 'git commit/push の --no-verify（一次品質ゲートの迂回）はブロックされました。pre-commit が落ちる場合は、迂回せずに指摘内容（dart format / dart analyze / 秘密情報 / ignore コメント / commit message 規約）を修正してください。どうしても迂回が必要な場合はユーザー自身に実行を依頼してください。'
  fi
fi

# hooksPath の無効化
if printf '%s' "$COMMAND" | grep -Eq 'git[[:space:]]+config[[:space:]]+.*core\.hooksPath'; then
  if printf '%s' "$COMMAND" | grep -Eq '(--unset|core\.hooksPath[[:space:]]+(""|.git/hooks))'; then
    deny 'core.hooksPath の無効化はブロックされました。一次品質ゲート（.githooks/）を外す変更はユーザーの判断で行ってください。'
  fi
fi

exit 0
