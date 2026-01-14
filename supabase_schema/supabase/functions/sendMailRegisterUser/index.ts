import { createClient } from 'npm:@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const TEST_MAIL_ADDRESS = Deno.env.get('TEST_MAIL_ADDRESS');
const HOSTING_DOMEIN = Deno.env.get('HOSTING_DOMEIN');

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const handler = async (req) => {
  // テーブルからURLを取得
  const payload = await req.json();
  console.log('payload', payload);
  const token = payload.record.token;
  const registrationUrl = `https://${HOSTING_DOMEIN}/register?token=${token}`;

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${RESEND_API_KEY}`
    },
    body: JSON.stringify({
      from: 'onboarding@resend.dev',
      to: `${TEST_MAIL_ADDRESS}`,
      subject: '会員登録手続きのご案内',
      html: `
      <p>このたびは会員登録いただきまして、<br>
      誠にありがとうございます。</p>
  
      <p>登録の手続きはまだ完了していません。<br>
      以下のURLをタップし、登録手続きを行ってください。</p>
  
      <p>■URL<br>
      <a href="${registrationUrl}">${registrationUrl}</a></p>
    `
    })
  });
  const data = await res.json();
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: {
      'Content-Type': 'application/json'
    }
  });
};
Deno.serve(handler);
