-- ============================================================
-- Migration: add_quality_tier_and_admin_rls
-- Date: 2026-04-04
-- 1. Add quality_tier to applications (approval scoring for matching algorithm)
-- 2. Fix admin RLS policies — correct JSON path to user_metadata
-- 3. Add admin policies for identity_verifications + verification-photos storage
-- ============================================================

-- ── 1. quality_tier on applications ──────────────────────────────────────────
--
--   S = 頂標 (top tier, elite)
--   A = 前標 (above average)
--   B = 均標 (standard pass)
--
--   Set by admin on approval. Used by future matching algorithm for score weighting.

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS quality_tier TEXT
    CHECK (quality_tier IN ('S', 'A', 'B'));

-- ── 2. Fix admin RLS on applications ─────────────────────────────────────────
--
-- Bug: `auth.jwt() ->> 'user_role'` returns NULL because Supabase embeds
-- user_metadata one level deep in the JWT payload.
-- Fix: `auth.jwt() -> 'user_metadata' ->> 'user_role'`

DROP POLICY IF EXISTS "admins_read_all_applications" ON applications;
CREATE POLICY "admins_read_all_applications"
  ON applications FOR SELECT
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

DROP POLICY IF EXISTS "admins_update_applications" ON applications;
CREATE POLICY "admins_update_applications"
  ON applications FOR UPDATE
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- ── 3. Admin access to identity_verifications ─────────────────────────────────

CREATE POLICY "admins_select_identity_verifications"
  ON identity_verifications FOR SELECT
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

CREATE POLICY "admins_update_identity_verifications"
  ON identity_verifications FOR UPDATE
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');

-- ── 4. Fix storage admin policies ────────────────────────────────────────────

-- application-photos: drop old (broken) policy and recreate with correct path
DROP POLICY IF EXISTS "admins_read_all_application_photos" ON storage.objects;
CREATE POLICY "admins_read_all_application_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'application-photos' AND
    (auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin'
  );

-- verification-photos: new admin read policy
DROP POLICY IF EXISTS "admins_read_all_verification_photos" ON storage.objects;
CREATE POLICY "admins_read_all_verification_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'verification-photos' AND
    (auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin'
  );

-- profile-photos: admin can manage (for is_verified tagging)
DROP POLICY IF EXISTS "admins_manage_profile_photos" ON storage.objects;
CREATE POLICY "admins_manage_profile_photos"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'profile-photos' AND
    (auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin'
  );

-- profile_photos table: admin full access (for is_verified tagging)
CREATE POLICY "admins_manage_profile_photos_table"
  ON profile_photos FOR ALL
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');
