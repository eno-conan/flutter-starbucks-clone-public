drop function if exists "public"."get_stores_with_favorites"(user_id_param uuid);

drop function if exists "public"."get_nearby_stores"(lat double precision, lng double precision, radius_km double precision);

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_nearby_stores(lat double precision, lng double precision, radius_km double precision)
 RETURNS TABLE(store_number character, store_name character varying, prefecture_id integer, address character varying, closing_time time without time zone, opening_time time without time zone, latitude double precision, longitude double precision, distance_km double precision)
 LANGUAGE sql
AS $function$
  WITH stores_with_distance AS (
    SELECT 
      s.store_number,
      s.store_name,
      s.prefecture_id,
      s.address,
      s.closing_time,
      s.opening_time,
      s.latitude,
      s.longitude,
      6371 * acos(
        cos(radians(lat)) * cos(radians(s.latitude)) *
        cos(radians(s.longitude) - radians(lng)) +
        sin(radians(lat)) * sin(radians(s.latitude))
      ) AS distance_km
    FROM stores s
    WHERE s.closing_date IS NULL OR s.closing_date > CURRENT_DATE
  )
  SELECT 
    store_number,
    store_name,
    prefecture_id,
    address,
    closing_time,
    opening_time,
    latitude,
    longitude,
    distance_km
  FROM stores_with_distance
  WHERE distance_km < radius_km
  ORDER BY distance_km;
$function$
;


