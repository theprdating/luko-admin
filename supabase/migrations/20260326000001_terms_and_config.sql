-- ============================================================
-- Luko — Terms Acceptance & App Config
-- Created: 2026-03-26
-- ============================================================

-- ── 1. app_config（全域設定，儲存條款版本時間戳）──────────────────────────────

CREATE TABLE app_config (
  key        TEXT        PRIMARY KEY,
  value      TEXT        NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 初始條款版本
INSERT INTO app_config (key, value) VALUES
  ('terms_updated_at',   '2026-03-26T00:00:00Z'),
  ('privacy_updated_at', '2026-03-26T00:00:00Z');

-- app_config 對已登入用戶公開讀取，只有 admin 可寫
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_app_config"
  ON app_config FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "admins_manage_app_config"
  ON app_config FOR ALL
  USING (auth.jwt() ->> 'user_role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'user_role' = 'admin');

-- ── 2. applications — 新增條款接受時間戳 ────────────────────────────────────
--
-- 用途：Step 5「確認送出」時記錄用戶接受了哪個版本的條款
-- 後續審核通過時，這個值會複製到 profiles.terms_accepted_at

ALTER TABLE applications
  ADD COLUMN terms_accepted_at   TIMESTAMPTZ,
  ADD COLUMN privacy_accepted_at TIMESTAMPTZ;

-- ── 3. profiles — 新增條款接受時間戳 ────────────────────────────────────────
--
-- 用途：App 啟動時比對此值 vs app_config.terms_updated_at
-- 若 terms_accepted_at < terms_updated_at → 強制重新接受

ALTER TABLE profiles
  ADD COLUMN terms_accepted_at   TIMESTAMPTZ,
  ADD COLUMN privacy_accepted_at TIMESTAMPTZ;

-- ── 4. 審核通過時自動複製條款接受時間戳的 Function ───────────────────────────
--
-- 當 applications.status 被更新為 'approved' 並建立 profiles 時，
-- 後端（Edge Function）負責呼叫此邏輯，
-- 這裡提供一個 helper function 供 Edge Function 使用

CREATE OR REPLACE FUNCTION copy_terms_to_profile(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET
    terms_accepted_at   = (SELECT terms_accepted_at   FROM applications WHERE user_id = p_user_id),
    privacy_accepted_at = (SELECT privacy_accepted_at FROM applications WHERE user_id = p_user_id)
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
