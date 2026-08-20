#!/bin/bash
# 認証情報ファイルを開こうとしたときユーザー確認を求める
#
# 検査対象:
#   - Read ツール : tool_input.file_path
#   - Bash ツール : tool_input.command のうち「読み取り系コマンド」の引数
#
# Bash も見るのは、cat / head / sed 経由の読み取りが Read の deny・本 Hook を
# 素通りしてしまうため。読み取った時点で会話コンテキストに値が載る＝流出なので、
# コミットを経由しない この層（Claude Hooks）で塞ぐ必要がある。
# → .claude/rules/quality-gate-layers.md
#
# .env* の Read は settings.json の deny で既にブロック済み。ここでは Bash 経由の
# 抜け道と、deny に列挙されていないファイル名パターンをカバーする。
set -euo pipefail

INPUT=$(cat)

# --- 判定パターン ---------------------------------------------------------

# 認証情報を示すファイル名の断片
CRED_NAME='service[-_]?account|serviceaccountkey|credential|secret|private[-_.]?key|api[-_.]?key|client[-_.]?secret|id_rsa|id_dsa|id_ecdsa|id_ed25519|git-credentials|\.netrc|\.npmrc|\.pypirc'

# 完全一致で秘匿とみなすファイル名
# key.properties は拡張子が .properties なので CRED_EXT では拾えない（Android署名鍵のパス・パスワードを含む）
CRED_FILE='^(key|secrets|signing|keystore|sentry)\.properties$'

# 鍵・証明書・キーストアの拡張子
CRED_EXT='\.(pem|key|p12|pfx|p8|jks|keystore|asc|gpg)$'

# .env / .env.local など
ENV_FILE='^\.env($|\.)'

# ソース・ドキュメントは対象外（このスクリプト自身などの誤検知を防ぐ）
SAFE_EXT='\.(sh|md|ts|js|mjs|cjs|dart|py|rb|go|sql|ya?ml|toml|lock|txt|html|css|mmd|svg)$'

# 引数を「読み取る」コマンド。git や ls などは対象外にして誤検知を減らす
READ_CMD='(^|[;&|(]|[[:space:]])(cat|bat|less|more|head|tail|sed|awk|strings|xxd|od|base64|jq|grep|rg|nl|tac|cp|scp|Get-Content|gc)([[:space:]]|$)'

# --- 判定関数 -------------------------------------------------------------

# 認証情報ファイルらしいパスなら 0 を返す
is_credential_path() {
  local base
  base=$(basename -- "$1" 2>/dev/null || true)
  [ -z "$base" ] && return 1

  if echo "$base" | grep -qiE "$SAFE_EXT"; then
    return 1
  fi
  if echo "$base" | grep -qiE "$ENV_FILE"; then
    return 0
  fi
  if echo "$base" | grep -qiE "$CRED_FILE"; then
    return 0
  fi
  if echo "$base" | grep -qiE "$CRED_NAME"; then
    return 0
  fi
  if echo "$base" | grep -qiE "$CRED_EXT"; then
    return 0
  fi
  return 1
}

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"⚠️ 認証情報・秘密鍵ファイル (%s) を読み取ろうとしています。中身が会話コンテキストに載るため、本当に必要か確認してください。"}}\n' "$1"
  exit 0
}

# --- Read ツール ----------------------------------------------------------

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [ -n "$FILE_PATH" ]; then
  if is_credential_path "$FILE_PATH"; then
    ask "$(basename -- "$FILE_PATH")"
  fi
  exit 0
fi

# --- Bash ツール ----------------------------------------------------------

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 読み取り系コマンドを含まないなら対象外
# （例: git check-ignore -v path/to/service-account.json は素通しする）
if ! echo "$COMMAND" | grep -qE "$READ_CMD"; then
  exit 0
fi

# 引数を1つずつ見て、認証情報らしいパスがあれば確認を求める
for token in $COMMAND; do
  case "$token" in
    -*) continue ;;
  esac
  # クォート・リダイレクト記号を落とす
  cleaned=$(echo "$token" | tr -d '"'"'"'<>|;&()')
  [ -z "$cleaned" ] && continue
  if is_credential_path "$cleaned"; then
    ask "$(basename -- "$cleaned")"
  fi
done

exit 0
