-- ============================================================================
-- Step 2 マイグレーション適用前チェック
--   対象: 20260820020409_step2_types_flags_and_fks.sql
--   経緯: Issue #938 のDB設計レビュー
--
-- 【これは何か】
--   Step 2 が行う型変換・FK 追加・CHECK 追加と 1 対 1 で対応する 28 件の検査。
--   Step 1 と違い、Step 2 は「エラーで止まる」だけでなく
--   「エラーにならずに値が静かに変わる／消える」変換を複数含む。
--   そのため BLOCKED（適用が失敗する）と WARN（適用は通るがデータが変わる）を
--   区別して出力する。
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
--        psql "<connection string>" -f supabase_schema/supabase/snippets/preflight_step2.sql
--      ※ 接続文字列はパスワードを含むためシェル履歴に残さないこと
--
-- 【結果の読み方】
--   result = 'OK'      → 問題なし
--   result = 'BLOCKED' → そのまま適用すると **失敗する**。
--                        blocked_by 列がどの操作で落ちるかを示す。対処は2択:
--                          1. データを是正してから適用する（推奨）
--                          2. 該当操作だけマイグレーションから外し、
--                             是正後に別マイグレーションで追加する
--   result = 'WARN'    → 適用は通るが **値が静かに変換・NULL 化される**。
--                        件数を確認し、失っても良い値かを判断すること。
--                        判断がつかない場合は適用前にバックアップを取る。
--   result = 'INFO'    → 是正方針を決めるための参考値。それ自体は問題ではない。
--
-- 【特に注意すべき検査】
--   No.19 star_usage → orders の FK 違反
--     archive_old_orders はこれまで star_usage を退避していなかったため、
--     **アーカイブ済みの注文を参照したままの star_usage 行が残っている**
--     可能性が高い。No.20 でその内訳（orders_archive にあるか）を出している。
--     退避漏れが原因なら star_usage_archive へ移して削除するのが筋。
--
--   No.26 / No.27 birthday の日付化
--     8桁数字以外は **NULL に落ちる**（= 生年月日が消える）。
--     アプリは Step 2 で 'YYYYMMDD' → 'YYYY-MM-DD' に書式変更しているため、
--     アプリ先行デプロイでハイフン付きの値が入っていると No.26 に計上される。
--     マイグレーションとアプリは必ず同時に出すこと。
--
--   No.8 cards.is_main の NOT NULL 化
--     現在の is_main は NULL 可。1件でも NULL があると適用が失敗する。
-- ============================================================================

with checks as (

  -- ==========================================================================
  -- (0) 前提スキーマの確認
  --     Step 2 には IF EXISTS を付けていない DROP と CREATE TYPE があるため、
  --     再実行や適用順の誤りをここで検出する
  -- ==========================================================================

  select 1 as no,
         'provided_status_enum 型が既に存在する（再実行）' as check_name,
         'BLOCKED' as severity,
         count(*) as violations,
         'create type public.provided_status_enum' as blocks
    from pg_type
   where typname = 'provided_status_enum'
     and typnamespace = 'public'::regnamespace

  union all
  select 2,
         'Step 1 が未適用（cards_user_id_is_main_key が無い）',
         'BLOCKED',
         1 - count(*),
         'Step 2 は Step 1 適用済みを前提とする（先に Step 1 を適用すること）'
    from pg_class
   where relname = 'cards_user_id_is_main_key'
     and relnamespace = 'public'::regnamespace

  union all
  select 3,
         'orders_provided_status_check が存在しない',
         'BLOCKED',
         1 - count(*),
         'alter table orders drop constraint orders_provided_status_check'
    from pg_constraint
   where conname = 'orders_provided_status_check'
     and conrelid = 'public.orders'::regclass

  union all
  select 4,
         'stores_is_drive_thru_available_check が存在しない',
         'BLOCKED',
         1 - count(*),
         'alter table stores drop constraint stores_is_drive_thru_available_check'
    from pg_constraint
   where conname = 'stores_is_drive_thru_available_check'
     and conrelid = 'public.stores'::regclass

  union all
  select 5,
         'carts_detail_user_id_fkey が存在しない',
         'BLOCKED',
         1 - count(*),
         'alter table carts_detail drop constraint carts_detail_user_id_fkey'
    from pg_constraint
   where conname = 'carts_detail_user_id_fkey'
     and conrelid = 'public.carts_detail'::regclass

  -- ==========================================================================
  -- (1) provided_status の enum 化 (B-2)
  --     USING の CASE は 0/1/2/99 以外を NULL にする。
  --     両テーブルとも NOT NULL のため、NULL 化は即エラーになる。
  -- ==========================================================================

  union all
  select 6,
         'orders.provided_status が 0/1/2/99 以外',
         'BLOCKED',
         count(*),
         'orders.provided_status → provided_status_enum'
    from orders
   where provided_status is null
      or provided_status not in ('0', '1', '2', '99')

  union all
  -- orders_archive には CHECK 制約が無いため、orders と違って想定外の値が入りうる
  select 7,
         'orders_archive.provided_status が 0/1/2/99 以外',
         'BLOCKED',
         count(*),
         'orders_archive.provided_status → provided_status_enum'
    from orders_archive
   where provided_status is null
      or provided_status not in ('0', '1', '2', '99')

  -- ==========================================================================
  -- (2) 真偽値の boolean 化 (B-1)
  --     USING は `<> 0`（stores のみ `= '1'`）なので、想定外の値でも
  --     エラーにはならず true / false に丸められる。
  --     丸め自体は WARN、NOT NULL 化と一意制約に絡むものは BLOCKED。
  -- ==========================================================================

  union all
  select 8,
         'cards.is_main が NULL',
         'BLOCKED',
         count(*),
         'cards.is_main SET NOT NULL'
    from cards
   where is_main is null

  union all
  select 9,
         'cards.is_main が 0/1 以外（true に丸められる）',
         'WARN',
         count(*),
         'cards.is_main → boolean（using is_main <> 0）'
    from cards
   where is_main is not null
     and is_main not in (0, 1)

  union all
  -- Step 1 の索引は `where is_main = 1` だが、Step 2 は `where is_main`
  -- （= is_main <> 0）に広がる。is_main = 2 のような値があると新たに衝突する
  select 10,
         'is_main <> 0 の行を2件以上持つユーザー',
         'BLOCKED',
         count(*),
         'create unique index cards_user_id_is_main_key ... where (is_main)'
    from (
      select user_id
        from cards
       where is_main is not null
         and is_main <> 0
       group by user_id
      having count(*) > 1
    ) d

  union all
  select 11,
         'user_fcm_tokens.is_notify が 0/1 以外（true に丸められる）',
         'WARN',
         count(*),
         'user_fcm_tokens.is_notify → boolean'
    from user_fcm_tokens
   where is_notify not in (0, 1)

  union all
  select 12,
         'user_mail_settings.is_send_related_rewards が 0/1 以外',
         'WARN',
         count(*),
         'user_mail_settings.is_send_related_rewards → boolean'
    from user_mail_settings
   where is_send_related_rewards not in (0, 1)

  union all
  select 13,
         'user_mail_settings.is_send_advance_product_announce が 0/1 以外',
         'WARN',
         count(*),
         'user_mail_settings.is_send_advance_product_announce → boolean'
    from user_mail_settings
   where is_send_advance_product_announce not in (0, 1)

  union all
  select 14,
         'user_mail_settings.is_html_mail が 0/1 以外',
         'WARN',
         count(*),
         'user_mail_settings.is_html_mail → boolean'
    from user_mail_settings
   where is_html_mail not in (0, 1)

  union all
  select 15,
         'star_aggregations.expiration_flag が 0/1 以外',
         'WARN',
         count(*),
         'star_aggregations.expiration_flag → boolean'
    from star_aggregations
   where expiration_flag not in (0, 1)

  union all
  -- stores は `= '1'` 判定のため、想定外の値はすべて false に倒れる
  select 16,
         'stores.is_drive_thru_available が 0/1 以外（false に丸められる）',
         'WARN',
         count(*),
         'stores.is_drive_thru_available → boolean（using = ''1''）'
    from stores
   where is_drive_thru_available is null
      or is_drive_thru_available not in ('0', '1')

  -- ==========================================================================
  -- (3) 参照整合性の回復 (A-2 / A-3 / A-6)
  -- ==========================================================================

  -- 3-1. carts_detail → carts
  union all
  select 17,
         'carts_detail に対応する carts が無い（親不在の明細）',
         'BLOCKED',
         count(*),
         'carts_detail_user_id_fkey → carts(user_id)'
    from carts_detail cd
   where not exists (
           select 1 from carts c where c.user_id = cd.user_id
         )

  -- 3-2. star_usage → orders
  union all
  -- varchar(32) への明示キャストは 32 文字超を **エラーにせず切り詰める**。
  -- 切り詰まった値は当然 orders に無いので、直後の FK 検証で落ちる
  select 18,
         'star_usage.order_id が 32 文字超（切り詰められる）',
         'BLOCKED',
         count(*),
         'star_usage.order_id → character varying(32)'
    from star_usage
   where order_id is not null
     and length(order_id) > 32

  union all
  select 19,
         'star_usage.order_id が orders に存在しない',
         'BLOCKED',
         count(*),
         'star_usage_order_id_fkey → orders(order_id)'
    from star_usage su
   where su.order_id is not null
     and not exists (
           select 1 from orders o where o.order_id = su.order_id::varchar(32)
         )

  union all
  -- No.19 の内訳。アーカイブ済み注文を指しているだけなら
  -- star_usage_archive へ退避して削除するのが是正方針になる
  select 20,
         '  └ うち orders_archive には存在する（退避漏れ）',
         'INFO',
         count(*),
         '是正方針の判断材料（No.19 の内訳）'
    from star_usage su
   where su.order_id is not null
     and not exists (
           select 1 from orders o where o.order_id = su.order_id::varchar(32)
         )
     and exists (
           select 1 from orders_archive oa where oa.order_id = su.order_id
         )

  union all
  select 21,
         'star_usage で order_id も exchange_item_id も NULL',
         'BLOCKED',
         count(*),
         'star_usage_reference_required'
    from star_usage
   where order_id is null
     and exchange_item_id is null

  union all
  select 22,
         'star_usage_archive.order_id が 32 文字超（切り詰められる）',
         'WARN',
         count(*),
         'star_usage_archive.order_id → character varying(32)'
    from star_usage_archive
   where order_id is not null
     and length(order_id) > 32

  -- 3-4. staff_schedules → stores
  union all
  -- character(4) への明示キャストは 4 文字超を切り詰め、4 文字未満を
  -- 空白で右詰めする。どちらも stores.store_number と一致しなくなる
  select 23,
         'staff_schedules.store_number が 4 文字でない',
         'BLOCKED',
         count(*),
         'staff_schedules.store_number → character(4)'
    from staff_schedules
   where store_number is not null
     and length(rtrim(store_number)) <> 4

  union all
  select 24,
         'staff_schedules.store_number が stores に存在しない',
         'BLOCKED',
         count(*),
         'staff_schedules_store_number_fkey → stores(store_number)'
    from staff_schedules ss
   where ss.store_number is not null
     and not exists (
           select 1 from stores s
            where s.store_number = ss.store_number::character(4)
         )

  union all
  -- FK は NULL を許すので適用は通るが、get_store_wait_times の
  -- 店舗別集計から漏れ続けることになる
  select 25,
         'staff_schedules.store_number が NULL',
         'WARN',
         count(*),
         '店舗別集計から漏れる（FK 自体は NULL を許容）'
    from staff_schedules
   where store_number is null

  -- ==========================================================================
  -- (4) birthday の date 化 / sex の値域 (B-4)
  -- ==========================================================================

  union all
  -- USING の CASE により、8桁数字でない値はすべて NULL に落ちる（= 消失）
  select 26,
         'user_profile_details.birthday が 8 桁数字でない（NULL 化される）',
         'WARN',
         count(*),
         'user_profile_details.birthday → date'
    from user_profile_details
   where birthday is not null
     and birthday !~ '^[0-9]{8}$'

  union all
  -- 8桁でも実在しない日付（20250230 等）は to_date が翌月へ繰り上げるか、
  -- 月に 13 以上が入っていると date/time field value out of range で落ちる。
  -- どちらも許容できないため BLOCKED として扱う。
  -- 判定は文字列演算のみで行い、この検査自体が例外を出さないようにしている
  select 27,
         'user_profile_details.birthday が 8 桁だが実在しない日付',
         'BLOCKED',
         count(*),
         'user_profile_details.birthday → date（to_date で例外 or 日付がずれる）'
    from (
      select case
               when birthday ~ '^[0-9]{8}$' then
                 case
                   when substr(birthday, 5, 2) not between '01' and '12' then false
                   when substr(birthday, 7, 2)::int between 1 and
                        case substr(birthday, 5, 2)
                          when '02' then
                            case
                              when substr(birthday, 1, 4)::int % 4 = 0
                               and (substr(birthday, 1, 4)::int % 100 <> 0
                                    or substr(birthday, 1, 4)::int % 400 = 0)
                              then 29
                              else 28
                            end
                          when '04' then 30
                          when '06' then 30
                          when '09' then 30
                          when '11' then 30
                          else 31
                        end
                   then true
                   else false
                 end
               else null
             end as is_valid_date
        from user_profile_details
    ) t
   where t.is_valid_date is false

  union all
  select 28,
         'user_profile_details.sex が 0/1/2/3 以外',
         'BLOCKED',
         count(*),
         'user_profile_details_sex_check'
    from user_profile_details
   where sex is not null
     and sex not in (0, 1, 2, 3)
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
-- No.19 の該当行を実際に見る（是正対象の特定）
-- ----------------------------------------------------------------------------
-- select su.id, su.user_id, su.order_id, su.exchange_item_id,
--        su.point_used, su.created_at,
--        exists (select 1 from orders_archive oa where oa.order_id = su.order_id)
--          as exists_in_archive
--   from star_usage su
--  where su.order_id is not null
--    and not exists (
--          select 1 from orders o where o.order_id = su.order_id::varchar(32)
--        )
--  order by su.created_at;

-- ----------------------------------------------------------------------------
-- No.19 の是正例: アーカイブ済み注文を指す star_usage を退避してから削除する
-- （archive_old_orders の STEP 1-2 と同じことを、過去分に対して一度だけ行う）
--
-- ⚠ 実行前に必ずバックアップを取ること。DELETE を含む。
-- ----------------------------------------------------------------------------
-- begin;
--
-- insert into public.star_usage_archive (
--     id, user_id, order_id, exchange_item_id, point_used,
--     created_at, updated_at
-- )
-- select su.id, su.user_id, su.order_id, su.exchange_item_id, su.point_used,
--        su.created_at, su.updated_at
--   from public.star_usage su
--  where su.order_id is not null
--    and not exists (select 1 from public.orders o where o.order_id = su.order_id)
--    and exists (select 1 from public.orders_archive oa where oa.order_id = su.order_id)
-- on conflict (id) do nothing;
--
-- delete from public.star_usage su
--  where su.order_id is not null
--    and not exists (select 1 from public.orders o where o.order_id = su.order_id)
--    and exists (select 1 from public.orders_archive oa where oa.order_id = su.order_id);
--
-- -- 件数を確認してから commit / rollback を決める
-- -- commit;

-- ----------------------------------------------------------------------------
-- No.26 の該当値を確認する（どんな書式が混ざっているか）
-- ----------------------------------------------------------------------------
-- select birthday, count(*) as rows
--   from user_profile_details
--  where birthday is not null
--    and birthday !~ '^[0-9]{8}$'
--  group by birthday
--  order by rows desc;
