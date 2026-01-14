set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_orders(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    result json;
BEGIN
    WITH user_orders AS (
        SELECT 
            o.order_id,
            o.eat_in_takeout,
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
            stores s ON o.store_id = s.store_number
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
            sz.size_id,
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
            product_sizes ps ON od.product_id = ps.product_id AND od.size_id = ps.size_id
        LEFT JOIN
            sizes sz ON ps.size_id = sz.size_id
        LEFT JOIN
            temperature_types tt ON od.temperature_type_id = tt.temperature_type_id
        WHERE
            od.user_id = p_user_id
    )
    SELECT
        json_agg(
            json_build_object(
                'order_id', uo.order_id,
                'eat_in_takeout', uo.eat_in_takeout,
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
        
    -- Return empty array instead of null if no orders found
    IF result IS NULL THEN
        result := '[]'::json;
    END IF;
        
    RETURN result;
END;
$function$
;


