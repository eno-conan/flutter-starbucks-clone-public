-- 既存RPCをマテリアライズドビューから読み込むように変更
-- 返却カラムは変更なし → Dart側修正不要
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
