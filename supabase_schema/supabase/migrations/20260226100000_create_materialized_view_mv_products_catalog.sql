-- マテリアライズドビューの作成
CREATE MATERIALIZED VIEW public.mv_products_catalog AS
SELECT
    p.product_id,
    p.product_name,
    p.category_id,
    c.category_name,
    p.description,
    p.product_image_path,
    p.sale_type,
    p.display_order,
    s.size_id,
    s.size_name,
    ps.price,
    ptt.temperature_type_id,
    tt.type_name AS temperature_type_name
FROM
    products p
LEFT JOIN
    categories c ON p.category_id = c.category_id
LEFT JOIN
    product_sizes ps ON p.product_id = ps.product_id
LEFT JOIN
    sizes s ON ps.size_id = s.size_id
LEFT JOIN
    product_temperature_types ptt ON ptt.product_id = p.product_id
LEFT JOIN
    temperature_types tt ON tt.temperature_type_id = ptt.temperature_type_id
ORDER BY
    p.display_order ASC,
    p.category_id ASC,
    p.product_name ASC
WITH DATA;

-- CONCURRENTLY リフレッシュに必要なユニークインデックス
-- LEFT JOIN由来のNULLはCOALESCEで-1に変換してユニーク性を保証
CREATE UNIQUE INDEX idx_mv_products_catalog_unique
    ON public.mv_products_catalog (product_id, COALESCE(size_id, -1), COALESCE(temperature_type_id, -1));

-- anon / authenticated に SELECT を付与（RLS設定に合わせる）
GRANT SELECT ON public.mv_products_catalog TO anon;
GRANT SELECT ON public.mv_products_catalog TO authenticated;

-- リフレッシュ管理用RPC
-- SECURITY DEFINER: REFRESH MATERIALIZED VIEW はスーパーユーザー権限が必要
-- SET search_path: Search Path Hijacking 対策（必須）
CREATE OR REPLACE FUNCTION public.refresh_products_catalog()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_products_catalog;
$function$;

-- anon / authenticated からの実行を禁止（管理者のみ呼び出し可）
REVOKE EXECUTE ON FUNCTION public.refresh_products_catalog() FROM public;
REVOKE EXECUTE ON FUNCTION public.refresh_products_catalog() FROM anon;
REVOKE EXECUTE ON FUNCTION public.refresh_products_catalog() FROM authenticated;
