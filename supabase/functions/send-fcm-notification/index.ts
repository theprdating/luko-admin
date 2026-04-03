// Supabase Edge Function: send-fcm-notification
//
// 呼叫方式（from another Edge Function or webhook）：
//   POST /functions/v1/send-fcm-notification
//   Body: { "user_id": "uuid", "title": "...", "body": "...", "data": {} }
//
// 必要 Secrets（supabase secrets set）：
//   FIREBASE_PROJECT_ID=luko-52073
//   FIREBASE_SERVICE_ACCOUNT_KEY=<service account JSON 完整字串>

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── FCM v1 API 所需：用 Service Account 換取 Google OAuth2 Access Token ────
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  }

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const signingInput = `${encode(header)}.${encode(payload)}`

  // 將 PEM private key 轉為 CryptoKey
  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  const jwt =
    signingInput +
    '.' +
    btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

  // 換取 Access Token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const { access_token, error } = await tokenRes.json()
  if (error) throw new Error(`OAuth2 token error: ${error}`)
  return access_token
}

// ── 發送單一 FCM 訊息 ────────────────────────────────────────────────────────
async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const message: Record<string, unknown> = {
    token,
    notification: { title, body },
  }
  if (data) message.data = data

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message }),
    },
  )

  if (!res.ok) {
    const err = await res.json()
    // token 已失效時忽略，其餘拋出
    if (err?.error?.details?.[0]?.errorCode !== 'UNREGISTERED') {
      throw new Error(`FCM send error: ${JSON.stringify(err)}`)
    }
  }
}

interface ServiceAccount {
  client_email: string
  private_key: string
}

interface RequestBody {
  user_id: string
  title: string
  body: string
  data?: Record<string, string>
}

// ── Main handler ─────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')

  if (!projectId || !serviceAccountRaw) {
    return new Response('Missing Firebase secrets', { status: 500 })
  }

  let body: RequestBody
  try {
    body = await req.json()
  } catch {
    return new Response('Invalid JSON', { status: 400 })
  }

  const { user_id, title, body: msgBody, data } = body
  if (!user_id || !title || !msgBody) {
    return new Response('Missing required fields: user_id, title, body', { status: 400 })
  }

  // ── 查詢該用戶的所有 device_tokens ───────────────────────────────────────
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: tokens, error: dbError } = await supabase
    .from('device_tokens')
    .select('token')
    .eq('user_id', user_id)

  if (dbError) {
    return new Response(`DB error: ${dbError.message}`, { status: 500 })
  }

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // ── 取得 FCM Access Token ─────────────────────────────────────────────────
  const serviceAccount: ServiceAccount = JSON.parse(serviceAccountRaw)
  const accessToken = await getAccessToken(serviceAccount)

  // ── 對所有裝置發送（並行）────────────────────────────────────────────────
  const results = await Promise.allSettled(
    tokens.map(({ token }) =>
      sendFcmMessage(accessToken, projectId, token, title, msgBody, data),
    ),
  )

  const failed = results.filter((r) => r.status === 'rejected').length
  const sent = results.length - failed

  return new Response(JSON.stringify({ sent, failed }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
