#!/usr/bin/env bash
# ============================================================================
# 影響度分類器（モデル制御のための決定論的ルーター）
#
# 変更対象パスから「影響度ティア」を判定し、使うべきモデルと必須レビュアーを出力する。
# 判定は LLM の裁量ではなくこのスクリプトのパスルールで決まる（＝再現性がある）。
#
#   使い方:
#     bash .claude/scripts/impact-classify.sh lib/screens/home.dart docs/foo.md
#     bash .claude/scripts/impact-classify.sh            # 引数なし = 現在の作業ツリー差分
#
#   出力: TIER / PLAN_MODEL / IMPL_MODEL / REVIEWERS / MAX_ROUNDS / REASON
#
# ポリシー詳細: .claude/rules/model-routing.md
# ============================================================================
set -uo pipefail

FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <( { git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u )
fi

if [ ${#FILES[@]} -eq 0 ]; then
  echo "TIER=unknown"
  echo "PLAN_MODEL=opus"
  echo "IMPL_MODEL=sonnet"
  echo "REVIEWERS=code-reviewer"
  echo "MAX_ROUNDS=3"
  echo "REASON=対象ファイルを特定できませんでした。作業対象パスを引数で渡してください。"
  exit 0
fi

TIER=trivial
declare -a CRITICAL_HITS=() STANDARD_HITS=() TRIVIAL_HITS=()

classify_one() {
  case "$1" in
    supabase_schema/*|*.sql|supabase/*) echo critical ;;
    android/*|ios/*|macos/*|windows/*|linux/*) echo critical ;;
    .github/workflows/*|.github/scripts/*) echo critical ;;
    pubspec.yaml|pubspec.lock|analysis_options.yaml|firebase.json|.firebaserc) echo critical ;;
    .claude/settings.json|.claude/hooks/*|.githooks/*|scripts/*) echo critical ;;
    lib/constants/supabase_rpcs.dart) echo critical ;;
    lib/services/*|lib/core/services/*) echo critical ;;
    lib/*|test/*|integration_test/*|test_driver/*|web/*) echo standard ;;
    .claude/agents/*|.claude/skills/*|.claude/rules/*|.claude/scripts/*) echo standard ;;
    docs/*|*.md|assets/*|public/*|*.png|*.jpg|*.svg) echo trivial ;;
    *) echo standard ;;
  esac
}

for f in "${FILES[@]}"; do
  [ -z "$f" ] && continue
  case "$(classify_one "$f")" in
    critical) CRITICAL_HITS+=("$f") ;;
    standard) STANDARD_HITS+=("$f") ;;
    trivial)  TRIVIAL_HITS+=("$f") ;;
  esac
done

if [ ${#CRITICAL_HITS[@]} -gt 0 ]; then
  TIER=critical
elif [ ${#STANDARD_HITS[@]} -gt 0 ]; then
  TIER=standard
fi

case "$TIER" in
  critical)
    PLAN_MODEL=opus
    IMPL_MODEL=sonnet
    REVIEWERS=code-reviewer,qa-agent,security-agent
    MAX_ROUNDS=3
    REASON="スキーマ/ネイティブ設定/CI/依存/サービス層など影響度の高い変更を含む: ${CRITICAL_HITS[*]}"
    ;;
  standard)
    PLAN_MODEL=opus
    IMPL_MODEL=sonnet
    REVIEWERS=code-reviewer,qa-agent
    MAX_ROUNDS=3
    REASON="アプリコード/テストの変更: ${STANDARD_HITS[*]}"
    ;;
  trivial)
    PLAN_MODEL=none
    IMPL_MODEL=haiku
    REVIEWERS=code-reviewer
    MAX_ROUNDS=2
    REASON="ドキュメント/アセットのみの定型変更: ${TRIVIAL_HITS[*]}"
    ;;
esac

echo "TIER=$TIER"
echo "PLAN_MODEL=$PLAN_MODEL"
echo "IMPL_MODEL=$IMPL_MODEL"
echo "REVIEWERS=$REVIEWERS"
echo "MAX_ROUNDS=$MAX_ROUNDS"
echo "REASON=$REASON"
