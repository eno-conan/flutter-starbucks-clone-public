set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_select_store_drive_thru_status(p_user_id uuid)
 RETURNS TABLE(store_number character, is_drive_thru_available character)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    s.store_number,
    s.is_drive_thru_available
  FROM 
    public.stores s
  JOIN 
    public.carts c ON c.store_number = s.store_number
  WHERE 
    c.user_id = p_user_id;
END;
$function$
;


