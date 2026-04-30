// Supabase Edge Function: send-announcement
//
// 群發系統公告給所有 active 用戶（INSERT system_messages.type='announcement'）
// 可選同步發送 FCM 推播到手機。
// POST /functions/v1/send-announcement
//
// Auth: --no-verify-jwt（與其他 admin functions 同 pattern）
//
// Body:
//   {
//     "title": string,         // 必填，<= 100
//     "body":  string,         // 必填，<= 5000
//     "include_banned"?: bool, // 預設 false（停權者不發）
//     "push"?: bool            // 預設 false（false=只進收件匣，true=同步 FCM 推播）
//   }
//
// Response: { ok: true, sent: number, push?: { sent, failed, skipped } }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { fanoutToUser } from '../_shared/fcm.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, apikey, x-client-info',
}

const json = (status: number, body: unknown) => new Response(
  JSON.stringify(body),
  { status, headers: { ...CORS, 'Content-Type': 'application/json' } },
)

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
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS })
  if (req.method !== 'POST') return json(405, { error: 'Method Not Allowed' })

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return json(401, { error: 'Missing Authorization' })

  let callerUserId: string
  try {
    callerUserId = decodeJwtSub(authHeader.slice(7))
  } catch {
    return json(401, { error: 'Unauthorized' })
  }

  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: { user: callerUser }, error: callerErr } =
    await adminDb.auth.admin.getUserById(callerUserId)
  if (callerErr || callerUser?.user_metadata?.user_role !== 'admin') {
    return json(403, { error: 'Admin access required' })
  }

  let body: { title?: string; body?: string; include_banned?: boolean; push?: boolean }
  try { body = await req.json() } catch { return json(400, { error: 'Invalid JSON' }) }

  const title = (body.title ?? '').trim()
  const messageBody = (body.body ?? '').trim()
  if (!title || !messageBody) return json(400, { error: 'title and body required' })
  if (title.length > 100)        return json(400, { error: 'title too long (max 100)' })
  if (messageBody.length > 5000) return json(400, { error: 'body too long (max 5000)' })

  const includeBanned = body.include_banned === true
  const pushFcm = body.push === true

  // 撈所有 active 用戶
  let query = adminDb.from('profiles').select('id').eq('is_deleted', false)
  if (!includeBanned) query = query.neq('account_status', 'banned')
  const { data: users, error: usersErr } = await query
  if (usersErr) {
    console.error('[send-announcement] users query error:', usersErr)
    return json(500, { error: 'Failed to fetch users' })
  }
  if (!users || users.length === 0) return json(200, { ok: true, sent: 0 })

  const now = new Date().toISOString()
  const rows = users.map(u => ({
    user_id: u.id as string,
    type: 'announcement',
    title,
    body: messageBody,
    created_at: now,
  }))

  // 批次 INSERT，分 batch 避免單次 payload 過大（每批 1000）
  const BATCH = 1000
  let inserted = 0
  for (let i = 0; i < rows.length; i += BATCH) {
    const slice = rows.slice(i, i + BATCH)
    const { error } = await adminDb.from('system_messages').insert(slice)
    if (error) {
      console.error('[send-announcement] batch insert error:', error)
      return json(500, { error: `Batch ${i / BATCH} failed: ${error.message}`, partial: inserted })
    }
    inserted += slice.length
  }

  // FCM 推播（選用）— 用 fanoutToUser 並行，每用戶尊重 push_enabled
  let pushStats = { sent: 0, failed: 0, skipped: 0 }
  if (pushFcm) {
    const CONCURRENCY = 50
    const fcmPayload = {
      title,
      body: messageBody.length > 200 ? messageBody.slice(0, 197) + '...' : messageBody,
      data: { type: 'announcement' as const },
    }
    for (let i = 0; i < users.length; i += CONCURRENCY) {
      const batch = users.slice(i, i + CONCURRENCY)
      const results = await Promise.allSettled(batch.map((u) =>
        fanoutToUser(adminDb, u.id as string, fcmPayload, { tag: 'announcement' }),
      ))
      for (const r of results) {
        if (r.status === 'fulfilled') {
          pushStats.sent   += r.value.sent
          pushStats.failed += r.value.failed
          if (r.value.skipped) pushStats.skipped += 1
        } else {
          pushStats.failed += 1
        }
      }
    }
  }

  // Audit log
  await adminDb.rpc('log_admin_action', {
    p_admin_id: callerUserId,
    p_action: 'send_announcement',
    p_metadata: {
      title,
      body_length: messageBody.length,
      recipients: inserted,
      include_banned: includeBanned,
      push: pushFcm,
      push_sent: pushFcm ? pushStats.sent : null,
    },
  })

  return json(200, {
    ok: true,
    sent: inserted,
    push: pushFcm ? pushStats : null,
  })
})
