#!/usr/bin/env bash
# .githooks/ をこのリポジトリの git hooks として有効化する。
# 人間・Claude 双方に等しく効く一次品質ゲート（pre-commit / commit-msg）を導入する。
#
#   使い方: bash scripts/install-git-hooks.sh
#   解除:   git config --unset core.hooksPath
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

chmod +x .githooks/* 2>/dev/null || true
git config core.hooksPath .githooks

echo "✅ core.hooksPath = $(git config core.hooksPath)"
echo "   有効な hook:"
for h in .githooks/*; do
  [ -f "$h" ] && echo "   - $(basename "$h")"
done
echo
echo "確認: git commit 時に dart format / dart analyze / 秘密情報スキャン / commit message 規約が実行されます。"
