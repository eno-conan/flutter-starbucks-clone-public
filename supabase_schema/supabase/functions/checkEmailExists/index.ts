import { createClient } from 'npm:@supabase/supabase-js@2';

const RATE_LIMIT_MAX = 5;
const RATE_LIMIT_WINDOW_MS = 5 * 60 * 1000; // 5分

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // ① Body を最初に読む（ReadableStream は先に消費しておく）
  const body = await req.json().catch(() => null);
  const email = body?.email;
  if (!email || typeof email !== 'string') {
    console.error('[checkEmailExists] Invalid request body:', JSON.stringify(body));
    return new Response(
      JSON.stringify({ error: 'Invalid request' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } },
    );
  }

  console.log('[checkEmailExists] called with email:', email);

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  // ② IPハッシュ生成
  const rawIp = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
  const hashBuffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(rawIp));
  const ipHash = Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0')).join('');

  // ③ レート制限チェック
  const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString();
  const { count, error: countError } = await supabase
    .from('email_check_rate_limits')
    .select('*', { count: 'exact', head: true })
    .eq('ip_hash', ipHash)
    .gte('created_at', windowStart);

  if (countError) {
    console.warn('[checkEmailExists] Rate limit table error (continuing):', countError.message);
  }

  if ((count ?? 0) >= RATE_LIMIT_MAX) {
    console.warn('[checkEmailExists] Rate limit exceeded for ip_hash:', ipHash.slice(0, 8));
    return new Response(
      JSON.stringify({ error: 'Too many requests' }),
      { status: 429, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // ④ リクエスト記録
  const { error: insertError } = await supabase
    .from('email_check_rate_limits')
    .insert({ ip_hash: ipHash });
  if (insertError) {
    console.warn('[checkEmailExists] Rate limit insert error (continuing):', insertError.message);
  }

  // ⑤ 古いレコードのクリーンアップ（best effort）
  const cleanupCutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  supabase.from('email_check_rate_limits').delete().lt('created_at', cleanupCutoff);

  // ⑥ メールアドレスの重複チェック
  const { data: exists, error: rpcError } = await supabase
    .rpc('check_signup_email_exists', { input_email: email });

  if (rpcError) {
    console.error('[checkEmailExists] RPC error:', rpcError.message);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  console.log('[checkEmailExists] result: exists =', exists);

  return new Response(
    JSON.stringify({ exists }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
