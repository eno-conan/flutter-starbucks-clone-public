set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_cart_with_store(p_user_id uuid)
 RETURNS TABLE(user_id uuid, store_number character, payment_method text, created_at timestamp with time zone, updated_at timestamp with time zone, usage smallint, store_name text, address text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  return query
  select
    c.user_id,
    c.store_number,
    c.payment_method,
    c.created_at,
    c.updated_at,
    c.usage,
    s.store_name,
    s.address
  from carts c
  inner join stores s on c.store_number = s.store_number
  where c.user_id = p_user_id;
end;
$function$
;


