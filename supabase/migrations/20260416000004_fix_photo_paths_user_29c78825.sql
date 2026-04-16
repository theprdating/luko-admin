-- Fix photo_paths for user 29c78825-ff1e-433b-aecd-b13b2c57d263
--
-- Root cause: edit_photos_page.dart uploaded to profile-photos with path
--   {userId}/photos/{ts}_{i}.jpg  ← wrong (photos/ subdir)
-- But actual files in storage are at:
--   {userId}/{ts}_{i}.jpg         ← correct (no subdir)
--
-- This migration:
--   1. Updates profiles.photo_paths with correct paths
--   2. Replaces profile_photos rows with correct storage_path values

DO $$
DECLARE
  v_user_id UUID := '29c78825-ff1e-433b-aecd-b13b2c57d263';
  v_paths   TEXT[] := ARRAY[
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_0.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_1.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_2.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_3.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_4.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_5.jpg',
    '29c78825-ff1e-433b-aecd-b13b2c57d263/1775798445462_6.jpg'
  ];
BEGIN
  -- 1. Fix profiles.photo_paths
  UPDATE profiles
  SET photo_paths = v_paths
  WHERE id = v_user_id;

  -- 2. Replace profile_photos rows
  DELETE FROM profile_photos WHERE user_id = v_user_id;

  INSERT INTO profile_photos (user_id, storage_path, display_order, is_verified)
  SELECT
    v_user_id,
    v_paths[i],
    i - 1,   -- display_order 0-based
    TRUE
  FROM generate_series(1, array_length(v_paths, 1)) AS i;

END $$;
