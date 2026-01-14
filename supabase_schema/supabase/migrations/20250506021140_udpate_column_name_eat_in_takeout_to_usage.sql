alter table "public"."orders" drop constraint "orders_eat_in_takeout_check";

alter table "public"."carts" drop column "eat_in_takeout";

alter table "public"."carts" add column "usage" smallint;

alter table "public"."orders" drop column "eat_in_takeout";

alter table "public"."orders" add column "usage" smallint NOT NULL DEFAULT 1;

alter table "public"."orders" add constraint "orders_usage" CHECK ((usage = ANY (ARRAY[1, 2, 3]))) not valid;

alter table "public"."orders" validate constraint "orders_usage";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_order_with_details(p_order_id character varying, p_store_number character varying, p_eat_in_takeout smallint, p_order_type smallint, p_pickup_number character varying, p_price_without_tax integer, p_price_with_tax integer, p_payment_method character varying, p_order_details jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
  v_user_id UUID;
  v_order_result JSONB;
  v_detail JSONB;
BEGIN
  -- 現在のユーザーIDを取得
  v_user_id := auth.uid();
  
  -- トランザクション開始
  BEGIN
    -- 注文を作成
    INSERT INTO orders (
      order_id,
      user_id,
      store_number,  -- store_id → store_number
      usage,
      order_type,
      pickup_number,
      price_without_tax,
      price_with_tax,
      payment_method
    ) VALUES (
      p_order_id,
      v_user_id,
      p_store_number,  -- p_store_id → p_store_number
      p_usage,
      p_order_type,
      p_pickup_number,
      p_price_without_tax,
      p_price_with_tax,
      p_payment_method
    )
    RETURNING to_jsonb(orders.*) INTO v_order_result;
    
    -- 各注文詳細を処理
    FOR v_detail IN SELECT * FROM jsonb_array_elements(p_order_details)
    LOOP
      INSERT INTO orders_detail (
        order_id,
        user_id,
        product_id,
        temperature_type_id,
        size_id,
        count,
        subtotal_without_tax
      ) VALUES (
        p_order_id,
        v_user_id,
        (v_detail->>'product_id')::INTEGER,
        (v_detail->>'temperature_type_id')::INTEGER,
        (v_detail->>'size_id')::INTEGER,
        (v_detail->>'count')::INTEGER,
        (v_detail->>'subtotal_without_tax')::INTEGER
      );
    END LOOP;
    
    RETURN jsonb_build_object(
      'success', true,
      'order', v_order_result
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE;
  END;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_store_order_list(p_user_id uuid)
 RETURNS TABLE(order_id character varying, store_number character varying, store_name character varying, provided_status character varying, eat_in_takeout character varying, pickup_number character varying, detail_id uuid, product_name character varying, temperature_type character varying, size_name character varying, count integer)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$SELECT
  o.order_id::VARCHAR,
  o.store_number::VARCHAR,
  st.store_name::VARCHAR,
  o.provided_status::VARCHAR,
  o.usage::VARCHAR,
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
  sp.user_id = p_user_id
  AND o.provided_status IN ('0', '1');$function$
;

CREATE OR REPLACE FUNCTION public.get_user_orders(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$DECLARE
    result json;
BEGIN
    WITH user_orders AS (
        SELECT 
            o.order_id,
            o.usage,
            o.created_at,
            s.store_number,
            s.store_name,
            s.address,
            o.price_without_tax,
            o.price_with_tax,
            o.payment_method,
            o.pickup_number
        FROM 
            orders o
        JOIN 
            stores s ON o.store_number = s.store_number
        WHERE 
            o.user_id = p_user_id
        ORDER BY 
            o.created_at DESC
        LIMIT 10
    ),
    order_items AS (
        SELECT
            od.order_id,
            p.product_id,
            p.product_name,
            od.size_id,
            sz.size_name,
            tt.temperature_type_id,
            tt.type_name,
            od.count,
            od.subtotal_without_tax
        FROM
            orders_detail od
        JOIN
            products p ON od.product_id = p.product_id
        LEFT JOIN
            sizes sz ON od.size_id = sz.size_id
        LEFT JOIN
            temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
        WHERE
            od.user_id = p_user_id
    )
    SELECT
        json_agg(
            json_build_object(
                'order_id', uo.order_id,
                'usage', uo.usage,
                'created_at', uo.created_at,
                'store_number', uo.store_number,
                'store_name', uo.store_name,
                'store_address', uo.address,
                'price_without_tax', uo.price_without_tax,
                'price_with_tax', uo.price_with_tax,
                'payment_method', uo.payment_method,
                'pickup_number', uo.pickup_number,
                'items', (
                    SELECT json_agg(
                        json_build_object(
                            'product_id', items.product_id,
                            'product_name', items.product_name,
                            'size_id', items.size_id,
                            'size_name', items.size_name,
                            'temperature_type_id', items.temperature_type_id,
                            'temperature_type_name', items.type_name,
                            'count', items.count,
                            'subtotal_without_tax', items.subtotal_without_tax
                        )
                    )
                    FROM order_items items
                    WHERE items.order_id = uo.order_id
                )
            )
            ORDER BY uo.created_at DESC
        ) INTO result
    FROM
        user_orders uo;
        
    IF result IS NULL THEN
        result := '[]'::json;
    END IF;
        
    RETURN result;
END;$function$
;


