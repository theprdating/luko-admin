-- Add reverify_photo_paths to profiles
--
-- When an approved user submits a photo update, they must retake 2 verification
-- photos (front face + 1 random action) to confirm identity.
-- These paths are stored here so the admin panel can review them alongside
-- the new profile photos.
--
-- Paths stored in profile-photos bucket: {userId}/reverify/{ts}_{0,1}.jpg

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS reverify_photo_paths TEXT[] DEFAULT '{}';
