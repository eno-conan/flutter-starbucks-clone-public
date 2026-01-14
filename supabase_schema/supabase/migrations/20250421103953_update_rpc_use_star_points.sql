set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.use_star_points(p_user_id uuid, p_order_id text, p_exchange_item_id integer, p_point_used numeric)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$DECLARE
  v_star_usage_id UUID;
  v_remaining_points NUMERIC(10,1);
  v_record RECORD;
BEGIN
  -- 入力値の検証
  IF p_point_used <= 0 THEN
    RAISE EXCEPTION 'ポイント数は0より大きい値である必要があります';
  END IF;

  -- 利用可能なポイントの合計を確認
  SELECT COALESCE(SUM(total_points), 0) INTO v_remaining_points 
  FROM public.star_aggregations 
  WHERE user_id = p_user_id;

  -- 利用可能なポイントが足りるか確認
  IF v_remaining_points < p_point_used THEN
    RAISE EXCEPTION '利用可能なポイントが不足しています（利用可能: %, 必要: %）', v_remaining_points, p_point_used;
  END IF;

  -- トランザクション開始
  BEGIN
    -- スター利用テーブルにレコード追加
    INSERT INTO public.star_usage (
      user_id,
      order_id,
      exchange_item_id,
      point_used,
      created_at,
      updated_at
    ) VALUES (
      p_user_id,
      p_order_id,
      p_exchange_item_id,
      p_point_used,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_star_usage_id;

    -- 利用するポイントの初期値を設定
    v_remaining_points := p_point_used;

    -- 有効期限が近いものから順にポイントを消費
    FOR v_record IN 
      SELECT target_year_month, total_points, expiration_datetime
      FROM public.star_aggregations
      WHERE user_id = p_user_id AND total_points > 0
      ORDER BY expiration_datetime ASC
    LOOP
      -- このレコードから消費するポイント量を計算
      DECLARE
        v_points_to_use NUMERIC(10,1);
      BEGIN
        v_points_to_use := LEAST(v_record.total_points, v_remaining_points);
        
        -- スター集計用テーブルを更新
        UPDATE public.star_aggregations
        SET 
          total_points = total_points - v_points_to_use,
          updated_at = NOW()
        WHERE user_id = p_user_id AND target_year_month = v_record.target_year_month;
        
        -- 残りの必要ポイントを減算
        v_remaining_points := v_remaining_points - v_points_to_use;
        
        -- 必要なポイントをすべて消費したら終了
        EXIT WHEN v_remaining_points <= 0;
      END;
    END LOOP;
    
    -- すべてのポイントが正しく消費されたか確認
    IF v_remaining_points > 0 THEN
      RAISE EXCEPTION 'ポイントの消費に失敗しました。残りのポイント: %', v_remaining_points;
    END IF;

    -- 成功したらスター利用IDを返す
    RETURN v_star_usage_id;
    
  EXCEPTION WHEN OTHERS THEN
    -- エラーが発生した場合はロールバック（自動的に行われるが明示的に記述）
    RAISE;
  END;
END;$function$
;


