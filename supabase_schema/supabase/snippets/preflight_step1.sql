-- ============================================================================
-- Step 1 マイグレーション適用前チェック
--   対象: 20260820011334_add_integrity_constraints_step1.sql
--   経緯: Issue #938 のDB設計レビュー
--
-- 【これは何か】
--   Step 1 で追加する制約と 1 対 1 で対応する 20 件の検査。
--   本番データが制約に違反していると `npm run db:push` が失敗するため、
--   適用前にこのクエリで違反の有無を確認する。
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
--        psql "<connection string>" -f supabase_schema/supabase/snippets/preflight_step1.sql
--      ※ 接続文字列はパスワードを含むためシェル履歴に残さないこと
--
-- 【結果の読み方】
--   全行 result = 'OK'  → そのまま db:push してよい
--   result = 'BLOCKED' → blocked_constraint 列がどの制約で落ちるかを示す。
--                         対処は次の2択:
--                           1. データを是正する（推奨）
--                           2. 該当制約だけマイグレーションから外し、
--                              是正後に別マイグレーションで追加する
--
--   特に No.1〜5（NOT NULL）と No.17（スター二重付与）は本番でのみ
--   顕在化する可能性がある。ローカルはシードデータのため検出できない。
--
--   No.17 が 0 でない場合、過去に実際に二重付与が起きている。
--   重複行の削除に加えて star_aggregations の再計算が必要になる点に注意。
-- ============================================================================

with checks as (

  -- (1) orders_detail: 外部キー列の NOT NULL 化
  select 1 as no, 'orders_detail.order_id IS NULL' as check_name,
         count(*) as violations, 'ALTER COLUMN order_id SET NOT NULL' as blocks
    from orders_detail where order_id is null
  union all
  select 2, 'orders_detail.user_id IS NULL',
         count(*), 'ALTER COLUMN user_id SET NOT NULL'
    from orders_detail where user_id is null
  union all
  select 3, 'orders_detail.product_id IS NULL',
         count(*), 'ALTER COLUMN product_id SET NOT NULL'
    from orders_detail where product_id is null
  union all
  select 4, 'orders_detail.temperature_type_id IS NULL',
         count(*), 'ALTER COLUMN temperature_type_id SET NOT NULL'
    from orders_detail where temperature_type_id is null
  union all
  select 5, 'orders_detail.size_id IS NULL',
         count(*), 'ALTER COLUMN size_id SET NOT NULL'
    from orders_detail where size_id is null

  -- (2) 数量・小計の CHECK
  union all
  select 6, 'orders_detail.count <= 0',
         count(*), 'orders_detail_count_positive'
    from orders_detail where count <= 0
  union all
  select 7, 'orders_detail.subtotal_without_tax < 0',
         count(*), 'orders_detail_subtotal_non_negative'
    from orders_detail where subtotal_without_tax < 0
  union all
  select 8, 'carts_detail.count <= 0',
         count(*), 'carts_detail_count_positive'
    from carts_detail where count <= 0
  union all
  select 9, 'carts_detail.subtotal_without_tax < 0',
         count(*), 'carts_detail_subtotal_non_negative'
    from carts_detail where subtotal_without_tax < 0

  -- (3) 金額の CHECK
  union all
  select 10, 'cards.balance < 0',
         count(*), 'cards_balance_non_negative'
    from cards where balance < 0
  union all
  select 11, 'orders.price_without_tax < 0',
         count(*), 'orders_price_without_tax_non_negative'
    from orders where price_without_tax < 0
  union all
  select 12, 'orders.price_with_tax < price_without_tax',
         count(*), 'orders_price_with_tax_gte_without_tax'
    from orders where price_with_tax < price_without_tax
  union all
  select 13, 'product_sizes.price < 0',
         count(*), 'product_sizes_price_non_negative'
    from product_sizes where price < 0

  -- (4) スター関連の CHECK
  union all
  select 14, 'star_acquisitions.acquired_points < 0',
         count(*), 'star_acquisitions_points_non_negative'
    from star_acquisitions where acquired_points < 0
  union all
  select 15, 'star_usage.point_used < 0',
         count(*), 'star_usage_point_used_non_negative'
    from star_usage where point_used < 0
  union all
  select 16, 'star_aggregations.total_points < 0',
         count(*), 'star_aggregations_total_points_non_negative'
    from star_aggregations where total_points < 0

  -- (5) 一意制約（重複している「グループ数」を数える）
  union all
  select 17, 'star_acquisitions (order_id, category) の重複',
         count(*), 'star_acquisitions_order_id_category_key'
    from (
      select order_id, category from star_acquisitions
      group by order_id, category having count(*) > 1
    ) d
  union all
  select 18, 'cards メインカードを2枚以上持つユーザー',
         count(*), 'cards_user_id_is_main_key'
    from (
      select user_id from cards where is_main = 1
      group by user_id having count(*) > 1
    ) d

  -- (6) 座標の CHECK
  --     ※ DEFAULT 0.0 の (0,0) は範囲内なのでここでは検出されない。
  --        「未設定と実在座標が区別できない」問題は Step 2 以降で扱う。
  union all
  select 19, 'stores.latitude が -90..90 の範囲外',
         count(*), 'stores_latitude_range'
    from stores where latitude < -90 or latitude > 90
  union all
  select 20, 'stores.longitude が -180..180 の範囲外',
         count(*), 'stores_longitude_range'
    from stores where longitude < -180 or longitude > 180
)
select
  case when violations = 0 then 'OK' else 'BLOCKED' end as result,
  no,
  check_name,
  violations,
  blocks as blocked_constraint
from checks
order by (violations > 0) desc, no;
