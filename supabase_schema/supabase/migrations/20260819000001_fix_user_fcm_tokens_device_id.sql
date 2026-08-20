-- user_fcm_tokens の device_id を端末ごとに一意な値へ是正する
--
-- 背景:
--   Android では DeviceIdService が Build.ID（OSビルドの識別子）を device_id として
--   保存していた。Build.ID は同じOSビルドで動く全端末で同じ値になるため、
--     1) device_id のグローバルユニーク制約により、2人目以降のユーザーの
--        FCMトークン登録が一意制約違反で失敗する
--     2) 同一ユーザーが同じビルドの端末を複数台使っても1行に潰れ、
--        マルチデバイス対応（20260314000001）が機能しない
--   という2つの不具合が発生していた。
--
--   アプリ側で device_id を端末ごとに生成した UUID に変更したため、
--   ここでは制約の是正と、二度と更新されない行の削除を行う。
--   ※ アプリ側の変更をリリースする前にこのマイグレーションだけを流すと、
--     同じ不正な device_id が入り直すため効果がない。

-- 1. device_id のグローバルユニーク制約を削除する
--
--    一意性は複合主キー (user_id, device_id) のみで担保する。
--    同一端末に複数ユーザーの行が並ぶことになるが、
--    pushNotify は user_id で絞り込むため送信先は正しい。
DROP INDEX IF EXISTS public.user_fcm_tokens_device_id_unique;

-- 2. UUID 形式でない device_id の行を削除する
--
--    対象:
--      - Android の Build.ID（例: TQ3A.230805.001）
--      - 20260314000001 で付与した legacy_<user_id>
--    これらの行はアプリ側の変更後に更新されることがなく、
--    無効なトークンとして残り続けるため削除する。
--
--    該当ユーザーは次回アプリ起動時に FcmTokenSyncService が
--    initialSession 契機で再登録するため、再ログインは不要。
DELETE FROM public.user_fcm_tokens
  WHERE device_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
