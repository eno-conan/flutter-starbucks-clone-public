-- MVへの直接アクセス権限を剥奪
-- get_products_with_sizes_and_categories() RPC 経由のみ許可する
REVOKE SELECT ON public.mv_products_catalog FROM anon;
REVOKE SELECT ON public.mv_products_catalog FROM authenticated;

-- RPCをSECURITY DEFINERに変更してMVを定義者権限で読み取れるようにする
-- SET search_path: Search Path Hijacking 対策（必須）
CREATE OR REPLACE FUNCTION public.get_products_with_sizes_and_categories()
 RETURNS TABLE(
    product_id integer,
    product_name text,
    category_id integer,
    category_name text,
    description text,
    product_image_path text,
    sale_type text,
    display_order integer,
    size_id integer,
    size_name text,
    price integer,
    temperature_type_id integer,
    temperature_type_name text
 )
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT
        product_id,
        product_name,
        category_id,
        category_name,
        description,
        product_image_path,
        sale_type,
        display_order,
        size_id,
        size_name,
        price,
        temperature_type_id,
        temperature_type_name
    FROM
        public.mv_products_catalog;
$function$;
