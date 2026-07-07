-- Issue#544: アーカイブデータの Storage エクスポート実装
-- pg_net 有効化 + Edge Function 呼び出しトリガー関数
--
-- 前提:
--   - Supabase Dashboard > Database > Extensions で pg_net が有効なこと
--   - 以下を SQL Editor で一度だけ手動実行して Vault に URL を登録すること:
--
--     SELECT vault.create_secret(
--         'https://<project-ref>.supabase.co',
--         'supabase_url'
--     );
--
-- Edge Function は --no-verify-jwt でデプロイすること:
--   supabase functions deploy exportArchiveToStorage --no-verify-jwt
--
-- ----------------------------------------------------------------
-- pg_net 拡張を有効化（pg_cron から Edge Function を HTTP 呼び出しするため）
-- ----------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

-- ----------------------------------------------------------------
-- Edge Function を HTTP POST で呼び出すトリガー関数
-- --no-verify-jwt でデプロイするため Authorization ヘッダー不要
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trigger_export_archive_to_storage()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'vault', 'net'
AS $$
DECLARE
    v_url        text;
    v_request_id bigint;
BEGIN
    SELECT decrypted_secret INTO v_url
    FROM vault.decrypted_secrets
    WHERE name = 'supabase_url';

    v_url := v_url || '/functions/v1/exportArchiveToStorage';

    SELECT net.http_post(
        url     := v_url,
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body    := '{}'::jsonb
    ) INTO v_request_id;

    RETURN jsonb_build_object('request_id', v_request_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.trigger_export_archive_to_storage() TO service_role;

-- ----------------------------------------------------------------
-- 動作確認用クエリ（実行後にコメントアウトして残す）
--
-- 手動実行:
--   SELECT public.trigger_export_archive_to_storage();
--
-- pg_net のレスポンス確認（非同期のため数秒後に実行）:
--   SELECT id, status_code, content
--   FROM net._http_response
--   ORDER BY id DESC
--   LIMIT 5;
-- ----------------------------------------------------------------
