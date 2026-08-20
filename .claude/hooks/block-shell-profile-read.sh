#!/usr/bin/env bash
# PreToolUse hook: シェルプロファイル/dotfile(~/.bashrc 等)・認証情報ストア・
# シークレット環境変数の「値」への読み取りアクセスを機械的にブロックする。
#
# 背景: これらのファイルに ANTHROPIC_API_KEY 等の秘密情報が export されている
# ケースがあり（別リポジトリで実際に .bashrc 経由で API キーが会話コンテキストへ
# 流出した）、cat/grep/source/type 等どんなコマンドでも読めてしまうため、
# settings.json の Read deny ルール（ファイルパス単位）では Bash 経由を塞げない。
# そのため Bash コマンド文字列側でも機械的に塞ぐ。
#
# 対象ツール: Bash（.tool_input.command）/ Read・Edit（.file_path）/
#             Grep・Glob（.path, .pattern）
#
# 他の非ブロッキング hook と異なり、これはハードな安全弁のため
# SKIP_*_HOOK 系の慣習でスキップ可能にはしない。
set -u

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  HAYSTACK=$(printf '%s' "$INPUT" | jq -r '
    [ .tool_input.command // empty,
      .tool_input.file_path // empty,
      .tool_input.path // empty,
      .tool_input.pattern // empty,
      (.tool_input.file_paths // [] | join(" ")) ] | join(" ")' 2>/dev/null)
else
  # jq が無い環境でも安全側に倒す（他の hook のように fail-open しない）。
  HAYSTACK=$(printf '%s' "$INPUT" | grep -oE '"(command|file_path|path|pattern)"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/^"[a-z_]+"[[:space:]]*:[[:space:]]*"//; s/"$//' | tr '\n' ' ')
fi

[ -z "${HAYSTACK//[[:space:]]/}" ] && exit 0

deny() {
  REASON="$1"
  if command -v jq >/dev/null 2>&1; then
    REASON_JSON=$(printf '%s' "$REASON" | jq -Rs .)
  else
    REASON_JSON=$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "\"%s\\n\"", $0}' | tr -d '\n')
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}' "$REASON_JSON"
  exit 0
}

# --- 1. シェルプロファイル / dotfile ---------------------------------------
SHELL_PROFILE_RE='\.bashrc|\.bash_profile|\.bash_login|\.bash_logout|\.profile|\.zshrc|\.zprofile|\.zshenv|\.zlogin|/etc/profile|/etc/bash\.bashrc|/etc/zsh/zshenv|/etc/environment|config\.fish'
if printf '%s' "$HAYSTACK" | grep -Eqi "$SHELL_PROFILE_RE"; then
  deny 'シェルプロファイル/dotfile（.bashrc 等）へのアクセスを検出したためブロックしました。これらのファイルには API キー等の秘密情報が export されている場合があり、cat・grep 等どんなコマンドで読んでも値が会話コンテキストに流出するリスクがあります。内容の確認が必要な場合は、値そのものを出力しない確認方法（変数名の有無だけを grep -q で確認する等）を使うか、ユーザー自身に確認してもらってください。'
fi

# --- 2. 認証情報ストア -------------------------------------------------------
CREDENTIAL_STORE_RE='\.credentials\.json|\.netrc|\.git-credentials|\.aws/credentials|\.ssh/id_|\.npmrc|\.pypirc|\.docker/config\.json|\.gnupg'
if printf '%s' "$HAYSTACK" | grep -Eqi "$CREDENTIAL_STORE_RE"; then
  deny '認証情報ストア（~/.claude/.credentials.json・~/.netrc・~/.ssh/id_* 等）へのアクセスを検出したためブロックしました。値が会話コンテキストに流出するリスクがあるため、必要な場合はユーザー自身に確認してもらってください。'
fi

# --- 3. シークレット環境変数の「値」の出力 -----------------------------------
# 誤爆を避けるため「値が展開される形」に限定して判定する。
#   deny  : echo $ANTHROPIC_API_KEY / env | grep -i anthropic / printenv SUPABASE_KEY
#   allow : printf 'SUPABASE_KEY=xxx' > .env.sample（代入の記述。展開しない）
#   allow : flutter run --dart-define=KEY=$SUPABASE_ANON_KEY（値を表示しない）
SECRET_VAR_RE='ANTHROPIC_(API_KEY|AUTH_TOKEN)|CLAUDE_CODE_OAUTH_TOKEN|SUPABASE_[A-Z_]*KEY|SERVICE_ROLE_KEY|GOOGLE_MAPS_API_KEY|FIREBASE_[A-Z_]*KEY'
PRINT_CMD_RE='(^|[;|&(]|[[:space:]])(echo|printf|cat)([[:space:]]|$)'
ENV_DUMP_RE='(^|[;|&(]|[[:space:]])(printenv|env|set|declare|export)([[:space:]]|\||$)'

# 3a. シークレット変数を「展開」して表示するケース
if printf '%s' "$HAYSTACK" | grep -Eq "\\\$\{?($SECRET_VAR_RE)" \
  && printf '%s' "$HAYSTACK" | grep -Eq "$PRINT_CMD_RE"; then
  deny 'シークレット環境変数の値を出力するコマンドを検出したためブロックしました。値が会話コンテキストに流出するため、設定の有無だけを確認したい場合は `[ -n "${VAR:-}" ] && echo set` のように値を出力しない形にしてください。'
fi

# 3b. 環境変数ダンプから秘密情報を拾うケース
if printf '%s' "$HAYSTACK" | grep -Eq "$ENV_DUMP_RE" \
  && printf '%s' "$HAYSTACK" | grep -Eqi 'anthropic|_api_key|api_key|secret|_token|credential'; then
  deny '環境変数ダンプから秘密情報を抽出するコマンドを検出したためブロックしました。値が会話コンテキストに流出するため、設定の有無だけを確認したい場合は `[ -n "${VAR:-}" ] && echo set` のように値を出力しない形にしてください。'
fi

exit 0
