// Supabase Edge Function: review-report
//
// 審核 reports，發出處分（warn / ban_temp / ban_perm / dismiss）
// POST /functions/v1/review-report
//
// Auth: --no-verify-jwt（與 review-application、review-photo-change 同 pattern）
//   - decode JWT payload 取 sub
//   - service role client 查 user_metadata.user_role === 'admin'
//   - DB 為唯一授權依據
//
// Body:
//   {
//     "report_id": "uuid",
//     "action": "dismiss" | "warn" | "ban_temp" | "ban_perm",
//     "ban_days"?: number,           // ban_temp 時必填
//     "admin_note"?: string,         // 內部備註，<= 1000
//     "notify_reporter"?: boolean,
//     "notify_reported"?: boolean,
//     "reporter_message"?: string,   // 通知 reporter 的文字（自訂或模板輸出）
//     "reported_message"?: string    // 通知 reported 的文字
//   }
//
// 副作用：
//   1. UPDATE reports.status='actioned' + admin_action + admin_action_expires_at + admin_note
//   2. INSERT user_sanctions（若非 dismiss）
//   3. UPDATE profiles.account_status
//   4. INSERT system_messages（reporter / reported，依 notify_* flag）
//   5. log_admin_action（review_report、issue_sanction）
//   6. ban → 撤銷該 user 的 active session（auth.admin.signOut）

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ReviewReportBody {
  report_id: string
  action: 'dismiss' | 'warn' | 'ban_temp' | 'ban_perm'
  ban_days?: number
  admin_note?: string
  notify_reporter?: boolean
  notify_reported?: boolean
  reporter_message?: string
  reported_message?: string
}

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info',
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

function decodeJwtSub(token: string): string {
  const parts = token.split('.')
  if (parts.length !== 3) throw new Error('malformed JWT')
  const padded = parts[1].replace(/-/g, '+').replace(/_/g, '/')
    + '=='.slice(0, (4 - parts[1].length % 4) % 4)
  const claims = JSON.parse(atob(padded)) as Record<string, unknown>
  const sub = claims.sub as string | undefined
  if (!sub) throw new Error('no sub claim')
  return sub
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'Method Not Allowed' })
  }

  // ── 1. Auth: decode JWT + verify admin via DB ─────────────────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return jsonResponse(401, { error: 'Missing Authorization' })
  }

  let callerUserId: string
  try {
    callerUserId = decodeJwtSub(authHeader.slice(7))
  } catch (e) {
    console.error('[review-report] JWT decode error:', e)
    return jsonResponse(401, { error: 'Unauthorized' })
  }

  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: { user: callerUser }, error: callerErr } =
    await adminDb.auth.admin.getUserById(callerUserId)
  if (callerErr || callerUser?.user_metadata?.user_role !== 'admin') {
    return jsonResponse(403, { error: 'Admin access required' })
  }

  // ── 2. Parse body ──────────────────────────────────────────────────────────
  let body: ReviewReportBody
  try {
    body = await req.json()
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON' })
  }

  const {
    report_id, action,
    ban_days, admin_note,
    notify_reporter = false, notify_reported = false,
    reporter_message, reported_message,
  } = body

  if (!report_id || !action) {
    return jsonResponse(400, { error: 'Missing report_id or action' })
  }
  if (!['dismiss', 'warn', 'ban_temp', 'ban_perm'].includes(action)) {
    return jsonResponse(400, { error: 'Invalid action' })
  }
  if (action === 'ban_temp' && (!ban_days || ban_days <= 0 || ban_days > 365)) {
    return jsonResponse(400, { error: 'ban_temp requires ban_days (1-365)' })
  }
  if (admin_note && admin_note.length > 1000) {
    return jsonResponse(400, { error: 'admin_note too long' })
  }

  // ── 3. Fetch report + verify pending ───────────────────────────────────────
  const { data: report, error: reportErr } = await adminDb
    .from('reports')
    .select('id, reporter_id, reported_id, reason, status, match_id')
    .eq('id', report_id)
    .single()

  if (reportErr || !report) {
    return jsonResponse(404, { error: 'Report not found' })
  }
  if (report.status === 'actioned') {
    return jsonResponse(409, { error: 'Report already actioned' })
  }

  const now = new Date()
  const expiresAt = action === 'ban_temp'
    ? new Date(now.getTime() + (ban_days as number) * 86_400_000).toISOString()
    : null

  const adminActionDb =
      action === 'dismiss'   ? 'dismissed'
    : action === 'warn'      ? 'warned'
    : action === 'ban_temp'  ? 'banned_temp'
                              : 'banned_perm'

  // ── 4. UPDATE report ───────────────────────────────────────────────────────
  const { error: updErr } = await adminDb
    .from('reports')
    .update({
      status: 'actioned',
      reviewed_by: callerUserId,
      reviewed_at: now.toISOString(),
      admin_action: adminActionDb,
      admin_action_expires_at: expiresAt,
      admin_note: admin_note ?? null,
      notify_reporter,
      notify_reported,
    })
    .eq('id', report_id)

  if (updErr) {
    console.error('[review-report] reports update error:', updErr)
    return jsonResponse(500, { error: 'Failed to update report' })
  }

  // ── 5. INSERT user_sanctions（若非 dismiss）─────────────────────────────────
  if (action !== 'dismiss') {
    const sanctionType = action === 'warn' ? 'warning'
                       : action === 'ban_temp' ? 'ban_temp'
                       : 'ban_perm'

    const { error: sErr } = await adminDb.from('user_sanctions').insert({
      user_id: report.reported_id,
      type: sanctionType,
      reason_summary: admin_note ?? `Report-based ${sanctionType}`,
      related_report_id: report_id,
      issued_by: callerUserId,
      expires_at: expiresAt,
    })
    if (sErr) {
      console.error('[review-report] sanctions insert error:', sErr)
      return jsonResponse(500, { error: 'Failed to create sanction' })
    }

    // 6. UPDATE profiles.account_status
    const newStatus = action === 'warn' ? 'warned' : 'banned'
    await adminDb
      .from('profiles')
      .update({ account_status: newStatus })
      .eq('id', report.reported_id)

    // 7. ban → signOut active sessions
    if (action === 'ban_temp' || action === 'ban_perm') {
      try {
        await adminDb.auth.admin.signOut(report.reported_id)
      } catch (e) {
        console.warn('[review-report] signOut warning:', e)
      }
    }
  }

  // ── 8. INSERT system_messages（依 notify_* flag）────────────────────────────
  if (notify_reporter && reporter_message) {
    await adminDb.from('system_messages').insert({
      user_id: report.reporter_id,
      type: 'report_resolved_reporter',
      title: '檢舉處理完成',
      body: reporter_message,
      metadata: { report_id, action },
    })
  }
  if (notify_reported && reported_message && action !== 'dismiss') {
    const sysType = action === 'warn' ? 'warning'
                  : action === 'ban_temp' ? 'sanction_temp'
                  : 'sanction_perm'
    await adminDb.from('system_messages').insert({
      user_id: report.reported_id,
      type: sysType,
      title: action === 'warn' ? '社群規範提醒'
           : action === 'ban_temp' ? '帳號暫時停權'
           : '帳號永久停權',
      body: reported_message,
      metadata: { report_id, expires_at: expiresAt },
    })
  }

  // ── 9. Audit log ──────────────────────────────────────────────────────────
  await adminDb.rpc('log_admin_action', {
    p_admin_id: callerUserId,
    p_action: 'review_report',
    p_target_user_id: report.reported_id,
    p_target_match_id: report.match_id,
    p_target_report_id: report_id,
    p_metadata: { action, ban_days: ban_days ?? null },
  })

  return jsonResponse(200, {
    ok: true,
    action: adminActionDb,
    expires_at: expiresAt,
  })
})
