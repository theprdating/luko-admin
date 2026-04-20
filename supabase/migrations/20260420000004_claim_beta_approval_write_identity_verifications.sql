-- Update claim_beta_approval to also write identity_verifications from source_verify_urls
-- so beta users have the same data shape as regular users going forward.

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
  v_user_id       UUID  := auth.uid();
  v_email         TEXT;
  v_name          TEXT;
  v_gender        TEXT;
  v_seeking       TEXT[];
  v_bio           TEXT;
  v_photos        TEXT[];
  v_verify_urls   TEXT[];
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

  SELECT
    COALESCE(p_display_name, pe.display_name, LEFT(v_name, 20)),
    COALESCE(p_gender,       pe.gender),
    COALESCE(p_seeking,      pe.seeking, ARRAY['male','female']::TEXT[]),
    COALESCE(p_bio,          pe.bio),
    pe.source_verify_urls
  INTO v_name, v_gender, v_seeking, v_bio, v_verify_urls
  FROM preapproved_emails pe
  WHERE pe.email = v_email;

  IF char_length(v_name) < 1 THEN v_name := 'User'; END IF;

  SELECT COALESCE(
    NULLIF(p_photo_paths, ARRAY[]::TEXT[]),
    NULLIF(photo_paths, ARRAY[]::TEXT[]),
    ARRAY[]::TEXT[]
  )
  INTO v_photos
  FROM profiles
  WHERE id = v_user_id;

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

  -- Write source verification photos so admin panel has original verify data.
  -- action codes stored as '' (beta users had no liveness challenge codes).
  IF v_verify_urls IS NOT NULL AND array_length(v_verify_urls, 1) >= 2 THEN
    INSERT INTO identity_verifications (
      user_id, front_face_path, side_face_path,
      action1_code, action1_path,
      action2_code, action2_path,
      status
    ) VALUES (
      v_user_id,
      v_verify_urls[1],
      v_verify_urls[2],
      '',
      v_verify_urls[array_length(v_verify_urls, 1)],
      '',
      v_verify_urls[array_length(v_verify_urls, 1)],
      'approved'
    )
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION claim_beta_approval(TEXT, TEXT, TEXT[], TEXT, TEXT[]) TO authenticated;
