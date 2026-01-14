set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_total_points_with_expiration_flag_zero()
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN (SELECT COALESCE(SUM(total_points), 0) FROM star_aggregations WHERE expiration_flag = 0);
END;
$function$
;


