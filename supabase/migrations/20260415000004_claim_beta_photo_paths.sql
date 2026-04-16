-- Add p_photo_paths to claim_beta_approval so existing profile photos
-- are preserved when a beta user completes the re-onboarding flow.
--
-- Flow:
--   app reads profiles.photo_paths → pre-fills uploadedPhotoPaths in form
--   user proceeds through locked photos page (can't change)
--   confirm page calls claim_beta_approval(... p_photo_paths=[...])
--   RPC writes those paths into both applications and profiles rows

CREATE OR REPLACE FUNCTION claim_beta_approval(
  p_display_name TEXT    DEFAULT NULL,
  p_gender       TEXT    DEFAULT NULL,
  p_seeking      TEXT[]  DEFAULT NULL,
  p_bio          TEXT    DEFAULT NULL,
  p_photo_paths  TEXT[]  DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id    UUID  := auth.uid();
  v_email      TEXT;
  v_name       TEXT;
  v_gender     TEXT;
  v_seeking    TEXT[];
  v_bio        TEXT;
  v_photos     TEXT[];
BEGIN
  SELECT email,
         COALESCE(raw_user_meta_data->>'full_name',
                  raw_user_meta_data->>'name',
                  split_part(email, '@', 1))
  INTO v_email, v_name
  FROM auth.users
  WHERE id = v_user_id;

  IF NOT EXISTS (SELECT 1 FROM preapproved_emails WHERE email = v_email) THEN
    RAISE EXCEPTION 'Email not pre-approved';
  END IF;

  IF EXISTS (SELECT 1 FROM applications WHERE user_id = v_user_id) THEN
    RETURN;
  END IF;

  -- Resolve values: caller params > preapproved_emails > defaults
  SELECT
    COALESCE(p_display_name, pe.display_name, LEFT(v_name, 20)),
    COALESCE(p_gender,       pe.gender),
    COALESCE(p_seeking,      pe.seeking, ARRAY['male','female']::TEXT[]),
    COALESCE(p_bio,          pe.bio)
  INTO v_name, v_gender, v_seeking, v_bio
  FROM preapproved_emails pe
  WHERE pe.email = v_email;

  IF char_length(v_name) < 1 THEN v_name := 'User'; END IF;

  -- Photos: caller-supplied paths take priority; fall back to existing profile photos
  SELECT COALESCE(
    NULLIF(p_photo_paths, ARRAY[]::TEXT[]),
    NULLIF(photo_paths, ARRAY[]::TEXT[]),
    ARRAY[]::TEXT[]
  )
  INTO v_photos
  FROM profiles
  WHERE id = v_user_id;

  -- profiles row might not exist yet
  IF v_photos IS NULL THEN
    v_photos := COALESCE(NULLIF(p_photo_paths, ARRAY[]::TEXT[]), ARRAY[]::TEXT[]);
  END IF;

  INSERT INTO applications (
    user_id, display_name, gender, status,
    photo_paths, seeking, bio,
    terms_accepted_at, privacy_accepted_at
  ) VALUES (
    v_user_id, v_name, v_gender, 'approved',
    v_photos, v_seeking, v_bio,
    NOW(), NOW()
  );

  INSERT INTO profiles (
    id, display_name, gender, bio, is_active, is_founding_member,
    seeking, photo_paths, photos_locked
  ) VALUES (
    v_user_id, v_name, v_gender, v_bio, TRUE, TRUE,
    v_seeking, v_photos, TRUE
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name  = EXCLUDED.display_name,
    gender        = EXCLUDED.gender,
    bio           = EXCLUDED.bio,
    seeking       = EXCLUDED.seeking,
    photo_paths   = EXCLUDED.photo_paths,
    photos_locked = TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION claim_beta_approval(TEXT, TEXT, TEXT[], TEXT, TEXT[]) TO authenticated;
