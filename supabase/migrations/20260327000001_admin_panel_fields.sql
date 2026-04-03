-- ============================================================
-- Luko — Admin Panel Support Fields
-- Created: 2026-03-27
-- Purpose: 為審核後台網頁提供更完整的資料與查詢效能
-- ============================================================

-- ── 1. applications 補充欄位 ─────────────────────────────────────────────────

ALTER TABLE applications
  -- 標準化拒絕原因碼（審核員內部使用，絕不對外顯示）
  ADD COLUMN rejection_reason_code TEXT
    CHECK (rejection_reason_code IN (
      'unclear_face',    -- 臉部不清晰
      'old_photo',       -- 照片明顯非近期
      'no_effort',       -- 無整體打扮意識
      'fake_profile',    -- 疑似假帳號/AI生成
      'inappropriate',   -- 不適當內容
      'other'
    )),

  -- 審核員開始審核的時間（用於計算平均審核時間 KPI）
  ADD COLUMN review_started_at TIMESTAMPTZ,

  -- 從開始審核到完成的秒數（review_started_at → reviewed_at）
  ADD COLUMN review_duration_seconds INTEGER
    CHECK (review_duration_seconds IS NULL OR review_duration_seconds >= 0),

  -- 第幾次申請（重申請時自動遞增）
  ADD COLUMN application_count SMALLINT NOT NULL DEFAULT 1
    CHECK (application_count >= 1),

  -- 申請時的裝置資訊（平台、App 版本），用於品質分析
  ADD COLUMN device_info JSONB NOT NULL DEFAULT '{}';

-- ── 2. 重申請時自動遞增 application_count 的 Trigger ───────────────────────────

CREATE OR REPLACE FUNCTION increment_application_count()
RETURNS TRIGGER AS $$
BEGIN
  -- 當 rejected 狀態的記錄被 upsert 為 pending（重新申請）時，遞增計數
  IF TG_OP = 'UPDATE'
     AND OLD.status = 'rejected'
     AND NEW.status = 'pending' THEN
    NEW.application_count := OLD.application_count + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER applications_reapply_count
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION increment_application_count();

-- ── 3. 後台查詢優化索引 ────────────────────────────────────────────────────────

-- 後台審核隊列：只撈 pending，FIFO 排序（最早申請優先）
CREATE INDEX idx_applications_pending_queue
  ON applications(created_at ASC)
  WHERE status = 'pending';

-- 審核員個人績效查詢（今日已審核幾筆、通過/拒絕比例）
CREATE INDEX idx_applications_reviewer_stats
  ON applications(reviewed_by, reviewed_at DESC)
  WHERE reviewed_by IS NOT NULL;

-- 按性別篩選隊列（後台可能要分男/女審核）
CREATE INDEX idx_applications_gender_status
  ON applications(gender, status, created_at ASC)
  WHERE status = 'pending';
