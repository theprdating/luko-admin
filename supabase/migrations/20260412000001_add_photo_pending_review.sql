-- Add photo_pending_review flag to profiles
--
-- When an approved user submits new photos via the edit profile flow,
-- this flag is set to true. The app shows a "under review" banner and
-- continues to use the original photos for matching until an admin
-- clears the flag (either approving or rejecting the new photos).

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS photo_pending_review boolean NOT NULL DEFAULT false;
