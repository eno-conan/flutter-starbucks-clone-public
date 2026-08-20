-- ============================================================================
-- DB設計レビュー (Issue #938) Step 3-3: 退会時の削除ポリシー (E-1)
--
-- auth.users を削除したときの挙動が ON DELETE CASCADE 4テーブルと
-- NO ACTION 11テーブルに割れており、退会機能を作った瞬間に
-- 「FK 違反でユーザーを削除できない」形で顕在化する状態だった。
--
-- 方針（Issue #938 で決定）:
--   個人設定・保有物  → ON DELETE CASCADE で一緒に消す
--   取引履歴          → 行は残し user_id を NULL にして匿名化する
--   集計値            → 元データから再計算できるので CASCADE
--
-- アプリ改修は不要（匿名化された行は RLS の user_id = auth.uid() に
-- 一致しなくなるため、ユーザー側の画面には出てこない）。
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. 個人設定・保有物: ON DELETE CASCADE
--
--    退会後に残しても意味がなく、残すと本人以外から参照されうるもの。
--    carts_detail は Step 2 で carts への CASCADE に張り替え済みのため、
--    carts が消えれば連鎖して消える。
--
--    star_aggregations だけは性質が違う（集計値）が、user_id が主キーの
--    構成列であるため NULL にできない。star_acquisitions / star_usage から
--    再計算できる派生データなので CASCADE で揃える。
-- ----------------------------------------------------------------------------
alter table "public"."cards" drop constraint "cards_user_id_fkey";
alter table "public"."cards"
  add constraint "cards_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."cards" validate constraint "cards_user_id_fkey";

alter table "public"."carts" drop constraint "carts_user_id_fkey";
alter table "public"."carts"
  add constraint "carts_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."carts" validate constraint "carts_user_id_fkey";

alter table "public"."user_fcm_tokens" drop constraint "user_fcm_tokens_user_id_fkey";
alter table "public"."user_fcm_tokens"
  add constraint "user_fcm_tokens_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."user_fcm_tokens" validate constraint "user_fcm_tokens_user_id_fkey";

alter table "public"."user_tickets" drop constraint "user_tickets_user_id_fkey";
alter table "public"."user_tickets"
  add constraint "user_tickets_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."user_tickets" validate constraint "user_tickets_user_id_fkey";

alter table "public"."store_profiles" drop constraint "store_profiles_user_id_fkey";
alter table "public"."store_profiles"
  add constraint "store_profiles_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."store_profiles" validate constraint "store_profiles_user_id_fkey";

alter table "public"."star_aggregations" drop constraint "star_aggregations_user_id_fkey";
alter table "public"."star_aggregations"
  add constraint "star_aggregations_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete cascade not valid;
alter table "public"."star_aggregations" validate constraint "star_aggregations_user_id_fkey";


-- ----------------------------------------------------------------------------
-- 2. 取引履歴: ON DELETE SET NULL（行は残して匿名化）
--
--    会計・売上分析のために行そのものは残す必要がある一方、
--    退会したユーザーの識別子を保持し続ける理由はない。
--
--    【Step 1 からの意図的な緩和】
--    Step 1 で orders_detail.user_id に NOT NULL を入れたのは
--    「孤児明細を作らせない」ためだった。ここで nullable に戻すが、
--    孤児明細の防止は order_id → orders の FK（NOT NULL のまま）が担う。
--    ヘッダが匿名化されたのに明細だけ user_id が残る、という
--    ちぐはぐな状態を避けるため、明細もヘッダと同じ扱いに揃える。
--
--    【作成時の NOT NULL 相当の担保】
--    列レベルの NOT NULL が外れるぶん「未認証で NULL のまま作られる」経路が
--    開くため、書き込み側の RPC で明示的に弾く（下の 3 を参照）。
--
--    ※ アーカイブ4テーブルは auth.users への FK を持たないため、この
--      SET NULL は伝播しない。退避済みデータの匿名化が必要になったら
--      退会処理側で別途 UPDATE する必要がある。
-- ----------------------------------------------------------------------------
alter table "public"."orders" alter column "user_id" drop not null;
alter table "public"."orders" drop constraint "orders_user_id_fkey";
alter table "public"."orders"
  add constraint "orders_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete set null not valid;
alter table "public"."orders" validate constraint "orders_user_id_fkey";

alter table "public"."orders_detail" alter column "user_id" drop not null;
alter table "public"."orders_detail" drop constraint "orders_detail_user_id_fkey";
alter table "public"."orders_detail"
  add constraint "orders_detail_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete set null not valid;
alter table "public"."orders_detail" validate constraint "orders_detail_user_id_fkey";

alter table "public"."star_acquisitions" alter column "user_id" drop not null;
alter table "public"."star_acquisitions" drop constraint "star_acquisitions_user_id_fkey";
alter table "public"."star_acquisitions"
  add constraint "star_acquisitions_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete set null not valid;
alter table "public"."star_acquisitions" validate constraint "star_acquisitions_user_id_fkey";

alter table "public"."star_usage" alter column "user_id" drop not null;
alter table "public"."star_usage" drop constraint "star_usage_user_id_fkey";
alter table "public"."star_usage"
  add constraint "star_usage_user_id_fkey"
  foreign key ("user_id") references auth.users(id) on delete set null not valid;
alter table "public"."star_usage" validate constraint "star_usage_user_id_fkey";

comment on column public.orders.user_id is 'ユーザーID';
comment on column public.orders_detail.user_id is 'ユーザーID';
comment on column public.star_acquisitions.user_id is 'ユーザーID';
comment on column public.star_usage.user_id is 'ユーザーID';


-- ----------------------------------------------------------------------------
-- 3. 書き込み側で user_id の欠落を弾く
--
--    2 で列レベルの NOT NULL を外したため、「退会による匿名化」ではなく
--    「未認証のまま作られた履歴」も NULL として通ってしまう。
--    SECURITY DEFINER の RPC は RLS を迂回するので、ここで明示的に落とす。
--
--    use_star_points は p_user_id が NULL だと保有ポイントの集計が 0 になり
--    「利用可能なポイントが不足しています」で先に落ちるため、追加の判定は要らない。
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_order_with_details(
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

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ユーザーが認証されていません';
  END IF;

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

CREATE OR REPLACE FUNCTION public.handle_star_acquisition(
  p_user_id uuid,
  p_order_id character varying,
  p_category smallint,
  p_acquired_points numeric
)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
    v_target_year_month char(6);
begin
    if p_user_id is null then
        raise exception 'ユーザーが認証されていません';
    end if;

    -- star_acquisitions にデータを登録
    insert into star_acquisitions (user_id, order_id, category, acquired_points)
    values (p_user_id, p_order_id, p_category, p_acquired_points);

    -- 取得年月を計算 (created_atの現在値をYYYYMM形式にする)
    v_target_year_month := to_char(now(), 'YYYYMM');

    -- star_aggregations にデータを追加または更新
    insert into star_aggregations (user_id, target_year_month, total_points)
    values (p_user_id, v_target_year_month, p_acquired_points)
    on conflict (user_id, target_year_month)
    do update set total_points = star_aggregations.total_points + excluded.total_points,
                  updated_at = now();

    -- 成功時のレスポンスを返す
    return jsonb_build_object('status', 'success', 'message', '');

exception
    when others then
        -- エラー時のレスポンスを返す
        return jsonb_build_object('status', 'error', 'message', sqlerrm);
end;
$function$
;
