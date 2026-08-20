import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
// https://supabase.com/docs/guides/functions/examples/push-notifications?queryGroups=platform&platform=fcm

// Firebase の認証情報は Supabase Secrets（FIREBASE_SERVICE_ACCOUNT）から読む。
//
// 以前は service-account.json を静的 import していた（公式サンプルの実装）。
// しかしこのファイルは認証情報のため Git 管理外で、CI からは参照できない。
// その結果 Edge Function だけが CI の検証・デプロイ対象から外れ、
// Step 2 の型変更に追従できないまま本番に残る事故につながった（Issue #943）。
//
// 未設定の場合はモジュール初期化時に落とす。
// 「通知していないのに 200 を返す」状態を増やさないため、黙って握りつぶさない。
interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

const rawServiceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
if (!rawServiceAccount) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT is not set')
}
const serviceAccount: ServiceAccount = JSON.parse(rawServiceAccount)

interface Order {
  id: string;
  user_id: string;
  order_id: string;
  created_at: string; // ISO形式の日時文字列
  order_type: number;
  updated_at: string; // ISO形式の日時文字列
  store_number: string;
  pickup_number: string;
  usage: number;
  payment_method: string;
  price_with_tax: number;
  // provided_status_enum: 'pending' | 'preparing' | 'provided' | 'cancelled'
  // （Issue #938 Step 2 で text の '0'/'1'/'2'/'99' から移行）
  provided_status: 'pending' | 'preparing' | 'provided' | 'cancelled';
  price_without_tax: number;
  tax_rate: number;
}

interface WebhookPayload {
  type: 'UPDATE'
  table: string
  record: Order
  schema: 'public'
  old_record: Order
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  // 未受付 → 調理中 に変わったレコードだけが通知対象
  if (payload.old_record.provided_status === 'pending' && payload.record.provided_status === 'preparing') {
    const { data } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token, is_notify')
      .eq('user_id', payload.record.user_id)

    // デバイス未登録の場合
    if (!data || data.length === 0) {
      console.warn('user_fcm_tokens: no records found for user_id', payload.record.user_id);
      return new Response('No data found', { status: 404 })
    }

    // is_notify が true かつ fcm_token が存在するデバイスのみ通知対象
    // （Issue #938 Step 2 で is_notify は integer から boolean になった）
    const notifyTargets = data.filter(d => d.is_notify === true && d.fcm_token)
    if (notifyTargets.length === 0) {
      return new Response('Notify flag is off', { status: 200 })
    }

    const accessToken = await getAccessToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
    })

    // 全デバイスに並列送信
    const results = await Promise.all(
      notifyTargets.map(device => sendFcmNotification(accessToken, device.fcm_token, payload.record))
    )

    return new Response(JSON.stringify(results), {
      headers: { 'Content-Type': 'application/json' },
    })
  } else {
    return new Response(JSON.stringify({}), {
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

const sendFcmNotification = async (
  accessToken: string,
  fcmToken: string,
  order: Order,
): Promise<unknown> => {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: `【受取番号:${order.pickup_number}】`,
            body: '商品のご用意ができました！お待ちしております',
          },
          data: {
            order_id: order.order_id,
          },
        },
      }),
    }
  )

  const resData = await res.json()
  if (res.status < 200 || 299 < res.status) {
    throw resData
  }
  return resData
}

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}