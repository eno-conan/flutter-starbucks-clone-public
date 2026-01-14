set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_stores_with_favorites(user_id_param uuid)
 RETURNS TABLE(id integer, store_number character, store_name character varying, address character varying, closing_time time without time zone, opening_time time without time zone, latitude double precision, longitude double precision, is_favorite boolean)
 LANGUAGE plpgsql
AS $function$BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.store_number,
    s.store_name,
    s.address,
    s.closing_time,
    s.opening_time,
    s.latitude,
    s.longitude,
    CASE WHEN fs.store_number IS NOT NULL THEN TRUE ELSE FALSE END AS is_favorite
  FROM 
    stores s
  LEFT JOIN 
    favorite_stores fs ON s.store_number = fs.store_number AND fs.user_id = user_id_param
  ORDER BY 
    s.store_number;
END;$function$
;


