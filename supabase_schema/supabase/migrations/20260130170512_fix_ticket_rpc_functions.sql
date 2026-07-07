-- Fix eチケット関連の型不一致とカラム欠落問題
-- Issue: PostgrestException - integer/bigint型不一致、used_atカラム不足

set check_function_bodies = off;

-- 1. user_ticketsテーブルにused_atカラムを追加
ALTER TABLE public.user_tickets
ADD COLUMN IF NOT EXISTS used_at TIMESTAMP WITH TIME ZONE;

-- 2. 既存の使用済みチケットにused_atの初期値を設定
UPDATE public.user_tickets
SET used_at = updated_at
WHERE is_used = true AND used_at IS NULL;

DROP FUNCTION IF EXISTS public.get_user_available_tickets(uuid);
DROP FUNCTION IF EXISTS public.get_user_used_tickets(uuid);

-- 3. RPC関数を修正: bigint → integer（get_user_available_tickets）
CREATE OR REPLACE FUNCTION public.get_user_available_tickets(p_user_id uuid)
 RETURNS TABLE(
   user_ticket_id integer,  -- bigintからintegerに変更
   user_id uuid,
   ticket_type text,
   expired_at timestamp with time zone,
   is_used boolean,
   ticket_name text,
   image_url text,
   discount_type text,
   discount_value integer
 )
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
    AND ut.expired_at > NOW()

  ORDER BY ut.expired_at ASC;
END;
$function$;

-- 4. RPC関数を修正: bigint → integer（get_user_used_tickets）
CREATE OR REPLACE FUNCTION public.get_user_used_tickets(p_user_id uuid)
 RETURNS TABLE(
   user_ticket_id integer,  -- bigintからintegerに変更
   user_id uuid,
   ticket_type text,
   expired_at timestamp with time zone,
   used_at timestamp with time zone,
   ticket_name text,
   image_url text,
   discount_type text,
   discount_value integer
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    ut.id AS user_ticket_id,
    ut.user_id,
    ut.ticket_type,
    ut.expired_at,
    ut.used_at,

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
    AND ut.expired_at > NOW() - INTERVAL '14 days'

  ORDER BY ut.used_at DESC;
END;
$function$;

-- 5. トリガー関数: チケット使用時にused_atを自動設定
CREATE OR REPLACE FUNCTION public.set_used_at_on_ticket_use()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_used = true AND OLD.is_used = false THEN
    NEW.used_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. トリガーを作成
DROP TRIGGER IF EXISTS trigger_set_used_at ON public.user_tickets;

CREATE TRIGGER trigger_set_used_at
BEFORE UPDATE ON public.user_tickets
FOR EACH ROW
EXECUTE FUNCTION set_used_at_on_ticket_use();
