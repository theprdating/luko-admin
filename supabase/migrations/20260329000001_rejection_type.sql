-- Add rejection_type to applications table
-- soft      : 照片/呈現不足，可 3–7 天後重申
-- potential : 有潛力但需改善，引導改善建議 + 合作夥伴推薦
-- hard      : 不雅內容/假帳號，永久封鎖（後台靜默處理）
-- NULL      : 舊資料相容，視同 soft

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS rejection_type text
    CHECK (rejection_type IN ('soft', 'potential', 'hard'));
