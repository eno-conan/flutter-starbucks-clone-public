-- user_fcm_tokens テーブルをマルチデバイス対応に変更する
-- 既存のPK(user_id)を複合PK(user_id, device_id)に変更し、
-- 同一ユーザーが複数端末でログインしても全端末のFCMトークンを保持できるようにする

-- device_id カラム追加（一時的にNULL許容）
ALTER TABLE "public"."user_fcm_tokens"
  ADD COLUMN IF NOT EXISTS "device_id" text,
  ADD COLUMN IF NOT EXISTS "device_name" text,
  ADD COLUMN IF NOT EXISTS "created_at" timestamp with time zone DEFAULT now(),
  ADD COLUMN IF NOT EXISTS "updated_at" timestamp with time zone DEFAULT now();

-- 既存レコードにダミーdevice_idをセット（マイグレーション用）
UPDATE "public"."user_fcm_tokens"
  SET device_id = 'legacy_' || user_id
  WHERE device_id IS NULL;

-- NOT NULL制約を付与
ALTER TABLE "public"."user_fcm_tokens"
  ALTER COLUMN "device_id" SET NOT NULL;

-- 既存PK削除
ALTER TABLE "public"."user_fcm_tokens"
  DROP CONSTRAINT IF EXISTS user_fcm_tokens_user_id_pkey;

-- 複合PK追加（user_id + device_id）
ALTER TABLE "public"."user_fcm_tokens"
  ADD CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (user_id, device_id);

-- device_idのグローバルユニーク制約
CREATE UNIQUE INDEX IF NOT EXISTS user_fcm_tokens_device_id_unique
  ON public.user_fcm_tokens(device_id);
