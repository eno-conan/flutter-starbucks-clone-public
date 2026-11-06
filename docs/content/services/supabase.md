# Supabase

## ローカル開発

- [忘れたらこれ見て思い出せ](https://qiita.com/eno49conan/items/2169072ed6e4aa1d0164)

### コンテナ起動とデータ投入

```shell
cd supabase_schema
npm run login
npm run start
npm run db:reset
```

### 注文情報削除

```sql
DELETE FROM public.orders_detail
WHERE order_id IN (
  SELECT order_id
  FROM public.orders
  WHERE created_at < '2025-09-10'
);
DELETE FROM public.star_acquisitions
WHERE created_at < '2025-09-10';
DELETE FROM public.orders
WHERE created_at < '2025-09-10';
```

### Connection Error時の対応コマンド

```bash
adb reverse tcp:54321 tcp:54321
```

### Edge Function

- [公式docs](https://supabase.com/docs/guides/functions/examples/push-notifications?queryGroups=platform&platform=fcm)

```shell
npx supabase functions new {functionName}
# JWT 検証の要否は CLI フラグではなく supabase/config.toml で管理する。
# 新規関数を追加したら [functions.{functionName}] を必ず定義すること
#（未定義だと verify_jwt はデフォルトの true になる）。
# --no-verify-jwt は config.toml を上書きするため使わない。
npx supabase functions deploy {functionName}
```

!!! warning "JWT 検証は `config.toml` で管理する"
    - 新規関数を追加したら、`[functions.{functionName}]` を必ず定義する。
    - 未定義だと、`verify_jwt` はデフォルトの `true` になる。
    - `--no-verify-jwt` は `config.toml` を上書きするため、使わない。

## Google認証

- [Supabase 状態に応じた処理の実装方法](https://supabase.com/docs/reference/dart/auth-onauthstatechange)
- [Supabase Google認証の実装方法](https://supabase.com/docs/guides/auth/social-login/auth-google?queryGroups=platform&queryGroups=platform&platform=flutter)
- [Supabase Google認証 エラー解決1](https://zenn.dev/saisana299/articles/5f9d2426896423#android)
- [Supabase Google認証 エラー解決2](https://zenn.dev/tsukatsuka1783/articles/flutter_firebase_auth_google_sign_in)

??? question "上記 2 つの記事は、次のエラーが発生したときの対処法"
    ```text
    PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
    ```

## パスキー（Supabase Auth）

- パスキーを使うには、Supabase Auth（GoTrue）が **v2.188.0 以降**である必要がある。
- 設計の背景は [設計書 0001](../design/0001-passkey-introduction.md) の 3.6.1。
- Android 側の設定（`assetlinks.json`・Relying Party Origins）の失敗は、[Android 署名鍵の管理](../release/android-signing-keys.md) の 6 章を参照。

### Auth のバージョンを確認する

!!! danger "ダッシュボードに設定画面が出ても、サーバが対応しているとは限らない"
    - 設定画面はプラットフォーム側から配信されており、実際に動いている Auth コンテナとは別物。
    - v2.188.0 未満では、`/auth/v1/passkeys/*` が **プレーンテキストの `404 page not found`** を返し、パスキーは一切動作しない。

- 実際に動いているバージョンは、`/auth/v1/health` を叩いて確認する。ダッシュボードの表示より確実。

### Auth のバージョンを上げる

1. Supabase Cloud では、Auth / PostgREST / Postgres がプラットフォームのイメージとして一体で更新される。
2. そのため、**Postgres のアップグレード**を行う（Settings → Infrastructure → Service versions）。
3. 未サポート拡張が残っていると、アップグレードがブロックされる。

??? example "実績: Auth 2.176.1 → 2.195.0（`pgjwt` の削除が事前条件）"
    - このリポジトリでは、Auth 2.176.1 を 2.195.0 に上げた。
    - `pgjwt` 拡張の削除が事前条件だった（`supabase_schema/supabase/migrations/20260819000002_drop_pgjwt_extension.sql`）。

### 症状と見る場所

| 症状 | 原因 | 見る場所 |
|---|---|---|
| エンドポイントが `404 page not found`（プレーンテキスト） | Auth サーバがパスキー未対応（v2.188.0 未満） | 上の「Auth のバージョンを確認する」 |
| `DomainNotAssociatedException` / 400 `webauthn_verification_failed` | `assetlinks.json` または Relying Party Origins の不備 | [Android 署名鍵の管理](../release/android-signing-keys.md) の 6 章 |
