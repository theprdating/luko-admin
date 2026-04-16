-- 新增 profiles 欄位：興趣標籤 + 問題回答
--
-- interests:        text[]  — 用戶選擇的興趣標籤列表（最多 50 項/類別，總量不限）
-- question_answers: jsonb   — 問題回答列表，格式：
--                            [{"id":"fun_1","question":"...","answer":"..."}]
--
-- 手機驗證完成後，router 會引導用戶填寫這兩個欄位（profile setup flow）。
-- 填完後 interests 不再為空，auth_provider 據此判斷跳過 profileSetupRequired 狀態。

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS interests       text[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS question_answers jsonb   NOT NULL DEFAULT '[]'::jsonb;

-- 更新 DATABASE_SCHEMA.md 說明同步請手動追加（此處僅為 migration 記錄）
