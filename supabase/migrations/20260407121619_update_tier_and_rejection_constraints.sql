-- Migration: update_tier_and_rejection_constraints
-- 1. quality_tier: 'S'|'A'|'B' → 'top'|'standard'
-- 2. rejection_type: 'potential'|'soft'|'hard' → 'soft'|'hard'

-- ── 1. quality_tier ───────────────────────────────────────────────────────────
-- Migrate existing values: S→top, A→top, B→standard
UPDATE applications SET quality_tier = 'top'      WHERE quality_tier IN ('S', 'A');
UPDATE applications SET quality_tier = 'standard'  WHERE quality_tier = 'B';

ALTER TABLE applications
  DROP CONSTRAINT IF EXISTS applications_quality_tier_check;

ALTER TABLE applications
  ADD CONSTRAINT applications_quality_tier_check
    CHECK (quality_tier IN ('top', 'standard'));

-- ── 2. rejection_type ─────────────────────────────────────────────────────────
-- Migrate existing values: potential→soft
UPDATE applications SET rejection_type = 'soft' WHERE rejection_type = 'potential';

ALTER TABLE applications
  DROP CONSTRAINT IF EXISTS applications_rejection_type_check;

ALTER TABLE applications
  ADD CONSTRAINT applications_rejection_type_check
    CHECK (rejection_type IN ('soft', 'hard'));
