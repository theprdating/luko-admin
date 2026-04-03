-- ============================================================
-- Migration: photo_verification
-- Date: 2026-03-30
-- 1. Add seeking to applications table
-- 2. Create profile_photos table (取代 profiles.photo_paths)
-- 3. Create identity_verifications table
-- 4. Add verification-photos Storage bucket
-- ============================================================

-- ── 1. applications: 新增 seeking 欄位 ────────────────────────────────────────
ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS seeking TEXT[] NOT NULL DEFAULT '{}';

-- ── 2. profile_photos（審核通過後的個人照片，取代 profiles.photo_paths）──────────
CREATE TABLE IF NOT EXISTS profile_photos (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  storage_path  TEXT        NOT NULL,
  display_order INTEGER     NOT NULL,          -- 0-based，用戶可拖動調整
  is_verified   BOOLEAN     NOT NULL DEFAULT false, -- 後台人工標記為本人照片
  verified_at   TIMESTAMPTZ,
  verified_by   UUID,                          -- 審核員 user_id（admin）
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 同一用戶的 display_order 不可重複（排序唯一）
  CONSTRAINT profile_photos_order_unique UNIQUE (user_id, display_order),
  -- 同一用戶的 storage_path 不可重複（同張照片不可加兩次）
  CONSTRAINT profile_photos_path_unique  UNIQUE (user_id, storage_path)
);

-- updated_at trigger 不需要（profile_photos 沒有 updated_at）

-- RLS
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;

-- 本人可讀自己的照片
CREATE POLICY "profile_photos_select_own"
  ON profile_photos FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 已通過審核的用戶可讀其他人的照片（discover / profile 頁）
CREATE POLICY "profile_photos_select_others"
  ON profile_photos FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
    )
  );

-- 本人可新增自己的照片
CREATE POLICY "profile_photos_insert_own"
  ON profile_photos FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 本人可更新自己照片的 display_order（排序）
CREATE POLICY "profile_photos_update_order_own"
  ON profile_photos FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 本人可刪除自己的照片
CREATE POLICY "profile_photos_delete_own"
  ON profile_photos FOR DELETE TO authenticated
  USING (user_id = auth.uid());


-- ── 3. identity_verifications（真人認證照片記錄）─────────────────────────────
CREATE TABLE IF NOT EXISTS identity_verifications (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 四張認證照片的 Storage 路徑（verification-photos bucket，私有）
  front_face_path  TEXT        NOT NULL,
  side_face_path   TEXT        NOT NULL,
  action1_code     TEXT        NOT NULL,  -- VerificationAction enum name
  action1_path     TEXT        NOT NULL,
  action2_code     TEXT        NOT NULL,
  action2_path     TEXT        NOT NULL,

  -- 審核狀態（由後台更新）
  status           TEXT        NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by      UUID,
  reviewed_at      TIMESTAMPTZ,
  review_note      TEXT,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_identity_verifications_updated_at
  BEFORE UPDATE ON identity_verifications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE identity_verifications ENABLE ROW LEVEL SECURITY;

-- 本人可新增驗證申請
CREATE POLICY "identity_verifications_insert_own"
  ON identity_verifications FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 本人可讀自己的驗證記錄
CREATE POLICY "identity_verifications_select_own"
  ON identity_verifications FOR SELECT TO authenticated
  USING (user_id = auth.uid());


-- ── 4. Storage bucket: verification-photos（私有）────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'verification-photos',
  'verification-photos',
  false,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- 本人可上傳到自己的資料夾（verification-photos/{uid}/...）
CREATE POLICY "verification_photos_upload_own"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'verification-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 本人可讀自己的驗證照片
CREATE POLICY "verification_photos_read_own"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
