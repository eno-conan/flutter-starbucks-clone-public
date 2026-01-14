set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_order_with_details(p_order_id character varying, p_store_id character, p_eat_in_takeout smallint, p_order_type smallint, p_pickup_number character varying, p_price_without_tax integer, p_price_with_tax integer, p_payment_method character varying, p_order_details jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
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
      store_id,
      eat_in_takeout,
      order_type,
      pickup_number,
      price_without_tax,
      price_with_tax,
      payment_method
    ) VALUES (
      p_order_id,
      v_user_id,
      p_store_id,
      p_eat_in_takeout,
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
END;
$function$
;


