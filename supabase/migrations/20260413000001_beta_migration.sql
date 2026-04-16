-- ── Beta 封測遷移：允許欄位為 null + 白名單表 + RPC 函式 ──────────────────────

-- 1a. 讓 applications 的 birth_date / gender 可以為 null（遷移用戶無此資料）
ALTER TABLE applications
  ALTER COLUMN birth_date DROP NOT NULL,
  ALTER COLUMN gender     DROP NOT NULL;

ALTER TABLE applications
  DROP CONSTRAINT IF EXISTS applications_gender_check;
ALTER TABLE applications
  ADD CONSTRAINT applications_gender_check
    CHECK (gender IS NULL OR gender IN ('male', 'female', 'other'));

-- 1b. 讓 profiles 的 birth_date / gender 可以為 null
ALTER TABLE profiles
  ALTER COLUMN birth_date DROP NOT NULL,
  ALTER COLUMN gender     DROP NOT NULL;

ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE profiles
  ADD CONSTRAINT profiles_gender_check
    CHECK (gender IS NULL OR gender IN ('male', 'female', 'other'));

-- 2. 封測白名單表
CREATE TABLE IF NOT EXISTS preapproved_emails (
  email       TEXT        PRIMARY KEY,
  migrated_at TIMESTAMPTZ DEFAULT NOW(),
  source      TEXT        DEFAULT 'beta_v1'
);

ALTER TABLE preapproved_emails ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can check their own preapproval"
  ON preapproved_emails FOR SELECT
  TO authenticated
  USING (email = (
    SELECT email FROM auth.users WHERE id = auth.uid()
  ));

-- 3. 安全 RPC
CREATE OR REPLACE FUNCTION claim_beta_approval()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id    UUID  := auth.uid();
  v_email      TEXT;
  v_name       TEXT;
BEGIN
  SELECT email,
         COALESCE(raw_user_meta_data->>'full_name',
                  raw_user_meta_data->>'name',
                  split_part(email, '@', 1))
  INTO v_email, v_name
  FROM auth.users
  WHERE id = v_user_id;

  v_name := LEFT(v_name, 20);
  IF char_length(v_name) < 1 THEN v_name := 'User'; END IF;

  IF NOT EXISTS (SELECT 1 FROM preapproved_emails WHERE email = v_email) THEN
    RAISE EXCEPTION 'Email not pre-approved';
  END IF;

  IF EXISTS (SELECT 1 FROM applications WHERE user_id = v_user_id) THEN
    RETURN;
  END IF;

  INSERT INTO applications (
    user_id, display_name, status,
    photo_paths,
    terms_accepted_at, privacy_accepted_at
  ) VALUES (
    v_user_id, v_name, 'approved',
    ARRAY[]::TEXT[],
    NOW(), NOW()
  );

  INSERT INTO profiles (
    id, display_name, is_active, is_founding_member,
    seeking, photo_paths
  ) VALUES (
    v_user_id, v_name, TRUE, TRUE,
    ARRAY['male','female']::TEXT[], ARRAY[]::TEXT[]
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION claim_beta_approval() TO authenticated;

-- 4. 設定密碼完成 flag（寫入 app_metadata，用戶無法自行偽造）
--    由 set_password_page 完成後呼叫，取代直接寫 user_metadata
CREATE OR REPLACE FUNCTION mark_password_set()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  -- 確認呼叫者在白名單內才允許標記（防止非封測用戶呼叫）
  IF NOT EXISTS (
    SELECT 1 FROM preapproved_emails pe
    JOIN auth.users u ON u.email = pe.email
    WHERE u.id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not a pre-approved user';
  END IF;

  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"password_set": true}'::jsonb
  WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION mark_password_set() TO authenticated;
