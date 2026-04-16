// Supabase Edge Function: review-photo-change
//
// 審核已通過用戶的換照請求
// POST /functions/v1/review-photo-change
//
// Headers:
//   Authorization: Bearer <admin_session_jwt>
//   Content-Type: application/json
//
// Body (approve):
//   { "user_id": "uuid", "action": "approve", "review_note": "..." }
//
// Body (reject):
//   { "user_id": "uuid", "action": "reject", "review_note": "..." }
//
// Auth: --no-verify-jwt（同 review-application，DB 驗 admin role）
//
// Approve 流程:
//   1. 讀取 profiles: photo_paths（舊）+ pending_photo_paths（新）
//   2. 差集刪除：storage 中 photo_paths - pending_photo_paths（不再使用的舊照片）
//   3. 刪除 reverify_photo_paths（身份驗證照，審核完畢即可刪）
//   4. 更新 profiles: photo_paths = pending_photo_paths, 清空 pending + reverify, photo_pending_review = false
//   5. 更新 profile_photos table（重建 verified rows）
//   6. FCM: photo_change_approved
//
// Reject 流程:
//   1. 讀取 profiles: photo_paths（現有）+ pending_photo_paths（待刪）
//   2. 差集刪除：storage 中 pending_photo_paths - photo_paths（剛上傳的新照片）
//   3. 刪除 reverify_photo_paths
//   4. 更新 profiles: 清空 pending + reverify, photo_pending_review = false
//   5. FCM: photo_change_rejected（帶 review_note 給用戶）

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Types ─────────────────────────────────────────────────────────────────────

interface ReviewPhotoBody {
  user_id: string
  action: 'approve' | 'reject'
  review_note?: string
}

// ── FCM (inlined from review-application) ─────────────────────────────────────

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
    'pkcs8', binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  )
  const signatureBuffer = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, new TextEncoder().encode(signingInput))
  const sigBytes = new Uint8Array(signatureBuffer)
  let sigBinary = ''
  for (let i = 0; i < sigBytes.length; i++) sigBinary += String.fromCharCode(sigBytes[i])
  const sigB64 = btoa(sigBinary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const jwt = `${signingInput}.${sigB64}`
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
  })
  const { access_token, error } = await tokenRes.json()
  if (error) throw new Error(`OAuth2 token error: ${error}`)
  return access_token
}

async function sendFcmNotification(
  adminDb: ReturnType<typeof createClient>,
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
  if (!projectId || !serviceAccountRaw) {
    console.warn('[review-photo-change] Firebase secrets not set, skipping FCM')
    return
  }
  const { data: tokens } = await adminDb.from('device_tokens').select('token').eq('user_id', userId)
  if (!tokens || tokens.length === 0) return
  const serviceAccount: ServiceAccount = JSON.parse(serviceAccountRaw)
  let accessToken: string
  try { accessToken = await getFcmAccessToken(serviceAccount) } catch (e) {
    console.error('[review-photo-change] FCM access token error:', e); return
  }
  await Promise.allSettled(
    tokens.map(async ({ token }: { token: string }) => {
      const message: Record<string, unknown> = { token, notification: { title, body } }
      if (data) message.data = data
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
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
}

// ── Storage helpers ───────────────────────────────────────────────────────────

/** 刪除 profile-photos bucket 中的路徑列表（忽略個別失敗） */
async function deleteProfilePhotos(
  adminDb: ReturnType<typeof createClient>,
  paths: string[],
): Promise<void> {
  if (paths.length === 0) return
  const { error } = await adminDb.storage.from('profile-photos').remove(paths)
  if (error) {
    console.warn('[review-photo-change] storage remove partial error:', error.message)
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
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: CORS_HEADERS })
  }

  // ── 1. Validate admin (same pattern as review-application) ──────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing Authorization' }), {
      status: 401, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
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
    console.error('[review-photo-change] JWT decode error:', e)
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const adminDb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: { user: callerUser }, error: callerErr } = await adminDb.auth.admin.getUserById(callerUserId)
  if (callerErr || callerUser?.user_metadata?.user_role !== 'admin') {
    return new Response(JSON.stringify({ error: 'Admin access required' }), {
      status: 403, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  // ── 2. Parse body ───────────────────────────────────────────────────────────
  let body: ReviewPhotoBody
  try { body = await req.json() } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const { user_id, action, review_note } = body
  if (!user_id || !action) {
    return new Response(JSON.stringify({ error: 'Missing user_id or action' }), {
      status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  // ── 3. Fetch profile ────────────────────────────────────────────────────────
  const { data: profile, error: profileErr } = await adminDb
    .from('profiles')
    .select('id, display_name, photo_paths, pending_photo_paths, reverify_photo_paths')
    .eq('id', user_id)
    .eq('photo_pending_review', true)
    .single()

  if (profileErr || !profile) {
    return new Response(JSON.stringify({ error: 'Profile not found or not pending review' }), {
      status: 404, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const oldPaths: string[]     = profile.photo_paths          ?? []
  const pendingPaths: string[] = profile.pending_photo_paths  ?? []
  const reverifyPaths: string[] = profile.reverify_photo_paths ?? []
  const now = new Date().toISOString()

  // ── 4A. APPROVE ─────────────────────────────────────────────────────────────
  if (action === 'approve') {
    if (pendingPaths.length === 0) {
      return new Response(JSON.stringify({ error: 'No pending photos to approve' }), {
        status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    // Photos to delete: old ones no longer in the pending set
    const pendingSet = new Set(pendingPaths)
    const toDelete = oldPaths.filter(p => !pendingSet.has(p))

    // a) Update profiles: swap photo_paths, clear pending + reverify flags
    const { error: updateErr } = await adminDb.from('profiles').update({
      photo_paths: pendingPaths,
      pending_photo_paths: [],
      reverify_photo_paths: [],
      photo_pending_review: false,
    }).eq('id', user_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    // b) Rebuild profile_photos table (delete all, re-insert new set as verified)
    await adminDb.from('profile_photos').delete().eq('user_id', user_id)
    if (pendingPaths.length > 0) {
      await Promise.all(pendingPaths.map((storagePath, i) =>
        adminDb.from('profile_photos').upsert({
          user_id,
          storage_path: storagePath,
          display_order: i,
          is_verified: true,
          verified_at: now,
          verified_by: callerUserId,
        }, { onConflict: 'user_id, storage_path' })
      ))
    }

    // c) Storage cleanup (fire-and-forget, don't block response on partial failures)
    Promise.all([
      deleteProfilePhotos(adminDb, toDelete),
      deleteProfilePhotos(adminDb, reverifyPaths),
    ]).catch(e => console.error('[review-photo-change] storage cleanup error:', e))

    // d) FCM notification
    sendFcmNotification(
      adminDb, user_id,
      '照片更換成功 ✓',
      '您的新照片已通過審核並正式生效！',
      { type: 'photo_change_approved' },
    ).catch(e => console.error('[review-photo-change] FCM error:', e))

    return new Response(
      JSON.stringify({ success: true, action: 'approved' }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  // ── 4B. REJECT ──────────────────────────────────────────────────────────────
  if (action === 'reject') {
    // Photos to delete: newly uploaded ones not in current approved set
    const oldSet = new Set(oldPaths)
    const toDelete = pendingPaths.filter(p => !oldSet.has(p))

    // a) Update profiles: clear pending + reverify, keep photo_paths untouched
    const { error: updateErr } = await adminDb.from('profiles').update({
      pending_photo_paths: [],
      reverify_photo_paths: [],
      photo_pending_review: false,
    }).eq('id', user_id)

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    // b) Storage cleanup (fire-and-forget)
    Promise.all([
      deleteProfilePhotos(adminDb, toDelete),
      deleteProfilePhotos(adminDb, reverifyPaths),
    ]).catch(e => console.error('[review-photo-change] storage cleanup error:', e))

    // c) FCM notification（帶管理員備註給用戶看）
    const rejectBody = review_note?.trim()
      ? `審核未通過：${review_note.trim()}`
      : '照片不符合規範，請重新上傳符合條件的照片。'
    sendFcmNotification(
      adminDb, user_id,
      '照片審核未通過',
      rejectBody,
      { type: 'photo_change_rejected', review_note: review_note?.trim() ?? '' },
    ).catch(e => console.error('[review-photo-change] FCM error:', e))

    return new Response(
      JSON.stringify({ success: true, action: 'rejected' }),
      { headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    )
  }

  return new Response(JSON.stringify({ error: 'Unknown action' }), {
    status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
})
