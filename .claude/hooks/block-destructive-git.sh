#!/usr/bin/env bash
# PreToolUse(Bash) hook: 破壊的な git コマンドをブロックする。
#
# 以前は settings.json のインライン正規表現で実装していたが、コマンド文字列全体を
# 検査するため「危険コマンドを文章中の例として書いただけ」で誤検知していた
# （本ルールのドキュメント執筆時に実際に発生）。そのためコマンド位置に限定した
# 判定に置き換えた。
#
# さらに #920 の指摘を受け、オプション判定を部分文字列マッチから
# 「引数トークン単位の判定」に置き換えた。ブランチ名に含まれる `-f`
# （`-flutter` / `-flow` など）を強制 push と誤検知せず、結合短縮フラグ
# （`-fu` / `-fdx`）と refspec 先頭の `+`（`git push origin +main:main`）を取りこぼさない。
#
# 判定方法: コマンドを `;` `&&` `||` `|` `(` と改行で分割し、
#           「git で始まるセグメント」をトークン分解して危険オプションを探す。
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

# クオートで囲まれた引数（"--force" など）から前後のクオートを外す
strip_quotes() {
  local t=$1
  t=${t#[\"\']}
  t=${t%[\"\']}
  printf '%s' "$t"
}

# `--force` / `--force-with-lease` / `--force=...` のような長いオプションか
is_force_long_opt() {
  case "$1" in
    --force|--force=*|--force-*) return 0 ;;
    *) return 1 ;;
  esac
}

# `-f` を含む短縮フラグの塊か（`-fu` `-fdx` `-xdf` などの結合指定を含む）
# ブランチ名やパスは `-` で始まらないため誤検知しない。
has_short_flag_f() {
  case "$1" in
    --*) return 1 ;;
    -*f*) return 0 ;;
    *) return 1 ;;
  esac
}

# refspec 先頭の `+`（`git push origin +main:main` = 強制 push）か
is_plus_refspec() {
  case "$1" in
    +?*) return 0 ;;
    *) return 1 ;;
  esac
}

# セグメント分割（区切り文字を改行に置換）。改行自体もコマンド区切りとして扱う。
SEGMENTS=$(printf '%s' "$COMMAND" | sed -E 's/(\&\&|\|\||[;|(])/\n/g')

# トークン分解時にグロブ展開されないようにする
set -f

while IFS= read -r seg; do
  # 空白を正規化し、前後に空白を付けてオプション判定を単純化する
  norm=" $(printf '%s' "$seg" | tr -s '[:space:]' ' ' | sed -E 's/^ +//; s/ +$//') "
  # sudo / env プレフィックスを落とす
  norm=$(printf '%s' "$norm" | sed -E 's/^ (sudo|env) / /')

  case "$norm" in
    " git "*) ;;
    *) continue ;;
  esac

  # shellcheck disable=SC2086
  set -- $norm
  shift # 先頭の `git` を捨てる

  # git 自体のグローバルオプション（`-C <path>` / `-c <k=v>` など）を読み飛ばし、
  # サブコマンドを特定する
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c|--git-dir|--work-tree|--namespace|--exec-path)
        shift 2 2>/dev/null || shift $# ;;
      -*)
        shift ;;
      *)
        break ;;
    esac
  done

  [ $# -eq 0 ] && continue
  subcommand=$1
  shift

  case "$subcommand" in
    push)
      for tok in "$@"; do
        tok=$(strip_quotes "$tok")
        if is_force_long_opt "$tok" || has_short_flag_f "$tok" || is_plus_refspec "$tok"; then
          deny '強制 push はブロックされました。共有ブランチの履歴が失われるため、必要な場合はユーザー自身に実行を依頼してください。'
        fi
      done ;;
    reset)
      for tok in "$@"; do
        case "$(strip_quotes "$tok")" in
          --hard)
            deny '作業ツリーを破棄する reset はブロックされました。未コミットの変更が失われます。退避が必要な場合は git stash を使ってください。' ;;
        esac
      done ;;
    clean)
      for tok in "$@"; do
        tok=$(strip_quotes "$tok")
        if is_force_long_opt "$tok" || has_short_flag_f "$tok"; then
          deny '未追跡ファイルを削除する clean はブロックされました。必要な場合はユーザー自身に実行を依頼してください。'
        fi
      done ;;
    filter-branch|filter-repo)
      deny '履歴書き換え（filter-branch / filter-repo）はブロックされました。ユーザーの判断で実行してください。' ;;
  esac
done <<< "$SEGMENTS"

exit 0
