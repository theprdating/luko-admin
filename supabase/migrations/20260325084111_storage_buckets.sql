-- ============================================================
-- Luko — Storage Buckets & Policies
-- Created: 2026-03-25
-- ============================================================

-- ── Buckets（私有）──────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('application-photos', 'application-photos', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('profile-photos',     'profile-photos',     false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ── Storage RLS Policies ─────────────────────────────────────────────────────

-- application-photos：用戶只能上傳到自己的子目錄
CREATE POLICY "users_upload_own_application_photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'application-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- application-photos：用戶可以讀取自己的照片
CREATE POLICY "users_read_own_application_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'application-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- application-photos：管理員可讀取所有申請照片
CREATE POLICY "admins_read_all_application_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'application-photos'
    AND auth.jwt() ->> 'user_role' = 'admin'
  );

-- profile-photos：通過審核的用戶可以讀取
CREATE POLICY "approved_users_read_profile_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'profile-photos'
    AND EXISTS (
      SELECT 1 FROM applications
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

-- profile-photos：用戶只能上傳到自己的子目錄
CREATE POLICY "users_upload_own_profile_photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- profile-photos：用戶可以刪除自己的照片
CREATE POLICY "users_delete_own_profile_photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
