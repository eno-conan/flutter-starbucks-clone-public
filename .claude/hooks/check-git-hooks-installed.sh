#!/usr/bin/env bash
# SessionStart hook: 一次品質ゲート（.githooks/）が有効かを確認し、
# 未導入ならその事実だけを Claude のコンテキストに注入する。
#
# 設計意図: pre-commit / Linter で塞げることは Claude Hooks で再実装しない。
# この hook は「下層のゲートが有効か」を見張るだけの補助であり、
# lint/format の実行そのものは行わない。
set -uo pipefail

cat >/dev/null   # stdin の JSON は読み捨てる

HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || true)

if [ "$HOOKS_PATH" = ".githooks" ]; then
  exit 0
fi

MSG='【品質ゲート未導入】このリポジトリで core.hooksPath が .githooks に設定されていません。pre-commit（dart format / dart analyze / 秘密情報スキャン / ignore コメント検出）と commit-msg 規約チェックが動作しません。コミットを伴う作業を始める前に `bash scripts/install-git-hooks.sh` の実行をユーザーに提案してください。'

if command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$MSG"
fi
exit 0
