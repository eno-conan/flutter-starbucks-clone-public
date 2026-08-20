#!/usr/bin/env bash
# ============================================================================
# assetlinks.json の SHA-256 フィンガープリントを WebAuthn の
# Relying Party Origins に変換し、Supabase Auth へ反映する。
#
# 背景（Issue #924）:
#   同じ署名鍵の情報を 2 箇所に別形式で持っている。
#     - public/.well-known/assetlinks.json : 43:F2:CF:...（16進・コロン区切り）
#     - Supabase の Relying Party Origins  : android:apk-key-hash:Q_LPl-8e...（base64url）
#   片方だけ更新すると、エラーメッセージから原因を推測しにくい失敗になる。
#     - RP Origins 未更新 → 400 webauthn_verification_failed
#     - assetlinks 未更新 → DomainNotAssociatedException
#   変換自体は単純なので、手作業をなくすだけで事故が防げる。
#
#   使い方:
#     bash scripts/sync-rp-origins.sh            # 変換結果を表示するだけ（ネットワーク不要）
#     bash scripts/sync-rp-origins.sh --check    # Supabase の現在値と突き合わせ、差分があれば exit 1
#     bash scripts/sync-rp-origins.sh --apply    # Supabase へ反映する（差分がなければ何もしない）
#
#   必要な環境変数:
#     FIREBASE_HOSTING_DOMAIN  裸ドメイン（例: example.web.app）。https:// のオリジンに使う
#     SUPABASE_ACCESS_TOKEN    Management API のアクセストークン（--check / --apply のみ）
#     SUPABASE_PROJECT_REF     プロジェクト ref（未設定なら SUPABASE_URL から導出する）
#     SUPABASE_URL             https://<ref>.supabase.co（SUPABASE_PROJECT_REF の代替）
# ============================================================================
set -euo pipefail

# Relying Party Origins は Supabase 側の上限が 5 つ。https:// で 1 つ使うため
# Android のオリジンは最大 4 つまでしか登録できない。
readonly MAX_ORIGINS=5
readonly PASSKEY_RELATION='delegate_permission/common.get_login_creds'
readonly API_HOST='https://api.supabase.com'

MODE='print'
case "${1:-}" in
  ''|--print) MODE='print' ;;
  --check)    MODE='check' ;;
  --apply)    MODE='apply' ;;
  -h|--help)  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "❌ 不明な引数: $1（--print / --check / --apply）" >&2; exit 2 ;;
esac

cd "$(git rev-parse --show-toplevel)"
ASSETLINKS_PATH="${ASSETLINKS_PATH:-public/.well-known/assetlinks.json}"

for cmd in jq curl base64; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ $cmd が必要です" >&2; exit 1; }
done

[ -f "$ASSETLINKS_PATH" ] || { echo "❌ $ASSETLINKS_PATH が見つかりません" >&2; exit 1; }
: "${FIREBASE_HOSTING_DOMAIN:?FIREBASE_HOSTING_DOMAIN が未設定です}"

# --- 1. assetlinks.json から passkey 用エントリのフィンガープリントを取り出す ---
# App Links 用の handle_all_urls ではなく get_login_creds 側を見る。パスキーの
# オリジン検証に効くのはこちらで、両者は意図的に別の鍵集合を持ちうるため。
FINGERPRINTS=()
while IFS= read -r line; do
  FINGERPRINTS+=("$line")
done < <(
  jq -r --arg rel "$PASSKEY_RELATION" '
    .[] | select(.relation | index($rel))
        | .target.sha256_cert_fingerprints[]
  ' "$ASSETLINKS_PATH" | awk '!seen[$0]++'
)

if [ "${#FINGERPRINTS[@]}" -eq 0 ]; then
  echo "❌ $ASSETLINKS_PATH に $PASSKEY_RELATION のエントリがありません" >&2
  echo "   パスキーはこのエントリがないと DomainNotAssociatedException になります" >&2
  exit 1
fi

# --- 2. 16進フィンガープリント → android:apk-key-hash:<base64url> -------------
to_apk_key_hash() {
  local hex
  hex="$(printf '%s' "${1//:/}" | tr '[:lower:]' '[:upper:]')"
  if ! printf '%s' "$hex" | grep -qE '^[0-9A-F]{64}$'; then
    echo "❌ SHA-256 フィンガープリントとして解釈できません: $1" >&2
    return 1
  fi
  # 16進をバイト列に戻すのに bash 組み込みの printf '\xHH' を使う。xxd は
  # ランナー・開発機のどちらでも入っているとは限らないため依存を増やさない。
  # フォーマット文字列は直前の正規表現で 16 進 64 桁に限定済み。
  # shellcheck disable=SC2059
  printf 'android:apk-key-hash:%s' \
    "$(printf "$(printf '%s' "$hex" | sed 's/../\\x&/g')" \
       | base64 | tr -d '\n' | tr '+/' '-_' | tr -d '=')"
}

ORIGINS=("https://${FIREBASE_HOSTING_DOMAIN}")
for fp in "${FINGERPRINTS[@]}"; do
  ORIGINS+=("$(to_apk_key_hash "$fp")")
done

if [ "${#ORIGINS[@]}" -gt "$MAX_ORIGINS" ]; then
  echo "❌ オリジンが ${#ORIGINS[@]} 個あり、Supabase の上限 ${MAX_ORIGINS} 個を超えています" >&2
  echo "   assetlinks.json の $PASSKEY_RELATION から不要な鍵を削除してください（Issue #924）" >&2
  exit 1
fi

DESIRED="$(IFS=,; printf '%s' "${ORIGINS[*]}")"

echo "assetlinks.json: $ASSETLINKS_PATH"
echo "Relying Party Origins（${#ORIGINS[@]}/${MAX_ORIGINS}）:"
for o in "${ORIGINS[@]}"; do echo "  - $o"; done

[ "$MODE" = 'print' ] && exit 0

# --- 3. Supabase Management API と突き合わせる -------------------------------
: "${SUPABASE_ACCESS_TOKEN:?SUPABASE_ACCESS_TOKEN が未設定です}"
PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
if [ -z "$PROJECT_REF" ]; then
  # https://<ref>.supabase.co から ref を取り出す
  PROJECT_REF="$(printf '%s' "${SUPABASE_URL:-}" | sed -E 's#^https?://##; s#\..*$##')"
fi
[ -n "$PROJECT_REF" ] || { echo "❌ SUPABASE_PROJECT_REF も SUPABASE_URL も設定されていません" >&2; exit 1; }

API_URL="${API_HOST}/v1/projects/${PROJECT_REF}/config/auth"

# 401 ならトークン、404 なら project ref を疑う。curl の素のメッセージだけでは
# CI ログから切り分けられないため、必ず補足を出す。
api_failed() {
  echo "❌ Supabase Management API の呼び出しに失敗しました（$1）" >&2
  echo "   project ref: ${PROJECT_REF} / 401 ならトークン、404 なら ref を確認してください" >&2
  exit 1
}

CONFIG_JSON="$(curl -fsS "$API_URL" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}")" || api_failed GET
CURRENT="$(printf '%s' "$CONFIG_JSON" | jq -r '.webauthn_rp_origins // ""')"

# 順序の違いを差分として扱わない（ダッシュボード側で並べ替えられても検知しないため）
normalize() { printf '%s' "$1" | tr ',' '\n' | sed '/^$/d' | sort | tr '\n' ','; }

if [ "$(normalize "$CURRENT")" = "$(normalize "$DESIRED")" ]; then
  echo "✅ Supabase の Relying Party Origins は assetlinks.json と一致しています"
  exit 0
fi

echo "⚠️  差分があります"
echo "  現在: ${CURRENT:-（未設定）}"
echo "  期待: ${DESIRED}"

if [ "$MODE" = 'check' ]; then
  echo "   反映するには: bash scripts/sync-rp-origins.sh --apply" >&2
  exit 1
fi

curl -fsS -X PATCH "$API_URL" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg o "$DESIRED" '{webauthn_rp_origins: $o}')" \
  -o /dev/null || api_failed PATCH

echo "✅ Supabase へ反映しました"
