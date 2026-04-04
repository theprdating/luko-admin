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
  quality_tier?: 'S' | 'A' | 'B'
  rejection_type?: 'potential' | 'soft' | 'hard'
  review_note?: string
  review_started_at?: string
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function reapplyAfter(rejectionType: string): string | null {
  const now = new Date()
  switch (rejectionType) {
    case 'potential': {
      const d = new Date(now); d.setDate(d.getDate() + 14); return d.toISOString()
    }
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
    subject: '🎉 恭喜！您已通過 Luko 資格審核',
    html: `
      <div style="font-family:-apple-system,sans-serif;max-width:480px;margin:0 auto;padding:32px 20px;color:#1a1a1a;">
        <h2 style="color:#C9A96E;margin-bottom:8px;">LUKO</h2>
        <h1 style="font-size:22px;margin-bottom:16px;">恭喜，${displayName}！</h1>
        <p style="line-height:1.7;color:#444;">您的申請已通過我們的資格審核。<br>
        現在可以開啟 App 開始探索了。</p>
        <p style="margin-top:24px;font-size:12px;color:#999;">
          Luko 是一個精選制約會社群，每位成員都經過人工審核。<br>
          感謝您成為我們社群的一員。
        </p>
      </div>
    `,
  }
}

function buildRejectEmail(
  displayName: string,
  rejectionType: string,
): { subject: string; html: string } {
  const messages: Record<string, { title: string; body: string }> = {
    potential: {
      title: '您的申請目前暫未通過',
      body: `${displayName}，您的照片看起來有潛力！<br><br>
        目前由於審核標準，我們暫時無法通過您的申請。<br>
        建議您在 <strong>14 天後</strong>以更完整、更自然的照片重新申請。<br><br>
        小提醒：選用光線充足、表情自然的照片，效果最好。`,
    },
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
    html: `
      <div style="font-family:-apple-system,sans-serif;max-width:480px;margin:0 auto;padding:32px 20px;color:#1a1a1a;">
        <h2 style="color:#C9A96E;margin-bottom:8px;">LUKO</h2>
        <h1 style="font-size:20px;margin-bottom:16px;">${msg.title}</h1>
        <p style="line-height:1.8;color:#444;">${msg.body}</p>
        <p style="margin-top:24px;font-size:12px;color:#999;">
          如有疑問，請聯繫 support@luko.app
        </p>
      </div>
    `,
  }
}

// ── Gmail SMTP via deno-smtp ──────────────────────────────────────────────────
//
// 需要設定的 Supabase Secrets:
//   GMAIL_USER=your-gmail@gmail.com
//   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx   ← Gmail App 密碼（非登入密碼）
//
// 取得 App 密碼：Google 帳號 → 安全性 → 兩步驟驗證開啟後 → 應用程式密碼 → 建立

import { SmtpClient } from 'https://deno.land/x/smtp@v0.7.0/mod.ts'

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

  const client = new SmtpClient()
  try {
    await client.connectTLS({
      hostname: 'smtp.gmail.com',
      port: 465,
      username: gmailUser,
      password: gmailPass,
    })

    await client.send({
      from: `Luko <${gmailUser}>`,
      to,
      subject,
      content: 'text/html',
      html,
    })
  } catch (e) {
    console.error('[review-application] Gmail send failed:', e)
  } finally {
    await client.close()
  }
}

async function sendFcmNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const res = await fetch(`${supabaseUrl}/functions/v1/send-fcm-notification`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${serviceKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ user_id: userId, title, body, data }),
  })

  if (!res.ok) {
    const err = await res.text()
    console.error('[review-application] FCM send failed:', err)
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  // ── 1. Validate admin ───────────────────────────────────────────────────────

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Missing Authorization', { status: 401 })

  const callerToken = authHeader.replace('Bearer ', '')

  // Verify caller's session using anon client
  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
  )
  const { data: { user: callerUser }, error: authError } = await anonClient.auth.getUser(callerToken)

  if (authError || !callerUser) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  if (callerUser.user_metadata?.user_role !== 'admin') {
    return new Response(JSON.stringify({ error: 'Admin access required' }), { status: 403 })
  }

  // ── 2. Parse body ───────────────────────────────────────────────────────────

  let body: ReviewBody
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 })
  }

  const { application_id, action, quality_tier, rejection_type, review_note, review_started_at } = body

  if (!application_id || !action) {
    return new Response(JSON.stringify({ error: 'Missing application_id or action' }), { status: 400 })
  }
  if (action === 'approve' && !quality_tier) {
    return new Response(JSON.stringify({ error: 'quality_tier required for approve' }), { status: 400 })
  }
  if (action === 'reject' && !rejection_type) {
    return new Response(JSON.stringify({ error: 'rejection_type required for reject' }), { status: 400 })
  }

  // ── 3. Service-role client for DB operations ────────────────────────────────

  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // ── 4. Fetch application ────────────────────────────────────────────────────

  const { data: app, error: appError } = await adminDb
    .from('applications')
    .select('*')
    .eq('id', application_id)
    .eq('status', 'pending')
    .single()

  if (appError || !app) {
    return new Response(JSON.stringify({ error: 'Application not found or not pending' }), { status: 404 })
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
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500 })
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
      { headers: { 'Content-Type': 'application/json' } },
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
      return new Response(JSON.stringify({ error: updateErr.message }), { status: 500 })
    }

    // FCM notification
    const fcmMessages: Record<string, string> = {
      potential: '目前暫時無法通過，14 天後可重新嘗試。',
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
      { headers: { 'Content-Type': 'application/json' } },
    )
  }

  return new Response(JSON.stringify({ error: 'Unknown action' }), { status: 400 })
})
