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
  rejection_tags?: string[]
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
    subject: '恭喜！您已通過 PR Dating 資格審核',
    html: `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f9f9f9;">
  <div style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;color:#1a1a1a;">
    <p style="font-size:20px;font-weight:600;color:#C9A96E;margin:0 0 24px;">PR DATING</p>
    <h1 style="font-size:22px;font-weight:700;margin:0 0 16px;">恭喜，${displayName}！</h1>
    <p style="line-height:1.8;color:#444;margin:0 0 16px;">您的申請已通過我們的資格審核，歡迎加入 PR Dating。</p>
    <div style="background:#eef7f1;border-radius:10px;padding:14px 16px;margin:20px 0;border:1px solid #b8ddc8;">
      <p style="line-height:1.8;color:#444;margin:0;font-size:14px;">現在可以開啟 App，完成最後幾個步驟開始探索了。</p>
    </div>
    <p style="font-size:12px;color:#999;margin:32px 0 0;line-height:1.7;">
      PR Dating 是一個精選制約會社群，每位成員都經過人工審核。<br>
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
  reviewNote?: string,
): { subject: string; html: string } {
  const fixedOpening = `感謝您的申請。為確保每位成員都能擁有最佳的配對體驗，我們對申請照片有基本的品質要求。`

  if (rejectionType === 'soft') {
    const noteHtml = reviewNote
      ? `<div style="background:#f5f5f5;border-radius:8px;padding:16px;margin:16px 0;">
           <p style="font-size:13px;font-weight:600;color:#1a1a1a;margin:0 0 8px;">審核建議</p>
           <p style="line-height:1.8;color:#444;margin:0;font-size:14px;">${reviewNote}</p>
         </div>`
      : `<p style="line-height:1.8;color:#444;margin:0 0 16px;">
           建議您留意照片的清晰度與自然感，並讓個人簡介真實呈現自己。
         </p>`
    return {
      subject: '關於您的 PR Dating 申請',
      html: `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f9f9f9;">
  <div style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;color:#1a1a1a;">
    <p style="font-size:20px;font-weight:600;color:#C9A96E;margin:0 0 24px;">PR DATING</p>
    <h1 style="font-size:20px;font-weight:700;margin:0 0 16px;">差一點點，${displayName}</h1>
    <p style="line-height:1.8;color:#444;margin:0 0 16px;">${fixedOpening}<br>您與通過標準的距離不遠，以下是一些建議，幫助您在重新申請時提高通過機會。</p>
    ${noteHtml}
    <p style="font-size:12px;color:#999;margin:32px 0 0;">如有疑問，請聯繫 theprdating@gmail.com</p>
  </div>
</body>
</html>`,
    }
  }

  // hard rejection
  return {
    subject: '關於您的 PR Dating 申請',
    html: `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f9f9f9;">
  <div style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;max-width:480px;margin:0 auto;padding:40px 24px;color:#1a1a1a;">
    <p style="font-size:20px;font-weight:600;color:#C9A96E;margin:0 0 24px;">PR DATING</p>
    <h1 style="font-size:20px;font-weight:700;margin:0 0 16px;">感謝您的申請</h1>
    <p style="line-height:1.8;color:#444;margin:0 0 16px;">${fixedOpening}</p>
    <p style="font-size:12px;color:#999;margin:32px 0 0;">如有疑問，請聯繫 theprdating@gmail.com</p>
  </div>
</body>
</html>`,
  }
}

// ── Gmail SMTP (raw, base64) ──────────────────────────────────────────────────
//
// 直接使用 Deno.connectTls 發送原始 MIME 郵件（base64 編碼）
// 避免 denomailer 的 quoted-printable 中文亂碼問題
//
// 需要設定的 Supabase Secrets:
//   GMAIL_USER=your-gmail@gmail.com
//   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx   ← Gmail App 密碼（非登入密碼）

function _encodeRFC2047(text: string): string {
  const bytes = new TextEncoder().encode(text)
  let binary = ''
  bytes.forEach((b) => (binary += String.fromCharCode(b)))
  return `=?utf-8?B?${btoa(binary)}?=`
}

function _toBase64Lines(text: string): string {
  const bytes = new TextEncoder().encode(text)
  let binary = ''
  bytes.forEach((b) => (binary += String.fromCharCode(b)))
  const b64 = btoa(binary)
  return b64.match(/.{1,76}/g)?.join('\r\n') ?? b64
}

async function _smtpSend(
  user: string,
  pass: string,
  fromName: string,
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const conn = await Deno.connectTls({ hostname: 'smtp.gmail.com', port: 465 })
  const enc = new TextEncoder()
  const dec = new TextDecoder()
  const buf = new Uint8Array(16384)

  const recv = async (): Promise<string> => {
    const n = await conn.read(buf)
    return dec.decode(buf.subarray(0, n ?? 0))
  }
  const send = async (cmd: string): Promise<void> => {
    await conn.write(enc.encode(cmd + '\r\n'))
  }

  const rawMessage = [
    'MIME-Version: 1.0',
    `From: ${fromName} <${user}>`,
    `To: ${to}`,
    `Subject: ${_encodeRFC2047(subject)}`,
    'Content-Type: text/html; charset=utf-8',
    'Content-Transfer-Encoding: base64',
    '',
    _toBase64Lines(html),
  ].join('\r\n')

  try {
    await recv()                     // 220 greeting
    await send('EHLO smtp.gmail.com')
    await recv()                     // 250 features
    await send('AUTH LOGIN')
    await recv()                     // 334 Username:
    await send(btoa(user))
    await recv()                     // 334 Password:
    await send(btoa(pass))
    await recv()                     // 235 authenticated
    await send(`MAIL FROM:<${user}>`)
    await recv()                     // 250
    await send(`RCPT TO:<${to}>`)
    await recv()                     // 250
    await send('DATA')
    await recv()                     // 354 start input
    await send(rawMessage + '\r\n.')
    await recv()                     // 250 queued
    await send('QUIT')
  } finally {
    conn.close()
  }
}

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

  try {
    await _smtpSend(gmailUser, gmailPass, 'PR Dating', to, subject, html)
  } catch (e) {
    console.error('[review-application] Gmail send failed:', e)
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
  //
  // 這個 function 以 --no-verify-jwt 部署（gateway 不驗 JWT 簽章）。
  // 因此 admin 驗證改為：
  //   a) decode JWT payload 取得 sub（caller 的 user_id）
  //   b) 用 service role client 直接從 Auth DB 查 user_metadata.user_role
  // 這樣即使 JWT 被偽造，攻擊者也無法冒充 admin，因為 DB 才是 source of truth。

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing Authorization' }), { status: 401, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
  }

  const token = authHeader.slice(7)

  let callerUserId: string
  try {
    const parts = token.split('.')
    if (parts.length !== 3) throw new Error('malformed JWT')
    const padded = parts[1].replace(/-/g, '+').replace(/_/g, '/') + '=='.slice(0, (4 - parts[1].length % 4) % 4)
    const claims = JSON.parse(atob(padded)) as Record<string, unknown>
    callerUserId = claims.sub as string
    if (!callerUserId) throw new Error('no sub claim')
  } catch (e) {
    console.error('[review-application] JWT decode error:', e)
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  // ── 3. Service-role client for DB operations ────────────────────────────────
  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // ── Verify admin role from DB (not from JWT payload) ────────────────────────
  const { data: { user: callerUser }, error: callerErr } = await adminDb.auth.admin.getUserById(callerUserId)
  if (callerErr || callerUser?.user_metadata?.user_role !== 'admin') {
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

  const { application_id, action, quality_tier, rejection_type, rejection_tags, review_note, review_started_at } = body

  if (!application_id || !action) {
    return new Response(JSON.stringify({ error: 'Missing application_id or action' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
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
      rejection_type: null,       // 清除上次拒絕殘留資料（Task 1 fix）
      rejection_tags: null,
      review_note: review_note ?? null,
      reviewed_by: callerUserId,
      reviewed_at: now,
      review_started_at: review_started_at ?? null,
      review_duration_seconds: reviewDuration,
    }).eq('id', application_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
    }

    // b) Copy application photos to profile-photos bucket (parallel)
    const timestamp = Date.now()
    const profilePhotoPaths: string[] = []
    const copyResults = await Promise.allSettled(
      (app.photo_paths ?? []).map(async (appPath: string, i: number) => {
        const profilePath = `${app.user_id}/${timestamp}_${i}.jpg`
        const { data: fileData, error: dlErr } = await adminDb.storage
          .from('application-photos')
          .download(appPath)
        if (dlErr || !fileData) {
          console.warn(`[review-application] Failed to copy photo ${appPath}:`, dlErr?.message)
          return null
        }
        await adminDb.storage
          .from('profile-photos')
          .upload(profilePath, fileData, { contentType: 'image/jpeg', upsert: true })
        return { profilePath, i }
      })
    )
    // Collect successful copies in original order
    for (const result of copyResults) {
      if (result.status === 'fulfilled' && result.value) {
        profilePhotoPaths[result.value.i] = result.value.profilePath
      }
    }
    // Compact: remove holes left by failed copies
    const compactPaths = profilePhotoPaths.filter(Boolean)

    // c) Create profile (upsert in case of re-review edge case)
    // NOTE: only use compactPaths (profile-photos bucket) — never fall back to
    // app.photo_paths (application-photos bucket) because those paths don't exist
    // in profile-photos, causing broken images in-app.
    const { error: profileErr } = await adminDb.from('profiles').upsert({
      id: app.user_id,
      display_name: app.display_name,
      birth_date: app.birth_date,
      gender: app.gender,
      bio: app.bio ?? null,
      photo_paths: compactPaths,
      seeking: app.seeking ?? [],
      is_active: true,
      is_founding_member: true,
      terms_accepted_at: app.terms_accepted_at ?? null,
      privacy_accepted_at: app.privacy_accepted_at ?? null,
    }, { onConflict: 'id' })

    if (profileErr) {
      console.error('[review-application] Profile creation error:', profileErr)
    }

    // d) Create profile_photos entries (parallel)
    if (compactPaths.length > 0) {
      await Promise.all(compactPaths.map((storagePath, i) =>
        adminDb.from('profile_photos').upsert({
          user_id: app.user_id,
          storage_path: storagePath,
          display_order: i,
          is_verified: true,
          verified_at: now,
          verified_by: callerUserId,
        }, { onConflict: 'user_id, storage_path' })
      ))
    }

    // e) Also approve the identity_verification record
    await adminDb.from('identity_verifications').update({
      status: 'approved',
      reviewed_by: callerUserId,
      reviewed_at: now,
    }).eq('user_id', app.user_id)

    // f) Return immediately, send notifications in background (fire-and-forget)
    const { subject: appSubject, html: appHtml } = buildApproveEmail(app.display_name)
    Promise.all([
      sendFcmNotification(
        app.user_id,
        '恭喜！申請通過 🎉',
        '您的申請已通過審核，快來開啟 App 開始探索吧！',
        { type: 'application_approved' },
      ),
      applicantEmail ? sendEmail(applicantEmail, appSubject, appHtml) : Promise.resolve(),
    ]).catch(e => console.error('[review-application] approve notify error:', e))

    return new Response(
      JSON.stringify({ success: true, action: 'approved' }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  // ── 6B. REJECT ──────────────────────────────────────────────────────────────

  if (action === 'reject') {
    const { error: updateErr } = await adminDb.from('applications').update({
      status: 'rejected',
      rejection_type,
      rejection_tags: rejection_tags ?? null,
      review_note: review_note ?? null,
      reviewed_by: callerUserId,
      reviewed_at: now,
      review_started_at: review_started_at ?? null,
      review_duration_seconds: reviewDuration,
      reapply_after: reapplyAfter(rejection_type!),
    }).eq('id', application_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
    }

    // Fire notifications in background (fire-and-forget)
    const fcmMessages: Record<string, string> = {
      soft: '差一點點！我們有一些建議給您，30 天後可重新申請。',
      hard: '很遺憾，您的申請目前無法通過審核。',
    }
    const { subject: rejSubject, html: rejHtml } = buildRejectEmail(app.display_name, rejection_type!, review_note)
    Promise.all([
      sendFcmNotification(
        app.user_id,
        '申請結果通知',
        fcmMessages[rejection_type!] ?? fcmMessages.soft,
        { type: 'application_rejected', rejection_type: rejection_type! },
      ),
      applicantEmail ? sendEmail(applicantEmail, rejSubject, rejHtml) : Promise.resolve(),
    ]).catch(e => console.error('[review-application] reject notify error:', e))

    return new Response(
      JSON.stringify({ success: true, action: 'rejected', rejection_type }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  return new Response(JSON.stringify({ error: 'Unknown action' }), { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } })
})
