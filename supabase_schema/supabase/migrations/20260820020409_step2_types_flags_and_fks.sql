-- ============================================================================
-- DB設計レビュー (Issue #938) Step 2: 型・フラグ表現の統一と参照整合性の回復
--
-- Step 1 と違い、本マイグレーションは**アプリ側の改修を伴う**。
-- 対応する Dart の変更と必ずセットで適用すること。
--
-- 適用前チェック: supabase_schema/supabase/snippets/preflight_step2.sql
-- ============================================================================


-- ============================================================================
-- 1. orders.provided_status を enum 型へ (B-2)
--
--    数値の意味を text で持っていたため、ソート・比較が文字列順になっていた。
--    さらにアプリ側では int ('.eq(provided_status, 0)') と
--    String ('.update({provided_status: "1"})') が混在しており、
--    どちらが正しいのか型から判断できなかった。
--
--    products.sale_type が既に sale_type_enum を使っているため、その流儀に揃える。
--    orders_archive も同じ型にすることで archive_old_orders の
--    INSERT ... SELECT がキャストなしで通る（レビュー G-5 の型ドリフト解消も兼ねる）。
-- ============================================================================

create type public.provided_status_enum as enum (
  'pending',    -- 未受付   (旧 '0')
  'preparing',  -- 調理中   (旧 '1')
  'provided',   -- 提供済   (旧 '2')
  'cancelled'   -- キャンセル (旧 '99')
);

comment on type public.provided_status_enum is '注文の提供ステータス。旧 text 値 0/1/2/99 に対応する';

-- orders
alter table "public"."orders" drop constraint "orders_provided_status_check";
alter table "public"."orders" alter column "provided_status" drop default;

alter table "public"."orders"
  alter column "provided_status" type public.provided_status_enum
  using (
    case "provided_status"
      when '0'  then 'pending'
      when '1'  then 'preparing'
      when '2'  then 'provided'
      when '99' then 'cancelled'
    end
  )::public.provided_status_enum;

alter table "public"."orders" alter column "provided_status" set default 'pending';

-- orders_archive（退避先も同じ型に揃える）
alter table "public"."orders_archive" alter column "provided_status" drop default;

alter table "public"."orders_archive"
  alter column "provided_status" type public.provided_status_enum
  using (
    case "provided_status"
      when '0'  then 'pending'
      when '1'  then 'preparing'
      when '2'  then 'provided'
      when '99' then 'cancelled'
    end
  )::public.provided_status_enum;

alter table "public"."orders_archive" alter column "provided_status" set default 'pending';


-- ----------------------------------------------------------------------------
-- 1-2. provided_status を参照する RPC を enum 値に追従させる
--      （text 比較のままだと enum への invalid input で実行時エラーになる）
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_user_orders(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$DECLARE
    result json;
BEGIN
    WITH user_orders AS (
        SELECT
            o.order_id,
            o.usage,
            o.created_at,
            s.store_number,
            s.store_name,
            s.address,
            o.price_without_tax,
            o.price_with_tax,
            o.payment_method,
            o.pickup_number
        FROM
            orders o
        JOIN
            stores s ON o.store_number = s.store_number
        WHERE
            o.user_id = p_user_id
            AND o.provided_status IN ('pending', 'preparing')
            AND o.created_at >= CURRENT_DATE - INTERVAL '1 month'
        ORDER BY
            o.created_at DESC
    ),
    order_items AS (
        SELECT
            od.order_id,
            p.product_id,
            p.product_name,
            od.size_id,
            sz.size_name,
            tt.temperature_type_id,
            tt.type_name,
            od.count,
            od.subtotal_without_tax
        FROM
            orders_detail od
        JOIN
            products p ON od.product_id = p.product_id
        LEFT JOIN
            sizes sz ON od.size_id = sz.size_id
        LEFT JOIN
            temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
        WHERE
            od.user_id = p_user_id
    )
    SELECT
        json_agg(
            json_build_object(
                'order_id', uo.order_id,
                'usage', uo.usage,
                'created_at', uo.created_at,
                'store_number', uo.store_number,
                'store_name', uo.store_name,
                'store_address', uo.address,
                'price_without_tax', uo.price_without_tax,
                'price_with_tax', uo.price_with_tax,
                'payment_method', uo.payment_method,
                'pickup_number', uo.pickup_number,
                'items', (
                    SELECT json_agg(
                        json_build_object(
                            'product_id', items.product_id,
                            'product_name', items.product_name,
                            'size_id', items.size_id,
                            'size_name', items.size_name,
                            'temperature_type_id', items.temperature_type_id,
                            'temperature_type_name', items.type_name,
                            'count', items.count,
                            'subtotal_without_tax', items.subtotal_without_tax
                        )
                    )
                    FROM order_items items
                    WHERE items.order_id = uo.order_id
                )
            )
            ORDER BY uo.created_at DESC
        ) INTO result
    FROM
        user_orders uo;

    IF result IS NULL THEN
        result := '[]'::json;
    END IF;

    RETURN result;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_store_wait_times(p_date date)
 RETURNS TABLE(store_number text, total_staff integer, cooking_staff integer, preparing_items integer, is_open boolean)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  WITH current_period AS (
      SELECT CASE
          WHEN (NOW() AT TIME ZONE 'Asia/Tokyo')::time BETWEEN '07:00' AND '11:00' THEN 'period_1'
          WHEN (NOW() AT TIME ZONE 'Asia/Tokyo')::time BETWEEN '10:00' AND '14:00' THEN 'period_2'
          WHEN (NOW() AT TIME ZONE 'Asia/Tokyo')::time BETWEEN '13:00' AND '17:00' THEN 'period_3'
          WHEN (NOW() AT TIME ZONE 'Asia/Tokyo')::time BETWEEN '16:00' AND '20:00' THEN 'period_4'
          WHEN (NOW() AT TIME ZONE 'Asia/Tokyo')::time BETWEEN '19:00' AND '23:00' THEN 'period_5'
          ELSE NULL
      END AS period_name
  ),
  staff_counts AS (
      SELECT
          s.store_number,
          CASE WHEN cp.period_name IS NULL THEN 0 ELSE COUNT(*) END AS total_staff,
          CASE WHEN cp.period_name IS NULL THEN 0 ELSE GREATEST(COUNT(*) - 1, 0) END AS cooking_staff
      FROM staff_schedules s
      INNER JOIN staff st ON s.staff_number = st.staff_number
      CROSS JOIN current_period cp
      WHERE s.date = p_date
        AND (
            (cp.period_name = 'period_1' AND s.period_1 = true) OR
            (cp.period_name = 'period_2' AND s.period_2 = true) OR
            (cp.period_name = 'period_3' AND s.period_3 = true) OR
            (cp.period_name = 'period_4' AND s.period_4 = true) OR
            (cp.period_name = 'period_5' AND s.period_5 = true) OR
            cp.period_name IS NULL
        )
      GROUP BY s.store_number, cp.period_name
  ),
  preparing_items AS (
      SELECT
          o.store_number,
          COALESCE(SUM(od.count), 0) AS total_items
      FROM orders o
      INNER JOIN orders_detail od ON o.order_id = od.order_id
      WHERE o.provided_status = 'pending'
      GROUP BY o.store_number
  )
  SELECT
      sc.store_number::text,
      sc.total_staff,
      sc.cooking_staff,
      COALESCE(pi.total_items, 0)::integer AS preparing_items,
      (SELECT period_name FROM current_period) IS NOT NULL AS is_open
  FROM staff_counts sc
  LEFT JOIN preparing_items pi ON sc.store_number = pi.store_number;
$function$
;


-- ============================================================================
-- 2. 真偽値表現の boolean 統一 (B-1)
--
--    同じ「真偽」を integer / smallint / bpchar(1) の3通りで表現しており、
--    アプリ側に3通りの変換コードが必要になっていた。
--
--    特に stores.is_drive_thru_available は bpchar(1) のため RPC が
--    character を返し、Dart 側の `data['is_drive_thru_available'] == 1`
--    （int 比較）が常に false になっていた。boolean 化でこの不具合も解消する。
-- ============================================================================

-- cards.is_main
--   Step 1 で作った部分ユニークインデックスが is_main = 1 を参照しているため、
--   先に落としてから型を変え、boolean 版で作り直す
drop index if exists "public"."cards_user_id_is_main_key";

alter table "public"."cards" alter column "is_main" drop default;
alter table "public"."cards"
  alter column "is_main" type boolean using ("is_main" <> 0);
alter table "public"."cards" alter column "is_main" set default false;
alter table "public"."cards" alter column "is_main" set not null;

create unique index cards_user_id_is_main_key
  on public.cards using btree (user_id)
  where ("is_main");

-- user_fcm_tokens.is_notify
alter table "public"."user_fcm_tokens" alter column "is_notify" drop default;
alter table "public"."user_fcm_tokens"
  alter column "is_notify" type boolean using ("is_notify" <> 0);
alter table "public"."user_fcm_tokens" alter column "is_notify" set default false;

-- user_mail_settings の3列
alter table "public"."user_mail_settings" alter column "is_send_related_rewards" drop default;
alter table "public"."user_mail_settings"
  alter column "is_send_related_rewards" type boolean using ("is_send_related_rewards" <> 0);
alter table "public"."user_mail_settings" alter column "is_send_related_rewards" set default false;

alter table "public"."user_mail_settings" alter column "is_send_advance_product_announce" drop default;
alter table "public"."user_mail_settings"
  alter column "is_send_advance_product_announce" type boolean using ("is_send_advance_product_announce" <> 0);
alter table "public"."user_mail_settings" alter column "is_send_advance_product_announce" set default false;

alter table "public"."user_mail_settings" alter column "is_html_mail" drop default;
alter table "public"."user_mail_settings"
  alter column "is_html_mail" type boolean using ("is_html_mail" <> 0);
alter table "public"."user_mail_settings" alter column "is_html_mail" set default true;

-- star_aggregations.expiration_flag
--   列名は据え置く（改名すると RPC 名 get_total_points_with_expiration_flag_zero や
--   定義書の論理名まで巻き込むため、型の統一だけを目的とする）
alter table "public"."star_aggregations" alter column "expiration_flag" drop default;
alter table "public"."star_aggregations"
  alter column "expiration_flag" type boolean using ("expiration_flag" <> 0);
alter table "public"."star_aggregations" alter column "expiration_flag" set default false;

CREATE OR REPLACE FUNCTION public.get_total_points_with_expiration_flag_zero()
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN (SELECT COALESCE(SUM(total_points), 0) FROM star_aggregations WHERE expiration_flag = false);
END;
$function$
;

-- stores.is_drive_thru_available
alter table "public"."stores" drop constraint "stores_is_drive_thru_available_check";
alter table "public"."stores" alter column "is_drive_thru_available" drop default;
alter table "public"."stores"
  alter column "is_drive_thru_available" type boolean using ("is_drive_thru_available" = '1');
alter table "public"."stores" alter column "is_drive_thru_available" set default false;

-- 戻り値の型（is_drive_thru_available: character → boolean）が変わるため、
-- CREATE OR REPLACE では置き換えられない。先に DROP する
drop function if exists public.get_select_store_drive_thru_status(uuid);

CREATE FUNCTION public.get_select_store_drive_thru_status(p_user_id uuid)
 RETURNS TABLE(store_number character, is_drive_thru_available boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT s.store_number, s.is_drive_thru_available
  FROM public.stores s
  JOIN public.carts c ON c.store_number = s.store_number
  WHERE c.user_id = p_user_id;
END;
$function$
;


-- ============================================================================
-- 3. 参照整合性の回復 (A-2 / A-3 / A-6)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3-1. carts_detail → carts (A-2)
--      これまで auth.users を直接参照していたため、カートヘッダが無いのに
--      明細だけ存在でき、carts の行を消しても明細が残っていた。
--      carts.user_id 自体が auth.users を参照しているので、
--      auth.users への直接 FK は冗長。張り替える。
-- ----------------------------------------------------------------------------
alter table "public"."carts_detail" drop constraint "carts_detail_user_id_fkey";

alter table "public"."carts_detail"
  add constraint "carts_detail_user_id_fkey"
  foreign key ("user_id") references public.carts(user_id) on delete cascade not valid;
alter table "public"."carts_detail" validate constraint "carts_detail_user_id_fkey";

-- ----------------------------------------------------------------------------
-- 3-2. star_usage → orders (A-3)
--      order_id が text かつ FK 無しで、さらに exchange_item_id も NULL 可だったため
--      「注文にも交換商品にも紐づかないポイント消費」が作成できた。
--      型を orders.order_id と揃え、FK と「どちらか必須」の CHECK を入れる。
-- ----------------------------------------------------------------------------
alter table "public"."star_usage"
  alter column "order_id" type character varying(32) using "order_id"::character varying(32);

alter table "public"."star_usage"
  add constraint "star_usage_order_id_fkey"
  foreign key ("order_id") references public.orders(order_id) not valid;
alter table "public"."star_usage" validate constraint "star_usage_order_id_fkey";

alter table "public"."star_usage"
  add constraint "star_usage_reference_required"
  check ((order_id is not null) or (exchange_item_id is not null)) not valid;
alter table "public"."star_usage" validate constraint "star_usage_reference_required";

-- star_usage_archive も型を揃える（退避時のキャストを不要にする）
alter table "public"."star_usage_archive"
  alter column "order_id" type character varying(32) using "order_id"::character varying(32);

-- ----------------------------------------------------------------------------
-- 3-3. archive_old_orders を star_usage に対応させる
--
--      【重要】3-2 で star_usage.order_id に FK を張ったため、
--      archive_old_orders の DELETE FROM orders が star_usage から参照されている
--      注文で失敗するようになる。star_usage を退避するのは別関数
--      archive_old_star_usage であり、実行順序が保証されないため。
--
--      既に star_acquisitions が「ordersへのFK参照があるため先に処理」として
--      同じ扱いを受けているので、star_usage も同じパターンに揃える。
--      これにより star_usage 行は「自身の created_at」ではなく
--      「参照先の注文の古さ」でも退避されうるが、これは star_acquisitions の
--      既存挙動と同じである。
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.archive_old_orders(p_retention_months integer DEFAULT 18)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_cutoff_date            timestamp with time zone;
    v_archived_orders        integer := 0;
    v_archived_details       integer := 0;
    v_archived_acquisitions  integer := 0;
    v_archived_usages        integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_retention_months || ' months')::interval;

    -- STEP 1: star_acquisitions をアーカイブ（ordersへのFK参照があるため先に処理）
    WITH moved AS (
        INSERT INTO public.star_acquisitions_archive (
            id, user_id, order_id, category, acquired_points,
            created_at, updated_at
        )
        SELECT
            sa.id, sa.user_id, sa.order_id::text, sa.category, sa.acquired_points,
            sa.created_at, sa.updated_at
        FROM public.star_acquisitions sa
        WHERE sa.order_id IN (
            SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
        )
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT count(*) INTO v_archived_acquisitions FROM moved;

    DELETE FROM public.star_acquisitions
    WHERE order_id IN (
        SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
    );

    -- STEP 1-2: star_usage をアーカイブ（同じくordersへのFK参照があるため先に処理）
    WITH moved AS (
        INSERT INTO public.star_usage_archive (
            id, user_id, order_id, exchange_item_id, point_used,
            created_at, updated_at
        )
        SELECT
            su.id, su.user_id, su.order_id, su.exchange_item_id, su.point_used,
            su.created_at, su.updated_at
        FROM public.star_usage su
        WHERE su.order_id IN (
            SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
        )
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT count(*) INTO v_archived_usages FROM moved;

    DELETE FROM public.star_usage
    WHERE order_id IN (
        SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
    );

    -- STEP 2: orders_detail をアーカイブ
    WITH moved AS (
        INSERT INTO public.orders_detail_archive (
            id, order_id, user_id, product_id, temperature_type_id, size_id,
            count, subtotal_without_tax
        )
        SELECT
            od.id, od.order_id::text, od.user_id, od.product_id,
            od.temperature_type_id, od.size_id, od.count, od.subtotal_without_tax
        FROM public.orders_detail od
        WHERE od.order_id IN (
            SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
        )
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT count(*) INTO v_archived_details FROM moved;

    DELETE FROM public.orders_detail
    WHERE order_id IN (
        SELECT order_id FROM public.orders WHERE created_at < v_cutoff_date
    );

    -- STEP 3: orders をアーカイブ
    WITH moved AS (
        INSERT INTO public.orders_archive (
            id, order_id, user_id, store_number, usage, order_type,
            pickup_number, price_without_tax, price_with_tax,
            payment_method, provided_status, created_at, updated_at
        )
        SELECT
            o.id, o.order_id, o.user_id, o.store_number, o.usage, o.order_type,
            o.pickup_number, o.price_without_tax, o.price_with_tax,
            o.payment_method, o.provided_status, o.created_at, o.updated_at
        FROM public.orders o
        WHERE o.created_at < v_cutoff_date
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT count(*) INTO v_archived_orders FROM moved;

    DELETE FROM public.orders WHERE created_at < v_cutoff_date;

    RETURN jsonb_build_object(
        'cutoff_date',             v_cutoff_date,
        'archived_orders',         v_archived_orders,
        'archived_details',        v_archived_details,
        'archived_acquisitions',   v_archived_acquisitions,
        'archived_usages',         v_archived_usages
    );
END;
$function$
;

-- ----------------------------------------------------------------------------
-- 3-4. staff_schedules.store_number → stores (A-6)
--      stores.store_number は bpchar(4) なのに varchar(50) で保持しており、
--      FK も無かったため店舗別の join が保証されていなかった。
-- ----------------------------------------------------------------------------
alter table "public"."staff_schedules"
  alter column "store_number" type character(4) using "store_number"::character(4);

alter table "public"."staff_schedules"
  add constraint "staff_schedules_store_number_fkey"
  foreign key ("store_number") references public.stores(store_number) not valid;
alter table "public"."staff_schedules" validate constraint "staff_schedules_store_number_fkey";

create index if not exists idx_staff_schedules_store_number
  on public.staff_schedules using btree (store_number);


-- ============================================================================
-- 4. user_profile_details.birthday を date へ (B-4)
--
--    アプリは 'YYYYMMDD' の8桁文字列で保存している。text のままでは
--    誕生月限定チケット (e_tickets_promotions.is_birthday_month_only) の
--    判定が入力フォーマット依存になり、インデックスも効かない。
--
--    8桁数字として解釈できない値は NULL に落とす（birthday は元々 NULL 可）。
--    該当データの有無は preflight_step2.sql の No.7 で事前に確認すること。
-- ============================================================================
alter table "public"."user_profile_details"
  alter column "birthday" type date
  using (
    case
      when "birthday" ~ '^[0-9]{8}$' then to_date("birthday", 'YYYYMMDD')
      else null
    end
  );

-- 性別コードに値域を与える（0:未選択 / 1:男性 / 2:女性 / 3:その他）
alter table "public"."user_profile_details"
  add constraint "user_profile_details_sex_check"
  check ((sex is null) or (sex = any (array[0, 1, 2, 3]))) not valid;
alter table "public"."user_profile_details" validate constraint "user_profile_details_sex_check";
