set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_orders_with_full_details(p_user_id uuid, p_order_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE(order_id character varying, order_type smallint, pickup_number text, price_without_tax integer, price_with_tax integer, payment_method text, created_at timestamp with time zone, provided_status text, store_number character, usage smallint, order_details jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    o.order_id,
    o.order_type,
    o.pickup_number,
    o.price_without_tax,
    o.price_with_tax,
    o.payment_method,
    o.created_at,
    o.provided_status,
    o.store_number,
    o.usage,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', od.id,
          'product_id', od.product_id,
          'product_name', p.product_name,
          'temperature_type_id', od.temperature_type_id,
          'temperature_type_name', tt.temperature_type_name,
          'size_id', od.size_id,
          'size_name', s.size_name,
          'count', od.count,
          'subtotal_without_tax', od.subtotal_without_tax
        ) ORDER BY od.id
      ) FILTER (WHERE od.id IS NOT NULL),
      '[]'::jsonb
    ) AS order_details
  FROM orders o
  LEFT JOIN orders_detail od ON o.order_id = od.order_id
  LEFT JOIN products p ON od.product_id = p.product_id
  LEFT JOIN temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
  LEFT JOIN sizes s ON od.size_id = s.size_id
  WHERE o.user_id = p_user_id
    AND (p_order_id IS NULL OR o.order_id = p_order_id)
  GROUP BY 
    o.id,
    o.order_id,
    o.order_type,
    o.pickup_number,
    o.price_without_tax,
    o.price_with_tax,
    o.payment_method,
    o.created_at,
    o.provided_status,
    o.store_number,
    o.usage
  ORDER BY o.created_at DESC;
END;
$function$
;


  create policy "Authenticated users can read starbucks bucket"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'starbucks'::text) AND (auth.role() = 'authenticated'::text)));



