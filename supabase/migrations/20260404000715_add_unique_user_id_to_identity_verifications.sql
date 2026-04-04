-- ============================================================
-- Migration: add_unique_user_id_to_identity_verifications
-- Date: 2026-04-04
-- identity_verifications.user_id 加上 UNIQUE constraint，
-- 讓 upsert onConflict: 'user_id' 可正常運作（每人只能有一筆驗證記錄）
-- ============================================================

ALTER TABLE identity_verifications
  ADD CONSTRAINT identity_verifications_user_id_unique UNIQUE (user_id);
