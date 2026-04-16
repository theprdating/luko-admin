-- ============================================================
-- Migration: pending_photo_paths
-- Date: 2026-04-16
--
-- Problem:
--   edit_reverify_page.dart previously overwrote profiles.photo_paths
--   immediately when the user submitted a photo change. This meant
--   the admin panel had no way to compare old vs new photos.
--
-- Solution: separate "pending" column
--   - New photos go to pending_photo_paths (not photo_paths)
--   - photo_paths stays unchanged (current approved photos)
--   - On admin approve  → copy pending_photo_paths → photo_paths
--   - On admin reject   → discard pending_photo_paths
--
-- Also:
--   - Add admin SELECT policy on profiles (needed for photo review queue)
-- ============================================================

-- ── 1. Add pending_photo_paths ────────────────────────────────────────────────

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS pending_photo_paths TEXT[] NOT NULL DEFAULT '{}';

-- ── 2. Admin SELECT policy on profiles ───────────────────────────────────────
--
-- The admin panel JS queries profiles directly (anon client + admin JWT).
-- Without this policy, SELECT returns 0 rows even for admins.

DROP POLICY IF EXISTS "admins_select_profiles" ON profiles;
CREATE POLICY "admins_select_profiles"
  ON profiles FOR SELECT
  USING ((auth.jwt() -> 'user_metadata' ->> 'user_role') = 'admin');
