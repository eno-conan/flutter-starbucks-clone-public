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
npx supabase functions deploy {functionName} --no-verify-jwt
```

## Google認証
- [Supabase 状態に応じた処理の実装方法](https://supabase.com/docs/reference/dart/auth-onauthstatechange)
- [Supabase Google認証の実装方法](https://supabase.com/docs/guides/auth/social-login/auth-google?queryGroups=platform&queryGroups=platform&platform=flutter)
- [Supabase Google認証 エラー解決1](https://zenn.dev/saisana299/articles/5f9d2426896423#android)
- [Supabase Google認証 エラー解決2](https://zenn.dev/tsukatsuka1783/articles/flutter_firebase_auth_google_sign_in)
  - 以下エラーが発生したときの対処法について
    > PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
