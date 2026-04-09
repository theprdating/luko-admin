-- Migration: add_rejection_tags
-- Date: 2026-04-09
-- Purpose: 新增 rejection_tags 欄位，儲存審核員勾選的標準化拒絕原因標籤

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS rejection_tags TEXT[] DEFAULT NULL;

-- 允許的 tag 值（不在 DB 層強制 check，彈性擴充用）
-- photo_blurry      → 建議提供清晰、光線充足的照片
-- messy_background  → 建議在整潔或有質感的空間拍攝
-- casual_style      → 建議展現經過打理的穿搭與造型
-- face_unclear      → 建議確保主照片能清楚看見臉部
-- too_few_photos    → 建議提供至少 3 張不同角度的照片

COMMENT ON COLUMN applications.rejection_tags IS
  '審核員勾選的標準化拒絕原因標籤（text[]）。只在 status=rejected 時有效；approve 時需清為 NULL。';
