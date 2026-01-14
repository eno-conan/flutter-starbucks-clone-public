set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_store_order_list(p_user_id uuid)
 RETURNS TABLE(order_id uuid, store_number character varying, store_name character varying, eat_in_takeout character varying, pickup_number character varying, detail_id uuid, product_name character varying, temperature_type character varying, size_name character varying, count integer)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
SELECT
  o.order_id::UUID,  -- UUID型にキャスト
  o.store_number::VARCHAR,
  st.store_name::VARCHAR,
  o.eat_in_takeout::VARCHAR,
  o.pickup_number::VARCHAR,
  od.id::UUID,  -- UUID型にキャスト
  p.product_name::VARCHAR,
  tt.type_name::VARCHAR AS temperature_type,
  s.size_name::VARCHAR,
  od.count::INTEGER
FROM
  orders o
JOIN
  orders_detail od ON o.order_id = od.order_id
JOIN
  store_profiles sp ON o.store_number = sp.store_number
JOIN
  products p ON od.product_id = p.product_id
JOIN
  temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
JOIN
  sizes s ON od.size_id = s.size_id
JOIN
  stores st ON o.store_number = st.store_number
WHERE
  sp.user_id = p_user_id;
$function$
;


