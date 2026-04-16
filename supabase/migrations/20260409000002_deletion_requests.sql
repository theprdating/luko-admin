-- deletion_requests
-- 記錄用戶提出的帳號刪除申請（軟刪除緩衝機制）
--
-- 設計原則：
--   - 用戶提出申請後帳號進入凍結狀態（不對外顯示、不參與任何功能）
--   - 90 天後由 cron job 清除所有個人資料（符合台灣個資法、隱私政策承諾）
--   - 期間用戶可登入取消申請（恢復原本狀態）
--   - 清除完成後保留 hashed_phone 供防濫用比對（不屬於個資，合法保存）

CREATE TABLE deletion_requests (
  user_id       UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_for TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '90 days',
  cancelled_at  TIMESTAMPTZ          -- NULL = 申請有效；NOT NULL = 用戶已取消
);

-- Index：cron job 每日掃描到期且未取消的請求
CREATE INDEX idx_deletion_requests_scheduled
  ON deletion_requests (scheduled_for)
  WHERE cancelled_at IS NULL;

-- RLS
ALTER TABLE deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "deletion_requests: user select own"
  ON deletion_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "deletion_requests: user insert own"
  ON deletion_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 只允許 UPDATE cancelled_at（取消申請），不允許修改 scheduled_for
CREATE POLICY "deletion_requests: user cancel own"
  ON deletion_requests FOR UPDATE
  USING (auth.uid() = user_id);
