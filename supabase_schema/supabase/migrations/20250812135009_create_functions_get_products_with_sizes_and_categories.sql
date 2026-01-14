set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_products_with_categories()
 RETURNS TABLE(product_name text, category_name text, sale_type text, display_order integer, description text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_name::TEXT,
        c.category_name::TEXT,
        p.sale_type::TEXT,
        p.display_order,
        p.description::TEXT
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    ORDER BY 
        p.display_order ASC,  
        p.product_name ASC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_products_with_sizes()
 RETURNS TABLE(product_id integer, product_name text, category_id integer, description text, product_image_path text, sale_type text, display_order integer, size_id integer, size_name text, price integer, temperature_type_id integer, temperature_type_name text)
 LANGUAGE sql
AS $function$
    SELECT 
        p.product_id,
        p.product_name,
        p.category_id,
        p.description,
        p.product_image_path,
        p.sale_type,
        p.display_order,
        s.size_id,
        s.size_name,
        ps.price,
        tt.temperature_type_id,
        tt.type_name as temperature_type_name
    FROM 
        products p
    LEFT JOIN 
        product_sizes ps ON p.product_id = ps.product_id
    LEFT JOIN 
        sizes s ON ps.size_id = s.size_id
    CROSS JOIN 
        temperature_types tt
    ORDER BY 
        p.display_order ASC,  
        p.product_name ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_products_with_sizes_and_categories()
 RETURNS TABLE(product_id integer, product_name text, category_id integer, description text, product_image_path text, sale_type text, display_order integer, size_id integer, size_name text, price integer, temperature_type_id integer, temperature_type_name text)
 LANGUAGE sql
AS $function$
    SELECT 
        p.product_id,
        p.product_name,
        p.category_id,
        p.description,
        p.product_image_path,
        p.sale_type,
        p.display_order,
        s.size_id,
        s.size_name,
        ps.price,
        tt.temperature_type_id,
        tt.type_name as temperature_type_name
    FROM 
        products p
    LEFT JOIN 
        product_sizes ps ON p.product_id = ps.product_id
    LEFT JOIN 
        sizes s ON ps.size_id = s.size_id
    CROSS JOIN 
        temperature_types tt
    ORDER BY 
        p.display_order ASC,  
        p.product_name ASC;
$function$
;


