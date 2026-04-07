// Supabase Edge Function: review-application
//
// 審核用戶申請 — 後台呼叫
// POST /functions/v1/review-application
//
// Headers:
//   Authorization: Bearer <admin_session_jwt>
//   Content-Type: application/json
//
// Body (approve):
//   { "application_id": "uuid", "action": "approve", "quality_tier": "S"|"A"|"B",
//     "review_note": "...", "review_started_at": "iso8601" }
//
// Body (reject):
//   { "application_id": "uuid", "action": "reject", "rejection_type": "potential"|"soft"|"hard",
//     "review_note": "...", "review_started_at": "iso8601" }
//
// 需要設定的 Supabase Secrets:
//   FIREBASE_PROJECT_ID, FIREBASE_SERVICE_ACCOUNT_KEY  (FCM, from send-fcm-notification)
//   GMAIL_USER=your-gmail@gmail.com                     (Email)
//   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx              (Gmail App 密碼，非登入密碼)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Types ─────────────────────────────────────────────────────────────────────

interface ReviewBody {
  application_id: string
  action: 'approve' | 'reject'
  quality_tier?: 'top' | 'standard'
  rejection_type?: 'soft' | 'hard'
  review_note?: string
  review_started_at?: string
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function reapplyAfter(rejectionType: string): string | null {
  const now = new Date()
  switch (rejectionType) {
    case 'soft': {
      const d = new Date(now); d.setDate(d.getDate() + 30); return d.toISOString()
    }
    case 'hard': {
      // 永久拒絕：設為 10 年後（App 端不顯示重申請入口）
      const d = new Date(now); d.setFullYear(d.getFullYear() + 10); return d.toISOString()
    }
    default: return null
  }
}

function buildApproveEmail(displayName: string): { subject: string; html: string } {
  return {
    subject: '恭喜！您已通過 Luko 資格審核',
    html: `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f9f9f9;">
  <div style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;color:#1a1a1a;">
    <p style="font-size:20px;font-weight:600;color:#C9A96E;margin:0 0 24px;">LUKO</p>
    <h1 style="font-size:22px;font-weight:700;margin:0 0 16px;">恭喜，${displayName}！</h1>
    <p style="line-height:1.8;color:#444;margin:0 0 16px;">您的申請已通過我們的資格審核。<br>現在可以開啟 App 開始探索了。</p>
    <p style="font-size:12px;color:#999;margin:32px 0 0;line-height:1.7;">
      Luko 是一個精選制約會社群，每位成員都經過人工審核。<br>
      感謝您成為我們社群的一員。
    </p>
  </div>
</body>
</html>`,
  }
}

function buildRejectEmail(
  displayName: string,
  rejectionType: string,
): { subject: string; html: string } {
  const messages: Record<string, { title: string; body: string }> = {
    soft: {
      title: '感謝您的申請',
      body: `${displayName}，感謝您申請 Luko。<br><br>
        很遺憾，目前暫時無法通過您的審核。<br>
        您可以在 <strong>30 天後</strong>重新提交申請。`,
    },
    hard: {
      title: '感謝您的申請',
      body: `${displayName}，感謝您申請 Luko。<br><br>
        很遺憾，您的申請目前無法通過審核。`,
    },
  }

  const msg = messages[rejectionType] ?? messages.soft

  return {
    subject: '關於您的 Luko 申請',
    html: `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f9f9f9;">
  <div style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;color:#1a1a1a;">
    <p style="font-size:20px;font-weight:600;color:#C9A96E;margin:0 0 24px;">LUKO</p>
    <h1 style="font-size:20px;font-weight:700;margin:0 0 16px;">${msg.title}</h1>
    <p style="line-height:1.8;color:#444;margin:0 0 16px;">${msg.body}</p>
    <p style="font-size:12px;color:#999;margin:32px 0 0;">如有疑問，請聯繫 support@luko.app</p>
  </div>
</body>
</html>`,
  }
}

// ── Gmail SMTP via denomailer ─────────────────────────────────────────────────
//
// 需要設定的 Supabase Secrets:
//   GMAIL_USER=your-gmail@gmail.com
//   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx   ← Gmail App 密碼（非登入密碼）
//
// 取得 App 密碼：Google 帳號 → 安全性 → 兩步驟驗證開啟後 → 應用程式密碼 → 建立

import { SMTPClient } from 'https://deno.land/x/denomailer@1.6.0/mod.ts'

async function sendEmail(
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const gmailUser = Deno.env.get('GMAIL_USER')
  const gmailPass = Deno.env.get('GMAIL_APP_PASSWORD')

  if (!gmailUser || !gmailPass) {
    console.warn('[review-application] GMAIL_USER/GMAIL_APP_PASSWORD not set, skipping email')
    return
  }

  const client = new SMTPClient({
    connection: {
      hostname: 'smtp.gmail.com',
      port: 465,
      tls: true,
      auth: {
        username: gmailUser,
        password: gmailPass,
      },
    },
  })

  try {
    await client.send({
      from: `Luko <${gmailUser}>`,
      to,
      subject,
      html,
    })
  } catch (e) {
    console.error('[review-application] Gmail send failed:', e)
  } finally {
    await client.close()
  }
}

// ── FCM v1 — inlined to avoid function-to-function auth issues ────────────────

interface ServiceAccount {
  client_email: string
  private_key: string
}

async function getFcmAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const signingInput = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })}`

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

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  // Convert ArrayBuffer to base64url without spread (avoids stack overflow for large buffers)
  const sigBytes = new Uint8Array(signatureBuffer)
  let sigBinary = ''
  for (let i = 0; i < sigBytes.length; i++) sigBinary += String.fromCharCode(sigBytes[i])
  const sigB64 = btoa(sigBinary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${signingInput}.${sigB64}`

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

async function sendFcmNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')

  if (!projectId || !serviceAccountRaw) {
    console.warn('[review-application] Firebase secrets not set, skipping FCM')
    return
  }

  // Look up device tokens for this user
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: tokens, error: dbError } = await supabase
    .from('device_tokens')
    .select('token')
    .eq('user_id', userId)

  if (dbError) {
    console.error('[review-application] FCM: DB error fetching tokens:', dbError.message)
    return
  }

  if (!tokens || tokens.length === 0) return

  const serviceAccount: ServiceAccount = JSON.parse(serviceAccountRaw)
  let accessToken: string
  try {
    accessToken = await getFcmAccessToken(serviceAccount)
  } catch (e) {
    console.error('[review-application] FCM: access token error:', e)
    return
  }

  const results = await Promise.allSettled(
    tokens.map(async ({ token }: { token: string }) => {
      const message: Record<string, unknown> = { token, notification: { title, body } }
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
        if (err?.error?.details?.[0]?.errorCode !== 'UNREGISTERED') {
          throw new Error(`FCM error: ${JSON.stringify(err)}`)
        }
      }
    }),
  )

  const failed = results.filter((r) => r.status === 'rejected')
  if (failed.length > 0) {
    console.error('[review-application] FCM: some sends failed:', failed.map((r) => (r as PromiseRejectedResult).reason))
  }
}

// ── CORS ──────────────────────────────────────────────────────────────────────

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info',
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }

  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: CORS_HEADERS })
  }

  // ── 1. Validate admin ───────────────────────────────────────────────────────

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing Authorization' }), { status: 401, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }

  const token = authHeader.slice(7)

  // ── 3. Service-role client for DB operations ────────────────────────────────
  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // ── Verify caller: use anon client + explicit token (most compatible in Deno) ─
  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
  )
  const { data: { user: callerUser }, error: authError } = await anonClient.auth.getUser(token)

  if (authError || !callerUser) {
    console.error('[review-application] getUser error:', authError?.message, '| token prefix:', token.slice(0, 20))
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  if (callerUser.user_metadata?.user_role !== 'admin') {
    return new Response(JSON.stringify({ error: 'Admin access required' }), {
      status: 403,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  // ── 2. Parse body ───────────────────────────────────────────────────────────

  let body: ReviewBody
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }

  const { application_id, action, quality_tier, rejection_type, review_note, review_started_at } = body

  if (!application_id || !action) {
    return new Response(JSON.stringify({ error: 'Missing application_id or action' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }
  if (action === 'approve' && !quality_tier) {
    return new Response(JSON.stringify({ error: "quality_tier required for approve, must be 'top' or 'standard'" }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }
  if (action === 'reject' && !rejection_type) {
    return new Response(JSON.stringify({ error: 'rejection_type required for reject' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }

  // ── 4. Fetch application ────────────────────────────────────────────────────

  const { data: app, error: appError } = await adminDb
    .from('applications')
    .select('*')
    .eq('id', application_id)
    .eq('status', 'pending')
    .single()

  if (appError || !app) {
    return new Response(JSON.stringify({ error: 'Application not found or not pending' }), { status: 404, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }

  const now = new Date().toISOString()

  // Review duration (seconds)
  const reviewDuration = review_started_at
    ? Math.round((Date.now() - new Date(review_started_at).getTime()) / 1000)
    : null

  // ── 5. Fetch applicant email from Auth ──────────────────────────────────────

  let applicantEmail: string | null = null
  try {
    const { data: { user: authUser } } = await adminDb.auth.admin.getUserById(app.user_id)
    applicantEmail = authUser?.email ?? null
  } catch (e) {
    console.warn('[review-application] Could not fetch auth user email:', e)
  }

  // ── 6A. APPROVE ─────────────────────────────────────────────────────────────

  if (action === 'approve') {
    // a) Update application
    const { error: updateErr } = await adminDb.from('applications').update({
      status: 'approved',
      quality_tier,
      review_note: review_note ?? null,
      reviewed_by: callerUser.id,
      reviewed_at: now,
      review_started_at: review_started_at ?? null,
      review_duration_seconds: reviewDuration,
    }).eq('id', application_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
    }

    // b) Copy application photos to profile-photos bucket
    const profilePhotoPaths: string[] = []
    for (let i = 0; i < (app.photo_paths ?? []).length; i++) {
      const appPath = app.photo_paths[i] as string
      const profilePath = `${app.user_id}/${Date.now()}_${i}.jpg`

      try {
        const { data: fileData, error: dlErr } = await adminDb.storage
          .from('application-photos')
          .download(appPath)

        if (!dlErr && fileData) {
          await adminDb.storage
            .from('profile-photos')
            .upload(profilePath, fileData, { contentType: 'image/jpeg', upsert: true })
          profilePhotoPaths.push(profilePath)
        } else {
          // Fallback: keep application-photos path (photos won't be visible to other users
          // until copied, but profile creation can still proceed)
          console.warn(`[review-application] Failed to copy photo ${appPath}:`, dlErr?.message)
        }
      } catch (e) {
        console.warn(`[review-application] Photo copy error for ${appPath}:`, e)
      }
    }

    // c) Create profile (upsert in case of re-review edge case)
    const { error: profileErr } = await adminDb.from('profiles').upsert({
      id: app.user_id,
      display_name: app.display_name,
      birth_date: app.birth_date,
      gender: app.gender,
      bio: app.bio ?? null,
      photo_paths: profilePhotoPaths.length > 0 ? profilePhotoPaths : (app.photo_paths ?? []),
      seeking: app.seeking ?? [],
      is_active: true,
      is_founding_member: true,
      terms_accepted_at: app.terms_accepted_at ?? null,
      privacy_accepted_at: app.privacy_accepted_at ?? null,
    }, { onConflict: 'id' })

    if (profileErr) {
      console.error('[review-application] Profile creation error:', profileErr)
      // Don't fail the whole request — application is already approved
    }

    // d) Create profile_photos entries
    if (profilePhotoPaths.length > 0) {
      for (let i = 0; i < profilePhotoPaths.length; i++) {
        await adminDb.from('profile_photos').upsert({
          user_id: app.user_id,
          storage_path: profilePhotoPaths[i],
          display_order: i,
          is_verified: true,
          verified_at: now,
          verified_by: callerUser.id,
        }, { onConflict: 'user_id, storage_path' })
      }
    }

    // e) Also approve the identity_verification record
    await adminDb.from('identity_verifications').update({
      status: 'approved',
      reviewed_by: callerUser.id,
      reviewed_at: now,
    }).eq('user_id', app.user_id)

    // f) Send notifications
    await sendFcmNotification(
      app.user_id,
      '恭喜！申請通過 🎉',
      '您的 Luko 申請已通過審核，快來探索吧！',
      { type: 'application_approved' },
    )

    if (applicantEmail) {
      const { subject, html } = buildApproveEmail(app.display_name)
      await sendEmail(applicantEmail, subject, html)
    }

    return new Response(
      JSON.stringify({ success: true, action: 'approved', quality_tier }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  // ── 6B. REJECT ──────────────────────────────────────────────────────────────

  if (action === 'reject') {
    const { error: updateErr } = await adminDb.from('applications').update({
      status: 'rejected',
      rejection_type,
      review_note: review_note ?? null,
      reviewed_by: callerUser.id,
      reviewed_at: now,
      review_started_at: review_started_at ?? null,
      review_duration_seconds: reviewDuration,
      reapply_after: reapplyAfter(rejection_type!),
    }).eq('id', application_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
    }

    // FCM notification
    const fcmMessages: Record<string, string> = {
      soft: '目前暫時無法通過，30 天後可重新申請。',
      hard: '很遺憾目前無法通過審核。',
    }

    await sendFcmNotification(
      app.user_id,
      '申請結果通知',
      fcmMessages[rejection_type!] ?? fcmMessages.soft,
      { type: 'application_rejected', rejection_type: rejection_type! },
    )

    if (applicantEmail) {
      const { subject, html } = buildRejectEmail(app.display_name, rejection_type!)
      await sendEmail(applicantEmail, subject, html)
    }

    return new Response(
      JSON.stringify({ success: true, action: 'rejected', rejection_type }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  return new Response(JSON.stringify({ error: 'Unknown action' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
})
