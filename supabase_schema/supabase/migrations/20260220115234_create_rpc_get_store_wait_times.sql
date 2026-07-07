set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_store_wait_times(p_date date)
 RETURNS TABLE(store_number text, total_staff bigint, cooking_staff bigint, preparing_items bigint, is_open boolean)
 LANGUAGE sql
 STABLE
AS $function$
WITH current_period AS (
    SELECT CASE
        WHEN LOCALTIME BETWEEN '07:00' AND '11:00' THEN 'period_1'
        WHEN LOCALTIME BETWEEN '10:00' AND '14:00' THEN 'period_2'
        WHEN LOCALTIME BETWEEN '13:00' AND '17:00' THEN 'period_3'
        WHEN LOCALTIME BETWEEN '16:00' AND '20:00' THEN 'period_4'
        WHEN LOCALTIME BETWEEN '19:00' AND '23:00' THEN 'period_5'
        ELSE NULL
    END AS period_name
),
staff_counts AS (
    SELECT
        s.store_number,
        CASE WHEN cp.period_name IS NULL THEN 0 ELSE COUNT(*) END AS total_staff,
        CASE WHEN cp.period_name IS NULL THEN 0 ELSE GREATEST(COUNT(*) - 1, 0) END AS cooking_staff
    FROM staff_schedules s
    INNER JOIN staff st ON s.staff_number = st.staff_number
    CROSS JOIN current_period cp
    WHERE s.date = p_date
      AND (
          (cp.period_name = 'period_1' AND s.period_1 = true) OR
          (cp.period_name = 'period_2' AND s.period_2 = true) OR
          (cp.period_name = 'period_3' AND s.period_3 = true) OR
          (cp.period_name = 'period_4' AND s.period_4 = true) OR
          (cp.period_name = 'period_5' AND s.period_5 = true) OR
          cp.period_name IS NULL
      )
    GROUP BY s.store_number, cp.period_name
),
preparing_items AS (
    SELECT
        o.store_number,
        COALESCE(SUM(od.count), 0) AS total_items
    FROM orders o
    INNER JOIN orders_detail od ON o.order_id = od.order_id
    WHERE o.provided_status = '0'
    GROUP BY o.store_number
)
SELECT
    sc.store_number,
    sc.total_staff,
    sc.cooking_staff,
    COALESCE(pi.total_items, 0) AS preparing_items,
    (SELECT period_name FROM current_period) IS NOT NULL AS is_open
FROM staff_counts sc
LEFT JOIN preparing_items pi ON sc.store_number = pi.store_number;
$function$
;

