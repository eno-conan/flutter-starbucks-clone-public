CREATE TABLE IF NOT EXISTS public.email_check_rate_limits (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  ip_hash    text        NOT NULL,           -- IP の SHA-256 ハッシュ（プライバシー考慮）
  created_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ON public.email_check_rate_limits (ip_hash, created_at);

-- service_role のみアクセス可（Flutter / PostgREST からは参照不可）
ALTER TABLE public.email_check_rate_limits ENABLE ROW LEVEL SECURITY;
