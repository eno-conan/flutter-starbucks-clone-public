-- 旧テーブル public.user_profiles の削除
--
-- 背景:
--   FCMトークン保持用として 20250406013719 で作成したが、複数デバイス対応のため
--   user_fcm_tokens に移行済みでアプリからは未使用。リモートDBではマイグレーション外で
--   既に削除されており、ローカルとの乖離が db push 失敗の原因となっていた。
--   ここで正式に削除し、ローカル・リモート双方のスキーマを一致させる。
DROP TABLE IF EXISTS public.user_profiles;
