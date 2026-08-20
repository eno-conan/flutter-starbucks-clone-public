-- ============================================================================
-- DB設計レビュー (Issue #938) Step 3-1: 期間・座標の制約とタイムスタンプの統一
--
-- レビュー C（金額・数量に対する制約の欠落）のうち Step 1 で入れ切れなかった
-- 「期間」「座標のDEFAULT」と、E-3（created_at / updated_at の NOT NULL 混在）、
-- E-5（poc_realtime の位置づけ）を扱う。
--
-- アプリ改修は不要。既存データの違反ゼロは
-- supabase_schema/supabase/snippets/preflight_step3.sql で確認すること。
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. 期間の前後関係 (C)
--
--    start < end / open < close がどこにも保証されておらず、
--    入力ミスがそのまま「終了済みなのに開始前」のキャンペーンや
--    営業時間が破綻した店舗として残る状態だった。
--
--    ※ stores は深夜営業（日をまたぐ営業時間）を扱わない前提。
--      24時間営業や翌日クローズを扱うようになったら、この制約ではなく
--      「営業日をまたぐか」を表す列を追加して表現し直すこと。
-- ----------------------------------------------------------------------------
alter table "public"."stores"
  add constraint "stores_opening_before_closing" check ((opening_time < closing_time)) not valid;
alter table "public"."stores" validate constraint "stores_opening_before_closing";

alter table "public"."campaign_settings"
  add constraint "campaign_settings_start_before_end" check ((start_date < end_date)) not valid;
alter table "public"."campaign_settings" validate constraint "campaign_settings_start_before_end";


-- ----------------------------------------------------------------------------
-- 2. 座標の DEFAULT 0.0 を外す (C)
--
--    (0, 0) はギニア湾沖の実在座標であり、「未設定」と区別できなかった。
--    列は NOT NULL のままなので、DEFAULT を外すと座標を渡さない INSERT は
--    その場でエラーになる（＝未設定のまま店舗が登録されることがなくなる）。
--    値域は Step 1 の stores_latitude_range / stores_longitude_range が担保する。
-- ----------------------------------------------------------------------------
alter table "public"."stores" alter column "latitude" drop default;
alter table "public"."stores" alter column "longitude" drop default;


-- ----------------------------------------------------------------------------
-- 3. created_at / updated_at の NOT NULL 統一 (E-3)
--
--    初期に作られたテーブルだけ nullable のまま残っており、
--    Step 1 で updated_at トリガを全テーブルに入れた今も
--    「NULL のまま差分同期の判定に使えない行」を作れる状態だった。
--
--    DEFAULT は既に全テーブルに付いているため、NULL 行は
--    明示的に NULL を入れた場合にしか生まれない。念のため now() で埋めてから
--    NOT NULL にする。
-- ----------------------------------------------------------------------------
update "public"."campaign_settings" set "created_at" = now() where "created_at" is null;
update "public"."campaign_settings" set "updated_at" = now() where "updated_at" is null;
alter table "public"."campaign_settings" alter column "created_at" set not null;
alter table "public"."campaign_settings" alter column "updated_at" set not null;

update "public"."categories" set "created_at" = now() where "created_at" is null;
update "public"."categories" set "updated_at" = now() where "updated_at" is null;
alter table "public"."categories" alter column "created_at" set not null;
alter table "public"."categories" alter column "updated_at" set not null;

update "public"."products" set "created_at" = now() where "created_at" is null;
update "public"."products" set "updated_at" = now() where "updated_at" is null;
alter table "public"."products" alter column "created_at" set not null;
alter table "public"."products" alter column "updated_at" set not null;

update "public"."staff" set "created_at" = now() where "created_at" is null;
update "public"."staff" set "updated_at" = now() where "updated_at" is null;
alter table "public"."staff" alter column "created_at" set not null;
alter table "public"."staff" alter column "updated_at" set not null;

update "public"."staff_schedules" set "created_at" = now() where "created_at" is null;
update "public"."staff_schedules" set "updated_at" = now() where "updated_at" is null;
alter table "public"."staff_schedules" alter column "created_at" set not null;
alter table "public"."staff_schedules" alter column "updated_at" set not null;

update "public"."store_profiles" set "created_at" = now() where "created_at" is null;
update "public"."store_profiles" set "updated_at" = now() where "updated_at" is null;
alter table "public"."store_profiles" alter column "created_at" set not null;
alter table "public"."store_profiles" alter column "updated_at" set not null;

update "public"."stores" set "created_at" = now() where "created_at" is null;
update "public"."stores" set "updated_at" = now() where "updated_at" is null;
alter table "public"."stores" alter column "created_at" set not null;
alter table "public"."stores" alter column "updated_at" set not null;

update "public"."user_fcm_tokens" set "created_at" = now() where "created_at" is null;
update "public"."user_fcm_tokens" set "updated_at" = now() where "updated_at" is null;
alter table "public"."user_fcm_tokens" alter column "created_at" set not null;
alter table "public"."user_fcm_tokens" alter column "updated_at" set not null;


-- ----------------------------------------------------------------------------
-- 4. poc_realtime の位置づけを明記 (E-5)
--
--    「別スキーマへ隔離するか削除」も検討したが、lib/poc/ 配下の画面が
--    アプリのルートに組み込まれて稼働しているため、どちらも機能の削除を伴う。
--    Step 1 で RLS・updated_at トリガの適用範囲は他テーブルと揃っているため、
--    ここでは「なぜ public に残っているのか」をスキーマ自身に残すに留める。
-- ----------------------------------------------------------------------------
comment on table public.poc_realtime is
  'Supabase Realtime 検証用のPoCテーブル。本番機能では使用しない（参照元は lib/poc/ のみ）。別スキーマへの隔離・削除は PoC 画面をアプリから外すときに合わせて判断する (Issue #938 E-5)';
