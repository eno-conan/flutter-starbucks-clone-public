-- ============================================================================
-- Step 3 マイグレーション適用前チェック
--   対象: 20260820100001_step3_amount_and_lifecycle_constraints.sql
--         20260820100002_step3_order_history_snapshot.sql
--         20260820100003_step3_user_deletion_policy.sql
--         20260820100004_step3_cleanup_expired_rows.sql
--   経緯: Issue #938 のDB設計レビュー（C / D / E）
--
-- 【これは何か】
--   Step 3 が追加する CHECK・NOT NULL・スナップショット列の埋め戻しと
--   1 対 1 で対応する検査。Step 1 / Step 2 と同じ読み方をする。
--
-- 【安全性】
--   SELECT のみ。データを一切変更しない。
--
-- 【実行方法】
--   A. Supabase Dashboard → SQL Editor に貼り付けて実行（推奨）
--      postgres 権限で実行されるため RLS の影響を受けない
--
--   B. CLI から実行する場合（接続文字列は Dashboard の
--      Settings → Database → Connection string）
--        psql "<connection string>" -f supabase_schema/supabase/snippets/preflight_step3.sql
--      ※ 接続文字列はパスワードを含むためシェル履歴に残さないこと
--
-- 【結果の読み方】
--   result = 'OK'      → 問題なし
--   result = 'BLOCKED' → そのまま適用すると **失敗する**。
--                        blocked_by 列がどの操作で落ちるかを示す。
--   result = 'WARN'    → 適用は通るが、埋め戻される値が期待と違いうる。
--   result = 'INFO'    → 是正方針を決めるための参考値。
--
-- 【特に注意すべき検査】
--   No.6 単価と小計の不整合
--     unit_price_without_tax は subtotal_without_tax / count で埋め戻す。
--     割り切れない明細があると orders_detail_subtotal_matches_unit_price の
--     validate で落ちる。該当行は末尾の補足クエリで特定できる。
--
--   No.7 商品マスタに存在しない product_id
--     product_name の埋め戻しが NULL のままになり、SET NOT NULL で落ちる。
--     orders_detail.product_id は FK があるため通常は 0 件。
--
--   No.10 / No.11 深夜営業・逆転した期間
--     stores_opening_before_closing / campaign_settings_start_before_end は
--     日をまたぐ営業時間を表現できない。該当店舗があるなら制約ではなく
--     「営業日をまたぐか」を持つ設計に変える必要がある。
-- ============================================================================

with checks as (

  -- ==========================================================================
  -- (0) 前提スキーマの確認
  --     Step 3 は Step 1 / Step 2 の適用済みを前提とする
  -- ==========================================================================

  select 1 as no,
         'Step 2 が未適用（provided_status_enum 型が無い）' as check_name,
         'BLOCKED' as severity,
         1 - count(*) as violations,
         'Step 3 は Step 2 適用済みを前提とする（先に Step 2 を適用すること）' as blocks
    from pg_type
   where typname = 'provided_status_enum'
     and typnamespace = 'public'::regnamespace

  union all
  select 2,
         'orders.tax_rate が既に存在する（再実行）',
         'BLOCKED',
         count(*),
         'alter table orders add column tax_rate'
    from pg_attribute
   where attrelid = 'public.orders'::regclass
     and attname = 'tax_rate'
     and not attisdropped

  union all
  select 3,
         'orders_detail.product_name が既に存在する（再実行）',
         'BLOCKED',
         count(*),
         'alter table orders_detail add column product_name'
    from pg_attribute
   where attrelid = 'public.orders_detail'::regclass
     and attname = 'product_name'
     and not attisdropped

  -- ==========================================================================
  -- (1) D-1 注文明細のスナップショット埋め戻し
  -- ==========================================================================

  union all
  select 4,
         'orders_detail.count が 0 の明細（0除算になる）',
         'BLOCKED',
         count(*),
         'update orders_detail set unit_price_without_tax = subtotal_without_tax / count'
    from public.orders_detail
   where count = 0

  union all
  select 5,
         'orders_detail_archive.count が 0 の明細（埋め戻しから除外される）',
         'WARN',
         count(*),
         'update orders_detail_archive set unit_price_without_tax = ...（NULL のまま残る）'
    from public.orders_detail_archive
   where count = 0 or count is null

  union all
  select 6,
         '単価×数量が小計と一致しない明細（割り切れない）',
         'BLOCKED',
         count(*),
         'validate constraint orders_detail_subtotal_matches_unit_price'
    from public.orders_detail
   where count > 0
     and subtotal_without_tax <> ((subtotal_without_tax / count) * count)

  union all
  select 7,
         '商品マスタに存在しない product_id を持つ明細',
         'BLOCKED',
         count(*),
         'alter table orders_detail alter column product_name set not null'
    from public.orders_detail od
   where not exists (
           select 1 from public.products p where p.product_id = od.product_id
         )

  union all
  select 8,
         'アーカイブ側で商品マスタに存在しない product_id',
         'INFO',
         count(*),
         'orders_detail_archive.product_name が NULL のまま残る（NOT NULL は課さない）'
    from public.orders_detail_archive oda
   where oda.product_id is null
      or not exists (
           select 1 from public.products p where p.product_id = oda.product_id
         )

  -- ==========================================================================
  -- (2) D-2 税率の埋め戻し
  -- ==========================================================================

  union all
  select 9,
         '税率を復元できない注文（税抜が0）',
         'INFO',
         count(*),
         'orders.tax_rate は 0 で埋め戻される'
    from public.orders
   where price_without_tax = 0

  -- ==========================================================================
  -- (3) C 期間・座標
  -- ==========================================================================

  union all
  select 10,
         '開店時刻が閉店時刻以降の店舗（深夜営業）',
         'BLOCKED',
         count(*),
         'validate constraint stores_opening_before_closing'
    from public.stores
   where opening_time >= closing_time

  union all
  select 11,
         '開始日時が終了日時以降のキャンペーン',
         'BLOCKED',
         count(*),
         'validate constraint campaign_settings_start_before_end'
    from public.campaign_settings
   where start_date >= end_date

  union all
  select 12,
         '座標が未設定のまま (0, 0) になっている店舗',
         'INFO',
         count(*),
         'DEFAULT を外すだけなので適用は通るが、既存の (0,0) は残る'
    from public.stores
   where latitude = 0 and longitude = 0

  -- ==========================================================================
  -- (4) E-3 タイムスタンプの NOT NULL 化
  --     いずれも DEFAULT があるため通常は 0 件。
  --     マイグレーション側で now() 埋めを先に行うので BLOCKED ではない。
  -- ==========================================================================

  union all
  select 13,
         'created_at / updated_at が NULL の行（now() で埋め戻される）',
         'WARN',
         (select count(*) from public.campaign_settings where created_at is null or updated_at is null)
       + (select count(*) from public.categories        where created_at is null or updated_at is null)
       + (select count(*) from public.products          where created_at is null or updated_at is null)
       + (select count(*) from public.staff             where created_at is null or updated_at is null)
       + (select count(*) from public.staff_schedules   where created_at is null or updated_at is null)
       + (select count(*) from public.store_profiles    where created_at is null or updated_at is null)
       + (select count(*) from public.stores            where created_at is null or updated_at is null)
       + (select count(*) from public.user_fcm_tokens   where created_at is null or updated_at is null),
         'alter column created_at / updated_at set not null（実時刻ではなく適用時刻になる）'

  -- ==========================================================================
  -- (5) E-1 退会時の削除ポリシー
  --     FK の張り替えは既存データに触れないが、
  --     参照先が消えている行があると validate で落ちる。
  -- ==========================================================================

  union all
  select 14,
         'auth.users に存在しない user_id を持つ注文',
         'BLOCKED',
         count(*),
         'validate constraint orders_user_id_fkey'
    from public.orders o
   where o.user_id is not null
     and not exists (select 1 from auth.users u where u.id = o.user_id)

  union all
  select 15,
         'auth.users に存在しない user_id を持つカード',
         'BLOCKED',
         count(*),
         'validate constraint cards_user_id_fkey'
    from public.cards c
   where not exists (select 1 from auth.users u where u.id = c.user_id)

  union all
  select 16,
         'auth.users に存在しない user_id を持つスター獲得履歴',
         'BLOCKED',
         count(*),
         'validate constraint star_acquisitions_user_id_fkey'
    from public.star_acquisitions sa
   where not exists (select 1 from auth.users u where u.id = sa.user_id)

  union all
  select 19,
         '張り替え対象の FK 名がスキーマ上に見つからない',
         'BLOCKED',
         10 - count(*),
         '20260820100003 の drop constraint（IF EXISTS を付けていない）'
    from pg_constraint
   where contype = 'f'
     and conname in (
       'cards_user_id_fkey', 'carts_user_id_fkey', 'user_fcm_tokens_user_id_fkey',
       'user_tickets_user_id_fkey', 'store_profiles_user_id_fkey',
       'star_aggregations_user_id_fkey', 'orders_user_id_fkey',
       'orders_detail_user_id_fkey', 'star_acquisitions_user_id_fkey',
       'star_usage_user_id_fkey'
     )

  -- ==========================================================================
  -- (6) E-7 クリーンアップ対象の量（初回実行で消える件数の目安）
  -- ==========================================================================

  union all
  select 17,
         '初回クリーンアップで削除される仮登録ユーザー',
         'INFO',
         count(*),
         'cleanup_expired_pre_signup_users(24) の削除対象'
    from public.pre_signup_users
   where expires_at < now() - interval '24 hours'

  union all
  select 18,
         '初回クリーンアップで削除されるレート制限記録',
         'INFO',
         count(*),
         'cleanup_email_check_rate_limits(7) の削除対象'
    from public.email_check_rate_limits
   where created_at < now() - interval '7 days'

)
select
  case when violations = 0 then 'OK' else severity end as result,
  no,
  check_name,
  violations,
  blocks as blocked_by
from checks
order by
  (violations > 0) desc,
  case severity when 'BLOCKED' then 0 when 'WARN' then 1 else 2 end,
  no;


-- ============================================================================
-- 補足クエリ（必要になったときだけ個別に実行する）
--
-- Supabase の SQL Editor は最後の文の結果しか表示しないため、
-- 上のチェックとは分けてコメントアウトしてある。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- No.6 の該当行を実際に見る（単価×数量が小計に一致しない明細）
-- ----------------------------------------------------------------------------
-- select od.id, od.order_id, od.product_id, od.count, od.subtotal_without_tax,
--        od.subtotal_without_tax::numeric / od.count as implied_unit_price
--   from public.orders_detail od
--  where od.count > 0
--    and od.subtotal_without_tax <> ((od.subtotal_without_tax / od.count) * od.count)
--  order by od.order_id;

-- ----------------------------------------------------------------------------
-- No.10 の該当行を実際に見る（深夜営業の店舗）
-- ----------------------------------------------------------------------------
-- select store_number, store_name, opening_time, closing_time
--   from public.stores
--  where opening_time >= closing_time
--  order by store_number;

-- ----------------------------------------------------------------------------
-- 適用後の確認: tax_rate の分布が想定（8 / 10）に収まっているか
-- ----------------------------------------------------------------------------
-- select tax_rate, count(*) as orders
--   from public.orders
--  group by tax_rate
--  order by tax_rate;
