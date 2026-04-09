-- ============================================================
-- Migration: reapply_no_cooldown_max_3
-- Date: 2026-04-08
-- Changes:
--   1. Add RLS policy so users can reapply (update own rejected → pending)
--   2. Enforce max 3 application attempts via trigger
-- ============================================================

-- ── 1. User reapply RLS policy ────────────────────────────────────────────────
--
-- Previously missing: users had no UPDATE policy on applications,
-- so the reapply call was silently blocked by RLS.
-- Scope is narrow: only allowed when current status = 'rejected',
-- and the resulting row must have status = 'pending'.

CREATE POLICY "users_reapply_own_application"
  ON applications FOR UPDATE
  USING  (auth.uid() = user_id AND status = 'rejected')
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- ── 2. Enforce max 3 attempts in the reapply trigger ─────────────────────────
--
-- application_count starts at 1 on first submission and increments
-- each time status transitions rejected → pending.
-- After the 3rd rejection (application_count = 3), no further reapply
-- is allowed: the trigger raises an exception before the increment.

CREATE OR REPLACE FUNCTION increment_application_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.status = 'rejected'
     AND NEW.status = 'pending' THEN

    IF OLD.application_count >= 3 THEN
      RAISE EXCEPTION 'max_reapply_attempts_reached'
        USING HINT = 'This account has used all 3 application attempts.';
    END IF;

    NEW.application_count := OLD.application_count + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
