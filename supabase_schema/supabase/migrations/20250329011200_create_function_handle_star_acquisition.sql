set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_star_acquisition(p_user_id uuid, p_order_id character varying, p_category smallint, p_acquired_points numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
    v_target_year_month char(6);
begin
    -- star_acquisitions にデータを登録
    insert into star_acquisitions (user_id, order_id, category, acquired_points)
    values (p_user_id, p_order_id, p_category, p_acquired_points);

    -- 取得年月を計算 (created_atの現在値をYYYYMM形式にする)
    v_target_year_month := to_char(now(), 'YYYYMM');

    -- star_aggregations にデータを追加または更新
    insert into star_aggregations (user_id, target_year_month, total_points)
    values (p_user_id, v_target_year_month, p_acquired_points)
    on conflict (user_id, target_year_month) 
    do update set total_points = star_aggregations.total_points + excluded.total_points,
                  updated_at = now();

    -- 成功時のレスポンスを返す
    return jsonb_build_object('status', 'success', 'message', '');

exception
    when others then
        -- エラー時のレスポンスを返す
        return jsonb_build_object('status', 'error', 'message', sqlerrm);
end;
$function$
;


