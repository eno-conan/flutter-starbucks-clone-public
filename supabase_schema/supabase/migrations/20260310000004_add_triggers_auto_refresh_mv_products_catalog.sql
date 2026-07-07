-- トリガー関数の作成
-- トランザクション内で呼べる非 CONCURRENT リフレッシュを使用
-- （REFRESH MATERIALIZED VIEW CONCURRENTLY はトランザクション内では実行不可）
-- SECURITY DEFINER + SET search_path: Search Path Hijacking 対策（必須）
CREATE OR REPLACE FUNCTION public.refresh_mv_products_catalog_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public.mv_products_catalog;
    RETURN NULL;
END;
$$;

-- 各テーブルへのトリガー設置（AFTER / FOR EACH STATEMENT）
-- FOR EACH STATEMENT: 行単位ではなく文単位で1回だけ発火し、MV 更新の重複を防ぐ
CREATE OR REPLACE TRIGGER trg_refresh_mv_on_products_change
    AFTER INSERT OR UPDATE OR DELETE ON public.products
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();

CREATE OR REPLACE TRIGGER trg_refresh_mv_on_categories_change
    AFTER INSERT OR UPDATE OR DELETE ON public.categories
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();

CREATE OR REPLACE TRIGGER trg_refresh_mv_on_product_sizes_change
    AFTER INSERT OR UPDATE OR DELETE ON public.product_sizes
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();

CREATE OR REPLACE TRIGGER trg_refresh_mv_on_sizes_change
    AFTER INSERT OR UPDATE OR DELETE ON public.sizes
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();

CREATE OR REPLACE TRIGGER trg_refresh_mv_on_product_temperature_types_change
    AFTER INSERT OR UPDATE OR DELETE ON public.product_temperature_types
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();

CREATE OR REPLACE TRIGGER trg_refresh_mv_on_temperature_types_change
    AFTER INSERT OR UPDATE OR DELETE ON public.temperature_types
    FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_mv_products_catalog_trigger();
