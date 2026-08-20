#!/usr/bin/env bash
# コミットメッセージを対話形式で組み立ててコミットする。
#
# 通常のコミットメッセージは Claude が書くが、人が手で切りたいときに
# .githooks/commit-msg と同じ規約（<type>(<scope>): <説明>）を
# 対話で満たせるようにするためのもの。
#
#   使い方: bash scripts/commit.sh
#
# ステージ済みの変更をそのままコミットする（git add はしない）。
# pre-commit / commit-msg hook は迂回しない。落ちたら内容を直して再実行する。
set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

# commit-msg hook と同じ type 一覧。増減させるときは両方を揃えること
TYPES=(feat fix docs style refactor perf test build ci chore revert)
TYPE_DESCS=(
  "新機能"
  "バグ修正"
  "ドキュメントのみ"
  "整形のみ（挙動を変えない）"
  "リファクタリング（挙動を変えない）"
  "パフォーマンス改善"
  "テストの追加・修正"
  "ビルド・依存関係"
  "CI 設定"
  "雑務（上記に当てはまらない）"
  "取り消し"
)

# commit-msg hook の検査と同じ正規表現
SUBJECT_RE='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'

abort() {
  echo "" >&2
  echo "❌ $1" >&2
  exit 1
}

# --- 前提チェック --------------------------------------------------------

if git diff --cached --quiet; then
  echo "ステージされた変更がありません。" >&2
  echo "" >&2
  git status --short >&2
  echo "" >&2
  abort "先に git add でコミット対象を選んでください。"
fi

if [ "$(git config core.hooksPath)" != ".githooks" ]; then
  echo "⚠️  core.hooksPath が .githooks になっていません。"
  echo "   pre-commit / commit-msg が動かない状態です。"
  echo "   導入: bash scripts/install-git-hooks.sh"
  echo ""
fi

# --- ステージ内容の提示 --------------------------------------------------

echo "── コミット対象 ──────────────────────────────"
git diff --cached --stat
echo ""

# --- 1. type -------------------------------------------------------------

echo "── type ──────────────────────────────────────"
for i in "${!TYPES[@]}"; do
  printf "  %2d) %-9s %s\n" "$((i + 1))" "${TYPES[$i]}" "${TYPE_DESCS[$i]}"
done
echo ""

TYPE=""
while [ -z "$TYPE" ]; do
  read -r -p "type を番号か名前で入力: " input || abort "中断しました。"
  input="$(printf '%s' "$input" | tr -d '[:space:]')"

  if printf '%s' "$input" | grep -qE '^[0-9]+$'; then
    idx=$((input - 1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#TYPES[@]}" ]; then
      TYPE="${TYPES[$idx]}"
    fi
  else
    for t in "${TYPES[@]}"; do
      [ "$input" = "$t" ] && TYPE="$t" && break
    done
  fi

  [ -z "$TYPE" ] && echo "  → 一覧にある番号か名前を入力してください。"
done

# --- 2. scope（省略可） ---------------------------------------------------

SCOPE=""
while :; do
  read -r -p "scope（省略可。例: db, hooks, script）: " SCOPE || abort "中断しました。"
  SCOPE="$(printf '%s' "$SCOPE" | tr -d '[:space:]')"
  [ -z "$SCOPE" ] && break
  printf '%s' "$SCOPE" | grep -qE '^[a-z0-9._/-]+$' && break
  echo "  → scope に使えるのは英小文字・数字・. _ / - だけです。"
  SCOPE=""
done

# --- 3. 説明（1行目） -----------------------------------------------------

SUBJECT=""
while :; do
  read -r -p "変更内容が分かる説明: " SUBJECT || abort "中断しました。"
  # 前後の空白を落とす
  SUBJECT="$(printf '%s' "$SUBJECT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  if [ -z "$SUBJECT" ]; then
    echo "  → 説明は必須です。"
    continue
  fi

  if [ -n "$SCOPE" ]; then
    FIRST_LINE="${TYPE}(${SCOPE}): ${SUBJECT}"
  else
    FIRST_LINE="${TYPE}: ${SUBJECT}"
  fi

  if ! printf '%s' "$FIRST_LINE" | grep -qE "$SUBJECT_RE"; then
    echo "  → 規約に合いません: $FIRST_LINE"
    continue
  fi

  if [ "${#FIRST_LINE}" -gt 72 ]; then
    echo "  ⚠️  1行目が ${#FIRST_LINE} 文字です（72文字以内を推奨）。詳細は本文へ。"
  fi
  break
done

# --- 4. 本文（省略可） ---------------------------------------------------

echo ""
echo "本文（省略可）。なぜその変更が必要かを書く。"
echo "入力を終えるには . だけの行を入力するか Ctrl+D。"
BODY=""
while IFS= read -r line; do
  [ "$line" = "." ] && break
  BODY="${BODY}${line}"$'\n'
done
# 末尾の空行を落とす
BODY="$(printf '%s' "$BODY" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"

# --- 5. 関連 Issue（省略可） ---------------------------------------------

echo ""
ISSUE_LINE=""
while :; do
  read -r -p "関連 Issue 番号（省略可。# は不要。複数はスペース区切り）: " issues || abort "中断しました。"
  issues="$(printf '%s' "$issues" | tr -d '#')"
  [ -z "$(printf '%s' "$issues" | tr -d '[:space:]')" ] && break

  if ! printf '%s' "$issues" | grep -qE '^[0-9]+([[:space:]]+[0-9]+)*$'; then
    echo "  → 数字とスペースだけで入力してください。"
    continue
  fi

  read -r -p "この Issue を閉じますか？ [y/N]: " close || abort "中断しました。"
  for n in $issues; do
    case "$close" in
      [yY]*) ISSUE_LINE="${ISSUE_LINE}Closes #${n}"$'\n' ;;
      *)     ISSUE_LINE="${ISSUE_LINE}Issue #${n}"$'\n' ;;
    esac
  done
  ISSUE_LINE="$(printf '%s' "$ISSUE_LINE" | sed -e 's/[[:space:]]*$//')"
  break
done

# --- 6. 組み立て・確認 ---------------------------------------------------

MSG_FILE="$(mktemp)"
trap 'rm -f "$MSG_FILE"' EXIT

{
  printf '%s\n' "$FIRST_LINE"
  if [ -n "$BODY" ]; then
    printf '\n%s\n' "$BODY"
  fi
  if [ -n "$ISSUE_LINE" ]; then
    printf '\n%s\n' "$ISSUE_LINE"
  fi
} > "$MSG_FILE"

echo ""
echo "── コミットメッセージ ────────────────────────"
cat "$MSG_FILE"
echo "──────────────────────────────────────────────"
echo ""

read -r -p "この内容でコミットしますか？ [y/N]: " ok || abort "中断しました。"
case "$ok" in
  [yY]*) ;;
  *) abort "コミットしていません。" ;;
esac

# --- 7. コミット（hook はそのまま走らせる） ------------------------------

echo ""
if git commit -F "$MSG_FILE"; then
  echo ""
  echo "✅ コミットしました: $(git log -1 --format='%h %s')"
else
  status=$?
  echo ""
  echo "❌ コミットが hook に止められました。" >&2
  echo "   迂回せず、指摘された内容を直してから再実行してください。" >&2
  exit "$status"
fi
