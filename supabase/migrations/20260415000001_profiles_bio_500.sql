-- Raise profiles.bio limit from 150 to 500
-- (consistent with applications.bio which was already 500)
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_bio_check;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_bio_check
    CHECK (bio IS NULL OR char_length(bio) <= 500);
