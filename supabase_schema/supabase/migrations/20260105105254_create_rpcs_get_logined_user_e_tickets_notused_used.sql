set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_available_tickets(p_user_id uuid)
 RETURNS TABLE(user_ticket_id bigint, user_id uuid, ticket_type text, expired_at timestamp with time zone, is_used boolean, ticket_name text, image_url text, discount_type text, discount_value numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    ut.id AS user_ticket_id,
    ut.user_id,
    ut.ticket_type,
    ut.expired_at,
    ut.is_used,
    
    CASE ut.ticket_type
      WHEN 'STAR_REWARD' THEN sri.name
      WHEN 'PROMOTION' THEN ep.name
      WHEN 'SPECIAL_OFFER' THEN eso.name
    END AS ticket_name,

    CASE ut.ticket_type
      WHEN 'STAR_REWARD' THEN sri.image_url
      WHEN 'PROMOTION' THEN ep.image_url
      WHEN 'SPECIAL_OFFER' THEN eso.image_url
    END AS image_url,

    CASE ut.ticket_type
      WHEN 'PROMOTION' THEN ep.discount_type
      ELSE NULL
    END AS discount_type,

    CASE ut.ticket_type
      WHEN 'PROMOTION' THEN ep.discount_value
      WHEN 'SPECIAL_OFFER' THEN eso.special_price
      ELSE NULL
    END AS discount_value

  FROM 
    public.user_tickets ut

  LEFT JOIN public.star_rewards_exchange_items sri 
    ON ut.ticket_type = 'STAR_REWARD' 
    AND ut.definition_id = sri.id

  LEFT JOIN public.e_tickets_promotions ep 
    ON ut.ticket_type = 'PROMOTION' 
    AND ut.definition_id = ep.id

  LEFT JOIN public.e_tickets_special_offers eso 
    ON ut.ticket_type = 'SPECIAL_OFFER' 
    AND ut.definition_id = eso.id

  WHERE 
    ut.user_id = p_user_id
    AND ut.is_used = false
    AND ut.expired_at > NOW()  -- 有効期限内のみ
  
  ORDER BY ut.expired_at ASC;  -- 期限が近い順
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_used_tickets(p_user_id uuid)
 RETURNS TABLE(user_ticket_id bigint, user_id uuid, ticket_type text, expired_at timestamp with time zone, used_at timestamp with time zone, ticket_name text, image_url text, discount_type text, discount_value numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    ut.id AS user_ticket_id,
    ut.user_id,
    ut.ticket_type,
    ut.expired_at,
    ut.used_at,  -- 使用済の場合は使用日時も返す
    
    CASE ut.ticket_type
      WHEN 'STAR_REWARD' THEN sri.name
      WHEN 'PROMOTION' THEN ep.name
      WHEN 'SPECIAL_OFFER' THEN eso.name
    END AS ticket_name,

    CASE ut.ticket_type
      WHEN 'STAR_REWARD' THEN sri.image_url
      WHEN 'PROMOTION' THEN ep.image_url
      WHEN 'SPECIAL_OFFER' THEN eso.image_url
    END AS image_url,

    CASE ut.ticket_type
      WHEN 'PROMOTION' THEN ep.discount_type
      ELSE NULL
    END AS discount_type,

    CASE ut.ticket_type
      WHEN 'PROMOTION' THEN ep.discount_value
      WHEN 'SPECIAL_OFFER' THEN eso.special_price
      ELSE NULL
    END AS discount_value

  FROM 
    public.user_tickets ut

  LEFT JOIN public.star_rewards_exchange_items sri 
    ON ut.ticket_type = 'STAR_REWARD' 
    AND ut.definition_id = sri.id

  LEFT JOIN public.e_tickets_promotions ep 
    ON ut.ticket_type = 'PROMOTION' 
    AND ut.definition_id = ep.id

  LEFT JOIN public.e_tickets_special_offers eso 
    ON ut.ticket_type = 'SPECIAL_OFFER' 
    AND ut.definition_id = eso.id

  WHERE 
    ut.user_id = p_user_id
    AND ut.is_used = true
    AND ut.expired_at > NOW()  -- 有効期限内のもののみ（期限切れは表示しない）
  
  ORDER BY ut.used_at DESC;  -- 使用日時が新しい順
END;
$function$
;


