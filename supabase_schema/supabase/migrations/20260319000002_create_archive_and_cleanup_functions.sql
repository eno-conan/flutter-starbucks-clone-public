-- Issue#544: データアーカイブ戦略 - アーカイブ・クリーンアップ関数の作成
-- SECURITY DEFINER で実行し、pg_cron から service_role として呼び出す

set check_function_bodies = off;

-- ----------------------------------------------------------------
-- 1. archive_old_orders
--    保持期間（デフォルト18ヶ月）を超えたorders/orders_detail/star_acquisitionsをアーカイブ
--    削除順序: star_acquisitions → orders_detail → orders (FK依存関係を考慮)
--    戻り値: { cutoff_date, archived_orders, archived_details, archived_acquisitions }
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.archive_old_orders(
    p_retention_months integer DEFAULT 18
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date            timestamp with time zone;
    v_archived_orders        integer := 0;
    v_archived_details       integer := 0;
    v_archived_acquisitions  integer := 0;
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

    -- STEP 2: orders_detail をアーカイブ（同じくordersへのFK参照があるため先に処理）
    WITH moved AS (
        INSERT INTO public.orders_detail_archive (
            id, order_id, user_id, product_id, temperature_type_id,
            size_id, count, subtotal_without_tax
        )
        SELECT
            od.id, od.order_id::text, od.user_id, od.product_id, od.temperature_type_id,
            od.size_id, od.count, od.subtotal_without_tax
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
        'archived_acquisitions',   v_archived_acquisitions
    );
END;
$$;

-- ----------------------------------------------------------------
-- 2. archive_old_star_usage
--    保持期間（デフォルト18ヶ月）を超えたstar_usageをアーカイブ
--    star_usageはordersへのFK参照がないため独立して処理可能
--    戻り値: { cutoff_date, archived_count }
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.archive_old_star_usage(
    p_retention_months integer DEFAULT 18
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date    timestamp with time zone;
    v_archived_count integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_retention_months || ' months')::interval;

    WITH moved AS (
        INSERT INTO public.star_usage_archive (
            id, user_id, order_id, exchange_item_id, point_used,
            created_at, updated_at
        )
        SELECT
            su.id, su.user_id, su.order_id, su.exchange_item_id, su.point_used,
            su.created_at, su.updated_at
        FROM public.star_usage su
        WHERE su.created_at < v_cutoff_date
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT count(*) INTO v_archived_count FROM moved;

    DELETE FROM public.star_usage WHERE created_at < v_cutoff_date;

    RETURN jsonb_build_object(
        'cutoff_date',    v_cutoff_date,
        'archived_count', v_archived_count
    );
END;
$$;

-- ----------------------------------------------------------------
-- 3. cleanup_expired_user_tickets
--    有効期限切れから猶予期間（デフォルト3ヶ月）を超えたuser_ticketsを削除
--    マーケティング価値が低いため削除のみ（アーカイブなし）
--    戻り値: { cutoff_date, deleted_count }
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_expired_user_tickets(
    p_grace_months integer DEFAULT 3
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date   timestamp with time zone;
    v_deleted_count integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_grace_months || ' months')::interval;

    WITH deleted AS (
        DELETE FROM public.user_tickets
        WHERE expired_at < v_cutoff_date
        RETURNING id
    )
    SELECT count(*) INTO v_deleted_count FROM deleted;

    RETURN jsonb_build_object(
        'cutoff_date',   v_cutoff_date,
        'deleted_count', v_deleted_count
    );
END;
$$;

-- ----------------------------------------------------------------
-- 4. cleanup_abandoned_carts
--    最終更新から保持期間（デフォルト30日）を超えた未決済カートを削除
--    削除順序: carts_detail → carts (参照整合性を考慮)
--    戻り値: { cutoff_date, deleted_carts, deleted_details }
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_abandoned_carts(
    p_retention_days integer DEFAULT 30
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date     timestamp with time zone;
    v_deleted_carts   integer := 0;
    v_deleted_details integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_retention_days || ' days')::interval;

    -- STEP 1: carts_detail を先に削除
    WITH deleted AS (
        DELETE FROM public.carts_detail
        WHERE user_id IN (
            SELECT user_id FROM public.carts WHERE updated_at < v_cutoff_date
        )
        RETURNING user_id
    )
    SELECT count(*) INTO v_deleted_details FROM deleted;

    -- STEP 2: carts を削除
    WITH deleted AS (
        DELETE FROM public.carts
        WHERE updated_at < v_cutoff_date
        RETURNING user_id
    )
    SELECT count(*) INTO v_deleted_carts FROM deleted;

    RETURN jsonb_build_object(
        'cutoff_date',     v_cutoff_date,
        'deleted_carts',   v_deleted_carts,
        'deleted_details', v_deleted_details
    );
END;
$$;

-- ----------------------------------------------------------------
-- GRANT: service_role からの呼び出しを明示的に許可
-- pg_cron スケジュール実行・SQL Editor からの手動即時実行の両方で使用可能
-- ----------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.archive_old_orders(integer)          TO service_role;
GRANT EXECUTE ON FUNCTION public.archive_old_star_usage(integer)      TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_user_tickets(integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_abandoned_carts(integer)     TO service_role;

-- ----------------------------------------------------------------
-- 手動即時実行例（Supabase Dashboard > SQL Editor で実行）
--
-- 通常実行（保持期間18ヶ月）:
--   SELECT public.archive_old_orders(18);
--   SELECT public.archive_old_star_usage(18);
--   SELECT public.cleanup_expired_user_tickets(3);
--   SELECT public.cleanup_abandoned_carts(30);
--
-- 動作確認用（保持期間0ヶ月 = 全データを即時アーカイブ/削除）:
--   SELECT public.archive_old_orders(0);
--   SELECT public.archive_old_star_usage(0);
--   SELECT public.cleanup_expired_user_tickets(0);
--   SELECT public.cleanup_abandoned_carts(0);
-- ----------------------------------------------------------------
