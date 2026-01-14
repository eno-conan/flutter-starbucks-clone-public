set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_products_with_sizes_and_categories()
 RETURNS TABLE(product_id integer, product_name text, category_id integer, category_name text, description text, product_image_path text, sale_type text, display_order integer, size_id integer, size_name text, price integer, temperature_type_id integer, temperature_type_name text)
 LANGUAGE sql
AS $function$
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
        tt.type_name as temperature_type_name
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
        p.product_name ASC;
$function$
;


