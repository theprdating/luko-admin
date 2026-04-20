-- 防止同一用戶同時存在多筆 pending 換照申請
-- App 端已有 photo_pending_review flag 防線，此為 DB 層兜底
CREATE UNIQUE INDEX photo_change_requests_one_pending_per_user
  ON photo_change_requests (user_id)
  WHERE status = 'pending';
