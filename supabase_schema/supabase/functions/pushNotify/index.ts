import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }
// https://supabase.com/docs/guides/functions/examples/push-notifications?queryGroups=platform&platform=fcm

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
  provided_status: string;
  price_without_tax: number;
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

  // 更新前が0で、更新後が1のレコードだった場合は通知対象
  if (payload.old_record.provided_status == '0' && payload.record.provided_status == '1') {
    const { data } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token, is_notify')
      .eq('user_id', payload.record.user_id)

    // デバイス未登録の場合
    if (!data || data.length === 0) {
      console.warn('user_fcm_tokens: no records found for user_id', payload.record.user_id);
      return new Response('No data found', { status: 404 })
    }

    // is_notify == 1 かつ fcm_token が存在するデバイスのみ通知対象
    const notifyTargets = data.filter(d => d.is_notify === 1 && d.fcm_token)
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