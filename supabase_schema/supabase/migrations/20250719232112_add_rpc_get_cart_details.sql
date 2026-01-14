set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_cart_details(input_user_id uuid)
 RETURNS TABLE(item_index integer, product_id integer, product_name text, temperature_type_id integer, type_name text, size_id integer, size_name text, count integer, subtotal_without_tax integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    cd.item_index,
    cd.product_id,
    p.product_name,
    cd.temperature_type_id,
    tt.type_name,
    cd.size_id,
    s.size_name,
    cd.count,
    cd.subtotal_without_tax
  FROM carts_detail cd
  INNER JOIN products p ON cd.product_id = p.product_id
  INNER JOIN temperature_types tt ON cd.temperature_type_id = tt.temperature_type_id
  INNER JOIN sizes s ON cd.size_id = s.size_id
  WHERE cd.user_id = input_user_id
  ORDER BY cd.item_index;
END;
$function$
;


