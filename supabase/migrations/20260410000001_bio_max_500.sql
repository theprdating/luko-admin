-- Increase bio character limit from 150 to 500
-- Applies to both applications and profiles tables.

ALTER TABLE applications
  DROP CONSTRAINT IF EXISTS applications_bio_check,
  ADD CONSTRAINT applications_bio_check CHECK (char_length(bio) <= 500);

ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_bio_check,
  ADD CONSTRAINT profiles_bio_check CHECK (char_length(bio) <= 500);
