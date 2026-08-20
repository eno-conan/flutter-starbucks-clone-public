-- ============================================================================
-- DB設計レビュー (Issue #938) Step 3-2: 注文の履歴スナップショット (D-1 / D-2 / D-3)
--
-- 注文は「確定した事実」であり、マスタの改定で過去が書き換わってはいけない。
-- 現状の orders_detail は subtotal_without_tax しか持たず、単価も商品名も
-- products / product_sizes への参照でしか再現できないため、
--   - 価格改定 → 過去注文の単価が再現できない
--   - 商品名の変更 → 過去の注文履歴の表示が変わる
--   - products.is_active = false → 過去注文の表示が壊れうる
-- という状態だった。意図的な非正規化でスナップショットを持たせる。
--
-- 本マイグレーションは**アプリ改修を伴う**（Dart 側で税率を渡す）。
-- 適用前チェック: supabase_schema/supabase/snippets/preflight_step3.sql
-- ============================================================================


-- ============================================================================
-- 1. 注文明細のスナップショット列 (D-1)
--
--    unit_price_without_tax は「その時点の master 価格」ではなく
--    「実際に請求した単価」を正とする。既存行は subtotal / count で復元する
--    （アプリは常に 単価 × 数量 で subtotal を組み立てているため一致する）。
--    product_name は移行時点の products.product_name を採用する。
--    それ以前の商品名改定は復元できないが、以降は固定される。
-- ============================================================================
alter table "public"."orders_detail" add column "product_name" text;
alter table "public"."orders_detail" add column "unit_price_without_tax" integer;

update "public"."orders_detail" od
   set "product_name" = p."product_name"
  from "public"."products" p
 where p."product_id" = od."product_id"
   and od."product_name" is null;

update "public"."orders_detail"
   set "unit_price_without_tax" = "subtotal_without_tax" / "count"
 where "unit_price_without_tax" is null;

alter table "public"."orders_detail" alter column "product_name" set not null;
alter table "public"."orders_detail" alter column "unit_price_without_tax" set not null;

-- 単価と小計の整合を DB 側で固定する。
-- ※ 明細単位の値引き（1行の中で単価×数量にならない請求）を導入するときは、
--   値引き額を持つ列を足したうえでこの制約を見直すこと。
alter table "public"."orders_detail"
  add constraint "orders_detail_subtotal_matches_unit_price"
  check ((subtotal_without_tax = (unit_price_without_tax * count))) not valid;
alter table "public"."orders_detail" validate constraint "orders_detail_subtotal_matches_unit_price";

alter table "public"."orders_detail"
  add constraint "orders_detail_unit_price_non_negative"
  check ((unit_price_without_tax >= 0)) not valid;
alter table "public"."orders_detail" validate constraint "orders_detail_unit_price_non_negative";

comment on column public.orders_detail.product_name is '商品名';
comment on column public.orders_detail.unit_price_without_tax is '税抜単価';

-- アーカイブ側も同じ列を持たせる（G-5 の型ドリフトを増やさない）
alter table "public"."orders_detail_archive" add column "product_name" text;
alter table "public"."orders_detail_archive" add column "unit_price_without_tax" integer;

update "public"."orders_detail_archive" oda
   set "product_name" = p."product_name"
  from "public"."products" p
 where p."product_id" = oda."product_id"
   and oda."product_name" is null;

update "public"."orders_detail_archive"
   set "unit_price_without_tax" = "subtotal_without_tax" / "count"
 where "unit_price_without_tax" is null
   and "count" > 0;

comment on column public.orders_detail_archive.product_name is '商品名';
comment on column public.orders_detail_archive.unit_price_without_tax is '税抜単価';


-- ============================================================================
-- 2. 注文の税率 (D-2)
--
--    これまで税額は price_with_tax - price_without_tax の差分でしか出せず、
--    税率改定をまたぐと過去注文の税率・税額を再計算できなかった。
--    アプリ側は利用区分（店内 8% / 持ち帰り 10%）から整数の税率を決めているので、
--    同じ整数パーセントで保存する。
--
--    既存行は差分から復元する。price_without_tax = 0 の注文（全額ポイント利用等）は
--    税率を復元できないため 0 とする。
-- ============================================================================
alter table "public"."orders" add column "tax_rate" smallint;

update "public"."orders"
   set "tax_rate" = case
         when "price_without_tax" > 0
           then round((100.0 * ("price_with_tax" - "price_without_tax")) / "price_without_tax")
         else 0
       end
 where "tax_rate" is null;

alter table "public"."orders" alter column "tax_rate" set not null;

alter table "public"."orders"
  add constraint "orders_tax_rate_range" check (((tax_rate >= 0) and (tax_rate <= 100))) not valid;
alter table "public"."orders" validate constraint "orders_tax_rate_range";

comment on column public.orders.tax_rate is '消費税率';

alter table "public"."orders_archive" add column "tax_rate" smallint;

update "public"."orders_archive"
   set "tax_rate" = case
         when "price_without_tax" > 0
           then round((100.0 * ("price_with_tax" - "price_without_tax")) / "price_without_tax")
         else 0
       end
 where "tax_rate" is null;

alter table "public"."orders_archive" alter column "tax_rate" set not null;

comment on column public.orders_archive.tax_rate is '消費税率';


-- ============================================================================
-- 3. ヘッダ合計と明細合計の整合について明記 (D-3)
--
--    orders.price_* と orders_detail.subtotal_without_tax の合計は独立して
--    保持されており、DB 側では一致が保証されていない。
--    実際には create_order_with_details が両方を1トランザクションで書いているので、
--    その前提をスキーマ自身に残す（後から直接 INSERT する経路を作らせないため）。
-- ============================================================================
comment on table public.orders is
  '注文。price_without_tax / price_with_tax は orders_detail の小計合計と一致する前提で、create_order_with_details が同一トランザクションで書き込む。この RPC を経由しない直接 INSERT はヘッダと明細の整合を壊すため使わないこと (Issue #938 D-3)';

comment on table public.orders_detail is
  '注文明細。product_name / unit_price_without_tax は注文時点のスナップショットであり、products / product_sizes の改定で書き換えてはならない (Issue #938 D-1)';


-- ============================================================================
-- 4. create_order_with_details をスナップショット対応にする
--
--    - p_tax_rate を追加。旧クライアントからの9引数呼び出しでも動くよう
--      DEFAULT NULL とし、NULL のときは税抜・税込の差分から復元する。
--    - 明細は unit_price_without_tax（クライアントが持っている単価）を優先し、
--      無ければ subtotal / count で補う。
--    - product_name はクライアントの文字列を信用せず products から引く。
--
--    ※ 引数を増やすため CREATE OR REPLACE では置き換えられない。
--      同時に、20260221140000 が誤ったシグネチャ（p_store_id character）で作った
--      重複オーバーロードもここで落とす。こちらは実在しない列
--      （store_id / eat_in_takeout）に INSERT しており、呼ばれれば必ず失敗する
--      死んだ定義だった。SET search_path はその移行の本来の目的なので引き継ぐ。
-- ============================================================================
drop function if exists public.create_order_with_details(character varying, character varying, smallint, smallint, character varying, integer, integer, character varying, jsonb);
drop function if exists public.create_order_with_details(character varying, character, smallint, smallint, character varying, integer, integer, character varying, jsonb);

CREATE FUNCTION public.create_order_with_details(
  p_order_id character varying,
  p_store_number character varying,
  p_usage smallint,
  p_order_type smallint,
  p_pickup_number character varying,
  p_price_without_tax integer,
  p_price_with_tax integer,
  p_payment_method character varying,
  p_order_details jsonb,
  p_tax_rate smallint DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id      UUID;
  v_order_result JSONB;
  v_detail       JSONB;
  v_tax_rate     SMALLINT;
  v_count        INTEGER;
  v_subtotal     INTEGER;
  v_unit_price   INTEGER;
BEGIN
  v_user_id := auth.uid();

  v_tax_rate := COALESCE(
    p_tax_rate,
    CASE
      WHEN p_price_without_tax > 0
        THEN round((100.0 * (p_price_with_tax - p_price_without_tax)) / p_price_without_tax)::SMALLINT
      ELSE 0::SMALLINT
    END
  );

  INSERT INTO orders (
    order_id, user_id, store_number, usage, order_type,
    pickup_number, price_without_tax, price_with_tax, tax_rate, payment_method
  ) VALUES (
    p_order_id, v_user_id, p_store_number, p_usage, p_order_type,
    p_pickup_number, p_price_without_tax, p_price_with_tax, v_tax_rate, p_payment_method
  )
  RETURNING to_jsonb(orders.*) INTO v_order_result;

  FOR v_detail IN SELECT * FROM jsonb_array_elements(p_order_details)
  LOOP
    v_count    := (v_detail->>'count')::INTEGER;
    v_subtotal := (v_detail->>'subtotal_without_tax')::INTEGER;
    v_unit_price := COALESCE((v_detail->>'unit_price_without_tax')::INTEGER, v_subtotal / v_count);

    INSERT INTO orders_detail (
      order_id, user_id, product_id, temperature_type_id, size_id,
      count, subtotal_without_tax, product_name, unit_price_without_tax
    ) VALUES (
      p_order_id,
      v_user_id,
      (v_detail->>'product_id')::INTEGER,
      (v_detail->>'temperature_type_id')::INTEGER,
      (v_detail->>'size_id')::INTEGER,
      v_count,
      v_subtotal,
      (SELECT p.product_name FROM products p WHERE p.product_id = (v_detail->>'product_id')::INTEGER),
      v_unit_price
    );
  END LOOP;

  RETURN jsonb_build_object('success', true, 'order', v_order_result);
END;
$function$
;


-- ============================================================================
-- 5. 履歴参照 RPC をスナップショット基準に切り替える
--
--    products への JOIN をやめることで、商品名の改定・非公開化
--    （products.is_active = false）が過去の注文表示に波及しなくなる。
-- ============================================================================

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
            o.tax_rate,
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
            od.product_id,
            od.product_name,
            od.size_id,
            sz.size_name,
            tt.temperature_type_id,
            tt.type_name,
            od.count,
            od.unit_price_without_tax,
            od.subtotal_without_tax
        FROM
            orders_detail od
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
                'tax_rate', uo.tax_rate,
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
                            'unit_price_without_tax', items.unit_price_without_tax,
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

CREATE OR REPLACE FUNCTION public.get_store_order_list(p_user_id uuid)
 RETURNS TABLE(
   order_id character varying, store_number character varying, store_name character varying,
   eat_in_takeout character varying, pickup_number character varying, detail_id uuid,
   product_name character varying, temperature_type character varying,
   size_name character varying, count integer
 )
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT
  o.order_id::VARCHAR,
  o.store_number::VARCHAR,
  st.store_name::VARCHAR,
  o.usage::VARCHAR,
  o.pickup_number::VARCHAR,
  od.id::UUID,
  od.product_name::VARCHAR,
  tt.type_name::VARCHAR AS temperature_type,
  s.size_name::VARCHAR,
  od.count::INTEGER
FROM orders o
JOIN orders_detail od ON o.order_id = od.order_id
JOIN store_profiles sp ON o.store_number = sp.store_number
JOIN temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
JOIN sizes s ON od.size_id = s.size_id
JOIN stores st ON o.store_number = st.store_number
WHERE sp.user_id = p_user_id;
$function$
;


-- ============================================================================
-- 6. archive_old_orders に新しい列を引き継がせる
--    （引き継がないとアーカイブ時点でスナップショットが失われる）
-- ============================================================================
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
            count, unit_price_without_tax, subtotal_without_tax, product_name
        )
        SELECT
            od.id, od.order_id::text, od.user_id, od.product_id,
            od.temperature_type_id, od.size_id, od.count,
            od.unit_price_without_tax, od.subtotal_without_tax, od.product_name
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
            pickup_number, price_without_tax, price_with_tax, tax_rate,
            payment_method, provided_status, created_at, updated_at
        )
        SELECT
            o.id, o.order_id, o.user_id, o.store_number, o.usage, o.order_type,
            o.pickup_number, o.price_without_tax, o.price_with_tax, o.tax_rate,
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
