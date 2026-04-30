-- 補發 welcome_approved 系統公告給所有現存的 approved 用戶
--
-- 背景：review-application Edge Function 從 migration 20260430000001 之後才會
-- 在通過時 INSERT system_messages。在那之前已經通過審核的用戶都沒收到歡迎訊息。
-- 此 migration 一次性回補。
--
-- 條件：
--   - profiles 存在（= 通過審核且建立 profile）
--   - is_deleted = false（不發給已刪除帳號）
--   - account_status != 'banned'（被停權的不發）
--   - 還沒收過 welcome_approved（NOT EXISTS guard 確保 idempotent）

INSERT INTO system_messages (user_id, type, title, body, created_at)
SELECT
  p.id,
  'welcome_approved',
  '歡迎加入 Luko 🌿',
  E'你的申請已通過審核，感謝你願意以真實的樣貌走進這裡。\n\n'
  || E'Luko 是一個慢一點的地方。我們相信好的關係從尊重開始，所以拜託你：\n'
  || E'　• 對每一位走過你眼前的人保有禮貌\n'
  || E'　• 不傳送讓自己日後也會臉紅的訊息\n'
  || E'　• 把對方當成可能會走進你生活的人，而不是螢幕另一端的選項\n\n'
  || E'小提醒：完整的個人檔案能讓你被看見的方式更立體。\n'
  || E'還沒填的興趣、自我介紹、回答的問題，都可以隨時在「我」→「編輯個人檔案」補上。\n\n'
  || E'祝你在這裡遇見值得的人。',
  NOW()
FROM profiles p
WHERE p.is_deleted = false
  AND p.account_status != 'banned'
  AND NOT EXISTS (
    SELECT 1 FROM system_messages sm
    WHERE sm.user_id = p.id
      AND sm.type = 'welcome_approved'
  );
