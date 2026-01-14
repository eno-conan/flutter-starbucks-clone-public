set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_product_by_id(product_id_param integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  result JSON;
BEGIN
  SELECT 
    json_build_object(
      'product_id', p.product_id,
      'product_name', p.product_name,
      'description', p.description,
      'category_id', p.category_id,
      'product_temperature_types', (
        SELECT json_agg(
          json_build_object(
            'temperature_types', json_build_object(
              'temperature_type_id', tt.temperature_type_id,
              'type_name', tt.type_name
            )
          )
        )
        FROM product_temperature_types ptt
        JOIN temperature_types tt ON ptt.temperature_type_id = tt.temperature_type_id
        WHERE ptt.product_id = p.product_id
      ),
      'product_sizes', (
        SELECT json_agg(
          json_build_object(
            'price', ps.price,
            'sizes', json_build_object(
              'size_id', s.size_id,
              'size_name', s.size_name
            )
          )
        )
        FROM product_sizes ps
        JOIN sizes s ON ps.size_id = s.size_id
        WHERE ps.product_id = p.product_id
      )
    ) INTO result
  FROM products p
  WHERE p.product_id = product_id_param
  AND p.is_active = true;

  RETURN result;
END;
$function$
;


