-- Fix: users cannot upload to profile-photos when upsert:true is set
--
-- Root cause: PostgreSQL's INSERT ... ON CONFLICT DO UPDATE (upsert) requires
-- UPDATE policies to exist and pass, *even when no conflict actually occurs*.
-- Without an UPDATE policy, every upsert upload returns 403 regardless of
-- whether the file already exists.
--
-- Applied in: edit_reverify_page.dart and edit_photos_page.dart (if any).

DROP POLICY IF EXISTS "users_update_own_profile_photos" ON storage.objects;

CREATE POLICY "users_update_own_profile_photos"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
