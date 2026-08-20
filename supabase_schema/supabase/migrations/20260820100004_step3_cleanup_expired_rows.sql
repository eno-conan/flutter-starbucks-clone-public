-- ============================================================================
-- DB設計レビュー (Issue #938) Step 3-4: 期限切れ行のクリーンアップ (E-7)
--
-- pre_signup_users（有効期限30分の仮登録）と email_check_rate_limits
-- （メール重複チェックのレート制限）は、既存のマイグレーション・pg_cron 定義に
-- 定期削除が無く、放置すると単調増加する。
-- 既にある cleanup_expired_user_tickets / cleanup_abandoned_carts と
-- 同じ形の関数を用意し、cron/archive_data.sql から呼べるようにする。
--
-- 実際のスケジュール登録は supabase_schema/cron/archive_data.sql を
-- Supabase Dashboard の SQL Editor で実行して行う（他のジョブと同じ運用）。
-- ============================================================================


-- ----------------------------------------------------------------------------
-- cleanup_expired_pre_signup_users
--   有効期限切れから猶予期間（デフォルト24時間）を超えた仮登録を削除する。
--   猶予を置くのは、期限切れ直後にユーザーが登録リンクを踏んだときに
--   「期限切れ」と案内できるようにするため（行ごと消すと理由が出せない）。
--   戻り値: { cutoff_date, deleted_count }
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_expired_pre_signup_users(
    p_grace_hours integer DEFAULT 24
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date   timestamp with time zone;
    v_deleted_count integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_grace_hours || ' hours')::interval;

    WITH deleted AS (
        DELETE FROM public.pre_signup_users
        WHERE expires_at < v_cutoff_date
        RETURNING id
    )
    SELECT count(*) INTO v_deleted_count FROM deleted;

    RETURN jsonb_build_object(
        'cutoff_date',   v_cutoff_date,
        'deleted_count', v_deleted_count
    );
END;
$$;

COMMENT ON FUNCTION public.cleanup_expired_pre_signup_users(integer)
    IS '有効期限切れの仮登録ユーザーを削除する。pg_cron から日次で呼ぶ (Issue #938 E-7)';


-- ----------------------------------------------------------------------------
-- cleanup_email_check_rate_limits
--   レート制限の判定に使うのは直近の数分ぶんだけで、それより古い行は
--   カウントに一切効かない。保持期間（デフォルト7日）を超えた行を削除する。
--   戻り値: { cutoff_date, deleted_count }
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_email_check_rate_limits(
    p_retention_days integer DEFAULT 7
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_cutoff_date   timestamp with time zone;
    v_deleted_count integer := 0;
BEGIN
    v_cutoff_date := NOW() - (p_retention_days || ' days')::interval;

    WITH deleted AS (
        DELETE FROM public.email_check_rate_limits
        WHERE created_at < v_cutoff_date
        RETURNING id
    )
    SELECT count(*) INTO v_deleted_count FROM deleted;

    RETURN jsonb_build_object(
        'cutoff_date',   v_cutoff_date,
        'deleted_count', v_deleted_count
    );
END;
$$;

COMMENT ON FUNCTION public.cleanup_email_check_rate_limits(integer)
    IS 'レート制限の判定に効かなくなった古い記録を削除する。pg_cron から日次で呼ぶ (Issue #938 E-7)';


-- ----------------------------------------------------------------
-- 権限: 既存のクリーンアップ関数と揃える
--   クライアントロール（anon / authenticated）からは呼べないようにし、
--   pg_cron スケジュール実行・SQL Editor からの手動実行に使う
--   service_role にだけ EXECUTE を渡す。
-- ----------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_pre_signup_users(integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.cleanup_email_check_rate_limits(integer)  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.cleanup_expired_pre_signup_users(integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_email_check_rate_limits(integer)  TO service_role;
