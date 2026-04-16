-- ============================================================
-- Migration: fix_rls_and_photo_changes
-- Date: 2026-04-10
-- 1. Fix broken admin RLS on reports (initial schema used wrong JWT path)
-- 2. Fix broken admin RLS on app_config (same bug)
-- 3. Add admin UPDATE policy on profiles (needed for photo change approval)
-- 4. Add photo_change_requests table (for approved users changing profile photos)
--
-- All statements are idempotent (safe to re-run).
-- ============================================================

-- ── 1. Fix reports admin policy ───────────────────────────────────────────────
--
-- Bug: initial schema used `auth.jwt() ->> 'user_role'` which returns NULL
-- because Supabase nests user_metadata one level deep in the JWT.
-- Fix: `auth.jwt() -> 'user_metadata' ->> 'user_role'`

DROP POLICY IF EXISTS "admins_manage_reports" ON reports;
CREATE POLICY "admins_manage_reports"
  ON reports FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- ── 2. Fix app_config admin write policy ──────────────────────────────────────
--
-- Same bug as above. SELECT is fine (TO authenticated), but ALL/INSERT/UPDATE
-- were silently failing for admins.

DROP POLICY IF EXISTS "admins_manage_app_config" ON app_config;
CREATE POLICY "admins_manage_app_config"
  ON app_config FOR ALL
  USING  ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- ── 3. Admin UPDATE policy on profiles ────────────────────────────────────────
--
-- Required for photo change approval: admin needs to update profiles.photo_paths
-- when approving a user's photo change request.

DROP POLICY IF EXISTS "admins_update_profiles" ON profiles;
CREATE POLICY "admins_update_profiles"
  ON profiles FOR UPDATE
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- ── 4. photo_change_requests table ────────────────────────────────────────────
--
-- Tracks requests from already-approved users who want to change their profile
-- photos. Admin reviews the selfie vs the original identity verification to
-- confirm it is the same person before approving the photo swap.

CREATE TABLE IF NOT EXISTS photo_change_requests (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References profiles (not auth.users) — only approved users have a profile
  user_id         UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- New photos the user wants to use (paths in profile-photos bucket)
  -- Convention: profile-photos/{user_id}/pending/{timestamp}_{index}.jpg
  new_photo_paths TEXT[]      NOT NULL,

  -- Selfie submitted to confirm identity (path in verification-photos bucket)
  -- Convention: verification-photos/{user_id}/photo-change/{timestamp}.jpg
  selfie_path     TEXT        NOT NULL,

  -- Review state
  status          TEXT        NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by     UUID,       -- admin user_id who took action
  reviewed_at     TIMESTAMPTZ,
  review_note     TEXT,       -- internal note (not shown to user in v1)

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- auto-update updated_at (drop first so re-runs are safe)
DROP TRIGGER IF EXISTS photo_change_requests_updated_at ON photo_change_requests;
CREATE TRIGGER photo_change_requests_updated_at
  BEFORE UPDATE ON photo_change_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS (enabling twice is a no-op)
ALTER TABLE photo_change_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_photo_change"         ON photo_change_requests;
DROP POLICY IF EXISTS "admins_manage_photo_change_requests"   ON photo_change_requests;

-- User can only see and manage their own request
CREATE POLICY "users_manage_own_photo_change"
  ON photo_change_requests FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin can read and update all requests
CREATE POLICY "admins_manage_photo_change_requests"
  ON photo_change_requests FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_photo_change_status
  ON photo_change_requests(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_photo_change_user_id
  ON photo_change_requests(user_id);
