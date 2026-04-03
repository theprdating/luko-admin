-- ============================================================
-- Luko — Initial Schema Migration
-- Created: 2026-03-25
-- ============================================================

-- ── 0. 共用 updated_at trigger function ──────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── 1. applications（申請者資料）────────────────────────────────────────────

CREATE TABLE applications (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT        NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 20),
  birth_date    DATE        NOT NULL,
  gender        TEXT        NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio           TEXT        CHECK (char_length(bio) <= 150),
  photo_paths   TEXT[]      NOT NULL,
  status        TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at   TIMESTAMPTZ,
  reviewed_by   UUID,
  review_note   TEXT,
  reapply_after TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id)
);

CREATE TRIGGER applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 2. profiles（個人檔案）──────────────────────────────────────────────────

CREATE TABLE profiles (
  id                 UUID     PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name       TEXT     NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 20),
  birth_date         DATE     NOT NULL,
  gender             TEXT     NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio                TEXT     CHECK (char_length(bio) <= 150),
  avatar_url         TEXT,
  photo_paths        TEXT[]   DEFAULT '{}',
  city               TEXT,
  seeking            TEXT[]   NOT NULL DEFAULT ARRAY['male','female','other'],
  is_active          BOOLEAN  NOT NULL DEFAULT TRUE,
  is_founding_member BOOLEAN  NOT NULL DEFAULT FALSE,
  is_deleted         BOOLEAN  NOT NULL DEFAULT FALSE,
  deleted_at         TIMESTAMPTZ,
  last_active_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 3. swipes（滑動記錄）────────────────────────────────────────────────────

CREATE TABLE swipes (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  direction     TEXT        NOT NULL CHECK (direction IN ('like', 'pass')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(from_user_id, to_user_id),
  CHECK (from_user_id != to_user_id)
);

-- ── 4. matches（配對成功）+ trigger ─────────────────────────────────────────

CREATE TABLE matches (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user1_id, user2_id),
  CHECK (user1_id < user2_id)
);

CREATE OR REPLACE FUNCTION check_and_create_match()
RETURNS TRIGGER AS $$
DECLARE
  mutual_like_exists BOOLEAN;
  u1 UUID;
  u2 UUID;
BEGIN
  IF NEW.direction = 'like' THEN
    SELECT EXISTS (
      SELECT 1 FROM swipes
      WHERE from_user_id = NEW.to_user_id
        AND to_user_id   = NEW.from_user_id
        AND direction    = 'like'
    ) INTO mutual_like_exists;

    IF mutual_like_exists THEN
      u1 := LEAST(NEW.from_user_id, NEW.to_user_id);
      u2 := GREATEST(NEW.from_user_id, NEW.to_user_id);
      INSERT INTO matches (user1_id, user2_id)
      VALUES (u1, u2)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER swipe_match_trigger
  AFTER INSERT ON swipes
  FOR EACH ROW EXECUTE FUNCTION check_and_create_match();

-- ── 5. messages（聊天訊息）──────────────────────────────────────────────────

CREATE TABLE messages (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id    UUID        NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content     TEXT        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1000),
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 6. reports（檢舉記錄）───────────────────────────────────────────────────

CREATE TABLE reports (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason        TEXT        NOT NULL
                            CHECK (reason IN ('fake_photo','harassment','spam','inappropriate','other')),
  note          TEXT        CHECK (char_length(note) <= 300),
  status        TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'reviewed', 'actioned')),
  reviewed_by   UUID,
  reviewed_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CHECK (reporter_id != reported_id)
);

-- ── 7. blocks（封鎖記錄）────────────────────────────────────────────────────

CREATE TABLE blocks (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

-- ── 8. device_tokens（FCM 推播裝置 Token）───────────────────────────────────

CREATE TABLE device_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, token)
);

CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 9. user_events（用戶行為追蹤）───────────────────────────────────────────

CREATE TABLE user_events (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name  TEXT        NOT NULL,
  properties  JSONB       DEFAULT '{}',
  session_id  TEXT,
  platform    TEXT        CHECK (platform IN ('ios', 'android')),
  app_version TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 10. Row Level Security ───────────────────────────────────────────────────

ALTER TABLE applications  ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches       ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports       ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events   ENABLE ROW LEVEL SECURITY;

-- applications
CREATE POLICY "users_read_own_application"
  ON applications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own_application"
  ON applications FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_update_own_application"
  ON applications FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "admins_read_all_applications"
  ON applications FOR SELECT USING (auth.jwt() ->> 'user_role' = 'admin');

CREATE POLICY "admins_update_applications"
  ON applications FOR UPDATE USING (auth.jwt() ->> 'user_role' = 'admin');

-- profiles
CREATE POLICY "approved_users_read_profiles"
  ON profiles FOR SELECT
  USING (
    is_deleted = FALSE AND is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM applications
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "users_update_own_profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- swipes
CREATE POLICY "users_read_own_swipes"
  ON swipes FOR SELECT USING (auth.uid() = from_user_id);

CREATE POLICY "users_insert_own_swipes"
  ON swipes FOR INSERT WITH CHECK (auth.uid() = from_user_id);

-- matches
CREATE POLICY "users_read_own_matches"
  ON matches FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- messages
CREATE POLICY "users_read_match_messages"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM matches
      WHERE id = match_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
        AND is_active = TRUE
    )
  );

CREATE POLICY "users_insert_match_messages"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM matches
      WHERE id = match_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
        AND is_active = TRUE
    )
  );

-- blocks
CREATE POLICY "users_manage_own_blocks"
  ON blocks FOR ALL
  USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);

-- reports
CREATE POLICY "users_insert_reports"
  ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "admins_manage_reports"
  ON reports FOR ALL USING (auth.jwt() ->> 'user_role' = 'admin');

-- device_tokens
CREATE POLICY "users_manage_own_device_tokens"
  ON device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- user_events：只寫不讀（分析由後端進行）
CREATE POLICY "users_insert_own_events"
  ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "admins_read_all_events"
  ON user_events FOR SELECT USING (auth.jwt() ->> 'user_role' = 'admin');

-- ── 11. Indexes ──────────────────────────────────────────────────────────────

CREATE INDEX idx_applications_status   ON applications(status, created_at DESC);
CREATE INDEX idx_applications_user_id  ON applications(user_id);

CREATE INDEX idx_profiles_active
  ON profiles(is_active, is_deleted, created_at DESC)
  WHERE is_active = TRUE AND is_deleted = FALSE;

CREATE INDEX idx_swipes_from_user  ON swipes(from_user_id, to_user_id);
CREATE INDEX idx_swipes_like_check ON swipes(to_user_id, from_user_id, direction)
  WHERE direction = 'like';

CREATE INDEX idx_matches_user1 ON matches(user1_id, created_at DESC);
CREATE INDEX idx_matches_user2 ON matches(user2_id, created_at DESC);

CREATE INDEX idx_messages_match_time ON messages(match_id, created_at ASC);

CREATE INDEX idx_blocks_blocker ON blocks(blocker_id, blocked_id);

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

CREATE INDEX idx_user_events_user_created ON user_events(user_id, created_at DESC);
CREATE INDEX idx_user_events_name_created ON user_events(event_name, created_at DESC);
CREATE INDEX idx_user_events_properties   ON user_events USING gin(properties);
