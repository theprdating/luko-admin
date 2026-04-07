// ── Luko Admin — Shared utilities ────────────────────────────────────────────
//
// 1. Fill in SUPABASE_ANON_KEY before deploying.
//    Get it from: Supabase Dashboard → Project Settings → API → anon public key
//
// 2. Set admin user_metadata in Supabase Dashboard:
//    Authentication → Users → [admin user] → Edit → Raw user meta data:
//    { "user_role": "admin" }

const SUPABASE_URL     = 'https://xzqwzpwpjofpkbewkwzx.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6cXd6cHdwam9mcGtiZXdrd3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3Nzc4NzUsImV4cCI6MjA5MDM1Mzg3NX0.xBHOJFqZfOZTe7GCxAHv5BQkJAUShzUqpg_ZOPSbecM'  // ← fill this in

const { createClient } = supabase
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// ── Auth ──────────────────────────────────────────────────────────────────────

async function requireAdmin() {
  const { data: { session } } = await db.auth.getSession()
  if (!session) {
    window.location.href = 'index.html'
    throw new Error('Not authenticated')
  }
  const user = session.user
  if (user.user_metadata?.user_role !== 'admin') {
    await db.auth.signOut()
    window.location.href = 'index.html?error=unauthorized'
    throw new Error('Not admin')
  }
  return { session, user }
}

async function signOut() {
  await db.auth.signOut()
  window.location.href = 'index.html'
}

// Returns a fresh access token, refreshing the session if needed.
// Redirects to login if the session cannot be recovered.
async function getFreshToken() {
  // First try to refresh (forces a new JWT from the server)
  const { data: refreshed } = await db.auth.refreshSession()
  if (refreshed?.session?.access_token) return refreshed.session.access_token

  // Fallback: use existing session (covers cases where refresh is redundant)
  const { data: { session } } = await db.auth.getSession()
  if (session?.access_token) return session.access_token

  // Session is gone — redirect to login
  window.location.href = 'index.html?error=session_expired'
  throw new Error('Session expired')
}

// ── XSS protection ───────────────────────────────────────────────────────────
//
// Always use escapeHtml() before inserting user-controlled data into innerHTML.
// Never use innerHTML with raw DB values — display_name, bio, review_note, etc.
// can contain <script> tags or event handlers if not escaped.

function escapeHtml(str) {
  if (str == null) return ''
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

// ── Toast ─────────────────────────────────────────────────────────────────────

function showToast(message, type = 'info', duration = 4500) {
  const container = document.getElementById('toast-container')
  if (!container) return
  const el = document.createElement('div')
  el.className = `toast toast-${type}`
  el.textContent = message
  container.appendChild(el)
  setTimeout(() => {
    el.style.opacity = '0'
    el.style.transform = 'translateY(6px)'
    el.style.transition = 'all 0.25s'
    setTimeout(() => el.remove(), 260)
  }, duration)
}

// ── Date helpers ──────────────────────────────────────────────────────────────

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1)  return '剛才'
  if (mins < 60) return `${mins} 分鐘前`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24)  return `${hrs} 小時前`
  const days = Math.floor(hrs / 24)
  return `${days} 天前`
}

function formatDate(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}/${pad(d.getMonth()+1)}/${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function calcAge(birthDateStr) {
  if (!birthDateStr) return '?'
  const birth = new Date(birthDateStr)
  const now   = new Date()
  let age = now.getFullYear() - birth.getFullYear()
  const m = now.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--
  return age
}

// ── Label maps ────────────────────────────────────────────────────────────────

const GENDER_LABELS = { male: '男', female: '女', other: '其他' }

const SEEKING_LABELS = {
  male:     '尋找男性',
  female:   '尋找女性',
  everyone: '不限',
}

const ACTION_LABELS = {
  smile:          '微笑',
  blink:          '眨眼',
  openMouth:      '張嘴',
  raiseRightHand: '舉右手',
  raiseLeftHand:  '舉左手',
  wave:           '揮手',
  thumbsUp:       '比讚',
  touchNose:      '摸鼻子',
  crossArms:      '交叉雙臂',
  tiltHead:       '頭傾向一側',
}

const REJECTION_TYPE_LABELS = {
  potential: '潛力可等',
  soft:      '差一點',
  hard:      '不通過',
}

function actionLabel(code) {
  return ACTION_LABELS[code] || code || '未知動作'
}

// ── Signed URL helper ─────────────────────────────────────────────────────────

async function getSignedUrl(bucket, path, expiresIn = 3600) {
  if (!path) return null
  const { data, error } = await db.storage.from(bucket).createSignedUrl(path, expiresIn)
  if (error) { console.warn(`getSignedUrl(${bucket}, ${path}):`, error.message); return null }
  return data?.signedUrl ?? null
}

// ── Active nav link ───────────────────────────────────────────────────────────

function setActiveNavLink() {
  const current = window.location.pathname.split('/').pop() || 'index.html'
  document.querySelectorAll('.nav-link').forEach(link => {
    const href = link.getAttribute('href')
    if (href === current) link.classList.add('active')
  })
}
