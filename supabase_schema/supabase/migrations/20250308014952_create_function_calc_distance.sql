set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_nearby_stores(lat double precision, lng double precision, radius_km double precision)
 RETURNS TABLE(id integer, store_number character, store_name character varying, prefecture_id integer, address character varying, opening_date date, closing_date date, closing_time time without time zone, opening_time time without time zone, latitude double precision, longitude double precision, distance_km double precision, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
AS $function$
  WITH stores_with_distance AS (
    SELECT 
      s.id,
      s.store_number,
      s.store_name,
      s.prefecture_id,
      s.address,
      s.opening_date,
      s.closing_date,
      s.closing_time,
      s.opening_time,
      s.latitude,
      s.longitude,
      6371 * acos(
        cos(radians(lat)) * cos(radians(s.latitude)) *
        cos(radians(s.longitude) - radians(lng)) +
        sin(radians(lat)) * sin(radians(s.latitude))
      ) AS distance_km,  -- 明示的に計算カラムを追加
      s.created_at,
      s.updated_at
    FROM stores s
    WHERE s.closing_date IS NULL OR s.closing_date > CURRENT_DATE
  )
  SELECT 
    id,
    store_number,
    store_name,
    prefecture_id,
    address,
    opening_date,
    closing_date,
    closing_time,
    opening_time,
    latitude,
    longitude,
    distance_km,  -- 計算カラムを適切な位置に指定
    created_at,
    updated_at
  FROM stores_with_distance
  WHERE distance_km < radius_km
  ORDER BY distance_km;
$function$
;


