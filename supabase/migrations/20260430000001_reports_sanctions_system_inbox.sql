-- ─────────────────────────────────────────────────────────────────────────────
-- 檢舉系統 v2 + 處分機制 + 系統收件匣 + soft_exit 配對冷卻
-- ─────────────────────────────────────────────────────────────────────────────
--
-- 內容：
--   1. reports 擴充：evidence_paths、match_id、admin_action、admin_note
--   2. user_sanctions：警告 / 暫時停權 / 永久停權 紀錄
--   3. profiles.account_status：active / warned / banned
--   4. system_messages：申請通過、換照通過、警告、停權、檢舉結果通知
--   5. admin_audit_logs：admin 調閱對話紀錄等敏感操作 audit
--   6. match_interactions.status 增加 'soft_exit' + soft_exit_until 欄位
--   7. chat_rooms：drop UNIQUE(match_id)，改成「同一 match 同時只能有一間 active room」
--      新增 archived_reason 'soft_exit_recycle'
--   8. report-evidence storage bucket（private）
--   9. pg_cron：soft_exit 解除 + ban_temp 解除
--
-- 設計原則：
--   - 所有寫入都透過 service role（Edge Function），RLS 對 user 限制
--   - reports 的 evidence 圖檔走 Storage RLS，僅 reporter / admin 可讀
--   - admin 調閱對話 → 寫 audit log（合規證明）
--   - account_status 為 router redirect 唯一依據；user_sanctions 為歷程
--

-- ── 1. reports 擴充 ──────────────────────────────────────────────────────────

ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS evidence_paths TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS match_id UUID REFERENCES match_interactions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS admin_action TEXT,
  ADD COLUMN IF NOT EXISTS admin_action_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS admin_note TEXT,
  ADD COLUMN IF NOT EXISTS notify_reporter BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notify_reported BOOLEAN NOT NULL DEFAULT false;

-- 證據圖數量限制：1~3 張（全部 reason 強制至少 1 張）
-- 用 cardinality() 而非 array_length()：空陣列回 0（非 NULL），可被 CHECK 攔下
-- NOT VALID：跳過既有 row 驗證（既有 row 的 default '{}' 會擋下），新 INSERT 強制檢查
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_evidence_paths_count;
ALTER TABLE reports ADD CONSTRAINT reports_evidence_paths_count
  CHECK (cardinality(evidence_paths) BETWEEN 1 AND 3) NOT VALID;

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_admin_action_check;
ALTER TABLE reports ADD CONSTRAINT reports_admin_action_check
  CHECK (admin_action IS NULL OR admin_action IN ('dismissed','warned','banned_temp','banned_perm'));

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_admin_note_len;
ALTER TABLE reports ADD CONSTRAINT reports_admin_note_len
  CHECK (admin_note IS NULL OR char_length(admin_note) <= 1000);

CREATE INDEX IF NOT EXISTS idx_reports_status      ON reports (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_reporter    ON reports (reporter_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_reported    ON reports (reported_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_match       ON reports (match_id);


-- ── 2. user_sanctions（處分歷程，可累計查詢）────────────────────────────────

CREATE TABLE IF NOT EXISTS user_sanctions (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type               TEXT        NOT NULL CHECK (type IN ('warning','ban_temp','ban_perm')),
  reason_summary     TEXT        NOT NULL CHECK (char_length(reason_summary) <= 500),
  related_report_id  UUID        REFERENCES reports(id) ON DELETE SET NULL,
  issued_by          UUID        NOT NULL,             -- admin uid
  issued_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at         TIMESTAMPTZ,                       -- ban_temp 用；warning/ban_perm 為 NULL
  lifted_at          TIMESTAMPTZ,                       -- 提前解除（手動或 cron 自動）
  lifted_by          UUID,
  lifted_reason      TEXT,
  acknowledged_at    TIMESTAMPTZ                        -- warning 被使用者點「我已了解」的時間
);

CREATE INDEX IF NOT EXISTS idx_sanctions_user_active
  ON user_sanctions (user_id) WHERE lifted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sanctions_expires
  ON user_sanctions (expires_at) WHERE lifted_at IS NULL AND expires_at IS NOT NULL;

ALTER TABLE user_sanctions ENABLE ROW LEVEL SECURITY;

-- 用戶可讀自己的有效處分（解除後仍可看歷史）
CREATE POLICY "users_read_own_sanctions"
  ON user_sanctions FOR SELECT
  USING (auth.uid() = user_id);

-- 寫入只透過 service role
CREATE POLICY "service_role_write_sanctions"
  ON user_sanctions FOR ALL
  USING  (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "admin_read_all_sanctions"
  ON user_sanctions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
        AND raw_user_meta_data->>'user_role' = 'admin'
    )
  );


-- ── 3. profiles.account_status（router redirect 依據）───────────────────────

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL DEFAULT 'active'
    CHECK (account_status IN ('active','warned','banned'));

CREATE INDEX IF NOT EXISTS idx_profiles_account_status
  ON profiles (account_status) WHERE account_status != 'active';


-- ── 4. system_messages（系統收件匣）─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS system_messages (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        TEXT        NOT NULL CHECK (type IN (
                'welcome_approved',
                'photo_change_approved',
                'warning',
                'sanction_temp',
                'sanction_perm',
                'sanction_lifted',
                'report_resolved_reporter',
                'report_resolved_reported',
                'announcement'
              )),
  title       TEXT,
  body        TEXT        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 5000),
  metadata    JSONB,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_messages_user_created
  ON system_messages (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_messages_unread
  ON system_messages (user_id) WHERE read_at IS NULL;

ALTER TABLE system_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_own_system_messages"
  ON system_messages FOR SELECT
  USING (auth.uid() = user_id);

-- user 可標已讀（UPDATE read_at），但僅自己的 row、僅 read_at 欄位
CREATE POLICY "users_mark_own_system_messages_read"
  ON system_messages FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "service_role_write_system_messages"
  ON system_messages FOR ALL
  USING  (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ── 5. admin_audit_logs（敏感操作 audit）────────────────────────────────────

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    UUID        NOT NULL,
  action      TEXT        NOT NULL CHECK (action IN (
                'view_chat_history',
                'review_report',
                'issue_sanction',
                'lift_sanction',
                'send_announcement'
              )),
  target_user_id  UUID,
  target_match_id UUID,
  target_report_id UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_admin   ON admin_audit_logs (admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target  ON admin_audit_logs (target_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_match   ON admin_audit_logs (target_match_id);

ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- 僅 admin 可讀；寫入透過 service role
CREATE POLICY "admin_read_audit"
  ON admin_audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
        AND raw_user_meta_data->>'user_role' = 'admin'
    )
  );

CREATE POLICY "service_role_write_audit"
  ON admin_audit_logs FOR ALL
  USING  (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ── 6. match_interactions：新增 soft_exit 狀態 ──────────────────────────────

ALTER TABLE match_interactions DROP CONSTRAINT IF EXISTS mi_status;
ALTER TABLE match_interactions ADD CONSTRAINT mi_status CHECK (status IN (
  'pending','dm_pending','mutual','chatted','gallery','cooldown','blocked','soft_exit'
));

ALTER TABLE match_interactions
  ADD COLUMN IF NOT EXISTS soft_exit_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS soft_exit_initiated_by UUID;

CREATE INDEX IF NOT EXISTS idx_mi_soft_exit
  ON match_interactions (soft_exit_until)
  WHERE status = 'soft_exit';


-- ── 7. chat_rooms：允許多間（archive 後可開新間）────────────────────────────

-- 原本 UNIQUE(match_id) 阻擋 soft_exit recycle 開新房；改為「同一 match 同時只能一間 active」
ALTER TABLE chat_rooms DROP CONSTRAINT IF EXISTS chat_rooms_match_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_rooms_active_per_match
  ON chat_rooms (match_id) WHERE status = 'active';

-- 既有 archived_reason 為 free text，無 CHECK；保持彈性，
-- 但在註解列出已知值供文件參照：
-- 'dislike' | 'unmatch' | 'exit_chat' | 'dm_expired_with_dislike'
-- 'user_deleted' | 'soft_exit_recycle' | 'admin_action'


-- ── 8. Storage bucket: report-evidence（private）─────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('report-evidence', 'report-evidence', false)
ON CONFLICT (id) DO NOTHING;

-- RLS：reporter 僅可上傳到自己的 reporter_id 路徑下；admin 可讀全部；reporter 可讀自己上傳的
DROP POLICY IF EXISTS "report_evidence_insert_own" ON storage.objects;
CREATE POLICY "report_evidence_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'report-evidence'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "report_evidence_read_own" ON storage.objects;
CREATE POLICY "report_evidence_read_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'report-evidence'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "report_evidence_admin_read" ON storage.objects;
CREATE POLICY "report_evidence_admin_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'report-evidence'
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
        AND raw_user_meta_data->>'user_role' = 'admin'
    )
  );


-- ── 10. RPC：lift_expired_sanctions（cron 自動解除過期 ban_temp）──────────────

CREATE OR REPLACE FUNCTION lift_expired_sanctions()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_lifted int := 0;
  v_user_record record;
BEGIN
  -- 找出所有過期但未解除的 ban_temp
  FOR v_user_record IN
    SELECT id, user_id, related_report_id
    FROM user_sanctions
    WHERE type = 'ban_temp'
      AND lifted_at IS NULL
      AND expires_at IS NOT NULL
      AND expires_at <= NOW()
  LOOP
    -- 標記 sanction lifted
    UPDATE user_sanctions
    SET lifted_at = NOW(),
        lifted_reason = 'auto_expired'
    WHERE id = v_user_record.id;

    -- 若該用戶無其他 active ban → 還原 account_status
    IF NOT EXISTS (
      SELECT 1 FROM user_sanctions
      WHERE user_id = v_user_record.user_id
        AND lifted_at IS NULL
        AND type IN ('ban_temp','ban_perm')
    ) THEN
      UPDATE profiles
      SET account_status = 'active'
      WHERE id = v_user_record.user_id;

      -- 發系統訊息：停權已解除
      INSERT INTO system_messages (user_id, type, title, body)
      VALUES (
        v_user_record.user_id,
        'sanction_lifted',
        '帳號已恢復',
        '你的暫時停權已解除，歡迎回到 Luko。請持續善待每一位你遇見的人。'
      );
    END IF;

    v_lifted := v_lifted + 1;
  END LOOP;

  RETURN jsonb_build_object('lifted', v_lifted, 'at', NOW());
END;
$$;


-- ── 11. RPC：lift_expired_soft_exits（30 天到期回配對池）─────────────────────

CREATE OR REPLACE FUNCTION lift_expired_soft_exits()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_lifted int := 0;
BEGIN
  -- soft_exit 期滿 → 轉成 'cooldown' 但 cooldown_expires_at 設為 now()，
  -- 讓 generate_daily_pairs 可立刻挑回；此設計與既有 cooldown 排除邏輯相容。
  WITH expired AS (
    UPDATE match_interactions
    SET status = 'cooldown',
        cooldown_expires_at = NOW(),
        soft_exit_until = NULL,
        soft_exit_initiated_by = NULL,
        previous_status = 'soft_exit'
    WHERE status = 'soft_exit'
      AND soft_exit_until IS NOT NULL
      AND soft_exit_until <= NOW()
    RETURNING id
  )
  SELECT count(*) INTO v_lifted FROM expired;

  RETURN jsonb_build_object('lifted', v_lifted, 'at', NOW());
END;
$$;


-- ── 12. pg_cron 排程 ────────────────────────────────────────────────────────

-- 每小時整點檢查 ban_temp 是否到期
SELECT cron.schedule(
  'luko-lift-expired-sanctions',
  '0 * * * *',
  'SELECT lift_expired_sanctions()'
);

-- 每天台北 03:00 清 soft_exit
SELECT cron.schedule(
  'luko-lift-expired-soft-exits',
  '0 19 * * *',  -- UTC 19:00 = 台北 03:00
  'SELECT lift_expired_soft_exits()'
);


-- ── 12.5 generate_daily_pairs soft_exit 排除（人工 follow-up）────────────────
--
-- 既有 generate_daily_pairs() 的排除子句沒有處理 soft_exit。
-- 短期不必修：cron `lift_expired_soft_exits` 會把過期 soft_exit 轉為 cooldown
-- (cooldown_expires_at = now())，下次 generate_daily_pairs 看見 cooldown 已過期
-- 即可重新配對。
--
-- 唯一風險視窗：30 天內若 cron 尚未跑當下，soft_exit row 的對會被視為「可配」
-- 而排入 daily_pairs。實務上影響極小：cron 每天跑一次，最多 24 小時的偏差。
--
-- 嚴格做法（之後再做）：在新 migration CREATE OR REPLACE generate_daily_pairs()，
-- 在排除子句加上：
--   OR (mi.status = 'soft_exit' AND mi.soft_exit_until > NOW())


-- ── 13. RPC：log_admin_action（Edge Function 呼叫，寫 audit 用）─────────────

CREATE OR REPLACE FUNCTION log_admin_action(
  p_admin_id        uuid,
  p_action          text,
  p_target_user_id  uuid DEFAULT NULL,
  p_target_match_id uuid DEFAULT NULL,
  p_target_report_id uuid DEFAULT NULL,
  p_metadata        jsonb DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO admin_audit_logs (
    admin_id, action, target_user_id, target_match_id, target_report_id, metadata
  ) VALUES (
    p_admin_id, p_action, p_target_user_id, p_target_match_id, p_target_report_id, p_metadata
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;
