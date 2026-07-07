-- anon / authenticated ロールからの直接 PostgREST 呼び出しを禁止
-- service_role（Edge Function）からは引き続き呼び出し可能
REVOKE EXECUTE ON FUNCTION public.check_signup_email_exists(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.check_signup_email_exists(text) FROM authenticated;
