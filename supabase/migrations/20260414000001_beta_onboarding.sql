-- Add migration data columns to preapproved_emails
ALTER TABLE preapproved_emails
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS gender       TEXT CHECK (gender IS NULL OR gender IN ('male','female','other')),
  ADD COLUMN IF NOT EXISTS seeking      TEXT[] DEFAULT ARRAY['male','female']::TEXT[],
  ADD COLUMN IF NOT EXISTS bio          TEXT;

-- Add photos_locked to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS photos_locked BOOLEAN NOT NULL DEFAULT FALSE;

-- Update claim_beta_approval to accept form data
CREATE OR REPLACE FUNCTION claim_beta_approval(
  p_display_name TEXT DEFAULT NULL,
  p_gender       TEXT DEFAULT NULL,
  p_seeking      TEXT[] DEFAULT NULL,
  p_bio          TEXT DEFAULT NULL
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

  -- Use provided params if given, otherwise fall back to preapproved_emails data, then defaults
  SELECT
    COALESCE(p_display_name, pe.display_name, LEFT(v_name, 20)),
    COALESCE(p_gender,       pe.gender),
    COALESCE(p_seeking,      pe.seeking, ARRAY['male','female']::TEXT[]),
    COALESCE(p_bio,          pe.bio)
  INTO v_name, v_gender, v_seeking, v_bio
  FROM preapproved_emails pe
  WHERE pe.email = v_email;

  IF char_length(v_name) < 1 THEN v_name := 'User'; END IF;

  INSERT INTO applications (
    user_id, display_name, gender, status,
    photo_paths, seeking,
    terms_accepted_at, privacy_accepted_at
  ) VALUES (
    v_user_id, v_name, v_gender, 'approved',
    ARRAY[]::TEXT[], v_seeking,
    NOW(), NOW()
  );

  INSERT INTO profiles (
    id, display_name, gender, bio, is_active, is_founding_member,
    seeking, photo_paths, photos_locked
  ) VALUES (
    v_user_id, v_name, v_gender, v_bio, TRUE, TRUE,
    v_seeking, ARRAY[]::TEXT[], TRUE
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION claim_beta_approval(TEXT, TEXT, TEXT[], TEXT) TO authenticated;
