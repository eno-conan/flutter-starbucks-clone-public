-- ============================================================
-- Fix: ADD SET search_path TO 'public' for SECURITY DEFINER functions
-- This prevents Search Path Hijacking attacks.
-- See: .claude/rules/supabase/security-definer-guidelines.md
-- ============================================================

-- 1. get_product_by_id
DROP FUNCTION IF EXISTS public.get_product_by_id(integer);

CREATE OR REPLACE FUNCTION public.get_product_by_id(product_id_param integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
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
$function$;

-- 2. create_order_with_details
DROP FUNCTION IF EXISTS public.create_order_with_details(character varying, character, smallint, smallint, character varying, integer, integer, character varying, jsonb);

CREATE OR REPLACE FUNCTION public.create_order_with_details(
  p_order_id character varying,
  p_store_id character,
  p_eat_in_takeout smallint,
  p_order_type smallint,
  p_pickup_number character varying,
  p_price_without_tax integer,
  p_price_with_tax integer,
  p_payment_method character varying,
  p_order_details jsonb
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_order_result JSONB;
  v_detail JSONB;
BEGIN
  v_user_id := auth.uid();
  BEGIN
    INSERT INTO orders (
      order_id, user_id, store_id, eat_in_takeout, order_type,
      pickup_number, price_without_tax, price_with_tax, payment_method
    ) VALUES (
      p_order_id, v_user_id, p_store_id, p_eat_in_takeout, p_order_type,
      p_pickup_number, p_price_without_tax, p_price_with_tax, p_payment_method
    )
    RETURNING to_jsonb(orders.*) INTO v_order_result;

    FOR v_detail IN SELECT * FROM jsonb_array_elements(p_order_details)
    LOOP
      INSERT INTO orders_detail (
        order_id, user_id, product_id, temperature_type_id, size_id, count, subtotal_without_tax
      ) VALUES (
        p_order_id, v_user_id,
        (v_detail->>'product_id')::INTEGER,
        (v_detail->>'temperature_type_id')::INTEGER,
        (v_detail->>'size_id')::INTEGER,
        (v_detail->>'count')::INTEGER,
        (v_detail->>'subtotal_without_tax')::INTEGER
      );
    END LOOP;

    RETURN jsonb_build_object('success', true, 'order', v_order_result);
  EXCEPTION WHEN OTHERS THEN
    RAISE;
  END;
END;
$function$;

-- 3. get_store_order_list
DROP FUNCTION IF EXISTS public.get_store_order_list(uuid);

CREATE OR REPLACE FUNCTION public.get_store_order_list(p_user_id uuid)
 RETURNS TABLE(
   order_id character varying, store_number character varying, store_name character varying,
   eat_in_takeout character varying, pickup_number character varying, detail_id uuid,
   product_name character varying, temperature_type character varying,
   size_name character varying, count integer
 )
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT
  o.order_id::VARCHAR,
  o.store_number::VARCHAR,
  st.store_name::VARCHAR,
  o.usage::VARCHAR,
  o.pickup_number::VARCHAR,
  od.id::UUID,
  p.product_name::VARCHAR,
  tt.type_name::VARCHAR AS temperature_type,
  s.size_name::VARCHAR,
  od.count::INTEGER
FROM orders o
JOIN orders_detail od ON o.order_id = od.order_id
JOIN store_profiles sp ON o.store_number = sp.store_number
JOIN products p ON od.product_id = p.product_id
JOIN temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
JOIN sizes s ON od.size_id = s.size_id
JOIN stores st ON o.store_number = st.store_number
WHERE sp.user_id = p_user_id;
$function$;

-- 4. check_signup_email_exists
DROP FUNCTION IF EXISTS public.check_signup_email_exists(text);

CREATE OR REPLACE FUNCTION public.check_signup_email_exists(input_email text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  email_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = input_email
  ) INTO email_exists;
  RETURN email_exists;
END;
$function$;

-- 5. get_select_store_drive_thru_status
DROP FUNCTION IF EXISTS public.get_select_store_drive_thru_status(uuid);

CREATE OR REPLACE FUNCTION public.get_select_store_drive_thru_status(p_user_id uuid)
 RETURNS TABLE(store_number character, is_drive_thru_available character)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT s.store_number, s.is_drive_thru_available
  FROM public.stores s
  JOIN public.carts c ON c.store_number = s.store_number
  WHERE c.user_id = p_user_id;
END;
$function$;

-- 6. get_cart_details
DROP FUNCTION IF EXISTS public.get_cart_details(uuid);

CREATE OR REPLACE FUNCTION public.get_cart_details(input_user_id uuid)
 RETURNS TABLE(
   item_index integer, product_id integer, product_name text,
   temperature_type_id integer, type_name text, size_id integer,
   size_name text, count integer, subtotal_without_tax integer
 )
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    cd.item_index, cd.product_id, p.product_name,
    cd.temperature_type_id, tt.type_name, cd.size_id,
    s.size_name, cd.count, cd.subtotal_without_tax
  FROM carts_detail cd
  INNER JOIN products p ON cd.product_id = p.product_id
  INNER JOIN temperature_types tt ON cd.temperature_type_id = tt.temperature_type_id
  INNER JOIN sizes s ON cd.size_id = s.size_id
  WHERE cd.user_id = input_user_id
  ORDER BY cd.item_index;
END;
$function$;

-- 7. get_cart_with_store
DROP FUNCTION IF EXISTS public.get_cart_with_store(uuid);

CREATE OR REPLACE FUNCTION public.get_cart_with_store(p_user_id uuid)
 RETURNS TABLE(
   user_id uuid, store_number character, payment_method text,
   created_at timestamp with time zone, updated_at timestamp with time zone,
   usage smallint, store_name text, address text
 )
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  return query
  select
    c.user_id, c.store_number, c.payment_method,
    c.created_at, c.updated_at, c.usage,
    s.store_name, s.address
  from carts c
  inner join stores s on c.store_number = s.store_number
  where c.user_id = p_user_id;
end;
$function$;

-- 8. get_user_orders_with_full_details
DROP FUNCTION IF EXISTS public.get_user_orders_with_full_details(uuid, character varying);

CREATE OR REPLACE FUNCTION public.get_user_orders_with_full_details(
  p_user_id uuid,
  p_order_id character varying DEFAULT NULL::character varying
)
 RETURNS TABLE(
   order_id character varying, order_type smallint, pickup_number text,
   price_without_tax integer, price_with_tax integer, payment_method text,
   created_at timestamp with time zone, provided_status text,
   store_number character, usage smallint, order_details jsonb
 )
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    o.order_id, o.order_type, o.pickup_number,
    o.price_without_tax, o.price_with_tax, o.payment_method,
    o.created_at, o.provided_status, o.store_number, o.usage,
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
    o.id, o.order_id, o.order_type, o.pickup_number,
    o.price_without_tax, o.price_with_tax, o.payment_method,
    o.created_at, o.provided_status, o.store_number, o.usage
  ORDER BY o.created_at DESC;
END;
$function$;
