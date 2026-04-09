# Luko — 資料庫設計文件

> **版本：** v0.1 Draft
> **建立日期：** 2026-03-25
> **資料庫：** Supabase（PostgreSQL）
> **使用前：** 在 Supabase Dashboard 依序執行本文件的 SQL

---

## 目錄

1. [整體架構](#1-整體架構)
2. [資料表設計](#2-資料表設計)
3. [Row Level Security（RLS）政策](#3-row-level-securityrls政策)
4. [Index 索引規劃](#4-index-索引規劃)
5. [Storage Bucket 設計](#5-storage-bucket-設計)
6. [Edge Functions 清單](#6-edge-functions-清單)
7. [初始化執行順序](#7-初始化執行順序)

> 資料表清單：`applications` `profiles` `swipes` `matches` `messages` `reports` `blocks` `device_tokens` `user_events`

---

## 1. 整體架構

```
Supabase Auth（auth.users）
  └─ 管理手機號碼驗證、Session
  └─ user_id 作為所有資料表的外鍵基礎

自訂資料表：
  applications   申請者資料（審核前）
  user_events    用戶行為事件追蹤
  profiles       用戶個人檔案（審核通過後建立）
  swipes         滑動記錄（like / pass）
  matches        配對成功記錄
  messages       聊天訊息
  reports        檢舉記錄
  blocks         封鎖記錄
  device_tokens  FCM 推播裝置 Token（推播通知用）

Supabase Storage Buckets：
  application-photos   申請照片（私有）
  profile-photos       個人頭貼與照片（私有）
```

---

## 2. 資料表設計

### 2-1. applications（申請者資料）

```sql
CREATE TABLE applications (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT        NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 20),
  birth_date    DATE        NOT NULL,
  gender        TEXT        NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio           TEXT        CHECK (char_length(bio) <= 150),
  photo_paths   TEXT[]      NOT NULL,          -- Supabase Storage 路徑陣列
  status        TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at   TIMESTAMPTZ,
  reviewed_by   UUID,                           -- 審核員 user_id（管理員）
  review_note   TEXT,                           -- 內部備註，不對用戶顯示
  reapply_after TIMESTAMPTZ,                    -- 可重新申請的最早時間
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id)   -- 每個用戶同時只能有一筆申請
);

-- updated_at 自動更新 trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**欄位說明：**

| 欄位 | 說明 | 備註 |
|------|------|------|
| `photo_paths` | Storage 內的相對路徑陣列 | 例：`['applications/uuid/1.jpg']` |
| `status` | 審核狀態 | `pending` / `approved` / `rejected` |
| `review_note` | 審核員內部備註 | ⚠️ 不對外顯示，只供內部紀錄 |
| `reapply_after` | 拒絕後可重申請的時間 | 設為 `rejected_at + 30 days` |
| `rejection_tags` | 審核員勾選的標準化拒絕標籤 | `text[]`，只在 `status=rejected` 時有效；approve 時清為 `NULL` |
| `terms_accepted_at` | Step 5 確認送出時接受服務條款的時間 | 審核通過後複製到 `profiles.terms_accepted_at` |
| `privacy_accepted_at` | Step 5 確認送出時接受隱私政策的時間 | 審核通過後複製到 `profiles.privacy_accepted_at` |

---

### 2-2. profiles（個人檔案）

```sql
CREATE TABLE profiles (
  id              UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT        NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 20),
  birth_date      DATE        NOT NULL,
  gender          TEXT        NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  bio             TEXT        CHECK (char_length(bio) <= 150),
  avatar_url      TEXT,                           -- 主頭貼 Storage URL
  photo_paths     TEXT[]      DEFAULT '{}',       -- 照片路徑陣列（最多 6 張）
  city            TEXT,
  seeking         TEXT[]      NOT NULL DEFAULT ARRAY['male','female','other'],
                              -- 配對偏好（可多選）：用戶自選想看到的性別
                              -- 例：['male'] = 只看男性；['male','female'] = 看男和女
  is_active       BOOLEAN     NOT NULL DEFAULT TRUE,   -- 帳號是否啟用
  is_founding_member BOOLEAN  NOT NULL DEFAULT FALSE,  -- 創始會員標記
  is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,  -- Soft delete
  deleted_at      TIMESTAMPTZ,
  last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  terms_accepted_at   TIMESTAMPTZ,  -- 最後一次接受服務條款的時間（比對 app_config.terms_updated_at）
  privacy_accepted_at TIMESTAMPTZ,  -- 最後一次接受隱私政策的時間（比對 app_config.privacy_updated_at）
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

### 2-3. swipes（滑動記錄）

```sql
CREATE TABLE swipes (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  direction     TEXT        NOT NULL CHECK (direction IN ('like', 'pass')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(from_user_id, to_user_id),   -- 每對只能滑一次
  CHECK (from_user_id != to_user_id)  -- 不能滑自己
);
```

---

### 2-4. matches（配對成功）

```sql
CREATE TABLE matches (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE,  -- 封鎖後設為 false
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user1_id, user2_id),
  CHECK (user1_id < user2_id)   -- 確保 (A,B) 和 (B,A) 不重複，user1_id 永遠 < user2_id
);
```

> 💡 **配對觸發邏輯**：每次插入 `direction = 'like'` 的 swipe 時，
> 用 DB Function 檢查對方是否已 like 過自己，若是則自動建立 match。

```sql
-- 配對觸發 Function
CREATE OR REPLACE FUNCTION check_and_create_match()
RETURNS TRIGGER AS $$
DECLARE
  mutual_like_exists BOOLEAN;
  u1 UUID;
  u2 UUID;
BEGIN
  IF NEW.direction = 'like' THEN
    -- 檢查對方是否也 like 過我
    SELECT EXISTS (
      SELECT 1 FROM swipes
      WHERE from_user_id = NEW.to_user_id
        AND to_user_id = NEW.from_user_id
        AND direction = 'like'
    ) INTO mutual_like_exists;

    IF mutual_like_exists THEN
      -- 確保 user1_id < user2_id（避免重複）
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
```

---

### 2-5. messages（聊天訊息）

```sql
CREATE TABLE messages (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id    UUID        NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content     TEXT        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1000),
  read_at     TIMESTAMPTZ,   -- NULL 表示未讀
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

### 2-6. reports（檢舉記錄）

```sql
CREATE TABLE reports (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_id   UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason        TEXT        NOT NULL
                            CHECK (reason IN ('fake_photo', 'harassment', 'spam', 'inappropriate', 'other')),
  note          TEXT        CHECK (char_length(note) <= 300),
  status        TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'reviewed', 'actioned')),
  reviewed_by   UUID,
  reviewed_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CHECK (reporter_id != reported_id)
);
```

---

### 2-7. blocks（封鎖記錄）

```sql
CREATE TABLE blocks (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id  UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);
```

---

### 2-8. device_tokens（推播裝置 Token）

> 儲存 FCM（Firebase Cloud Messaging）Token，供 Edge Functions 發送推播通知使用。
> 同一用戶可有多筆（多台裝置），但同一裝置 Token 只存一筆。

```sql
CREATE TABLE device_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, token)   -- 同一用戶同一 Token 只存一筆（避免重複發送）
                           -- 同一用戶可有多筆（多台裝置並行使用）
);

CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**欄位說明：**

| 欄位 | 說明 | 備註 |
|------|------|------|
| `user_id` | 關聯至 `auth.users` | 帳號刪除時自動 CASCADE 刪除 |
| `token` | FCM 裝置識別 Token | 重裝 App 或長時間未使用後會更新 |
| `platform` | `ios` 或 `android` | Edge Function 依平台選擇發送方式 |
| `updated_at` | Token 最後更新時間 | 可用來清除超過 60 天未更新的失效 Token |

**RLS 政策：**

```sql
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- 用戶只能管理自己的裝置 Token
CREATE POLICY "users_manage_own_device_tokens"
  ON device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

**Index：**

```sql
-- Edge Function 查詢某用戶所有 Token 時使用
CREATE INDEX idx_device_tokens_user_id
  ON device_tokens(user_id);
```

---

### 2-9. app_config（全域設定）

> 儲存 App 層級的設定值，目前用途為管理條款版本時間戳。
> 所有已登入用戶可讀，只有 admin 可寫。

```sql
CREATE TABLE app_config (
  key        TEXT        PRIMARY KEY,
  value      TEXT        NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 初始資料
INSERT INTO app_config (key, value) VALUES
  ('terms_updated_at',   '2026-03-26T00:00:00Z'),
  ('privacy_updated_at', '2026-03-26T00:00:00Z');
```

**條款版本比對邏輯（App 端）：**

```
App 啟動 → 已登入且 approved 用戶
  │
  ├─ 拉取 app_config WHERE key IN ('terms_updated_at', 'privacy_updated_at')
  ├─ 拉取 profiles.terms_accepted_at, privacy_accepted_at
  │
  ├─ terms_accepted_at < terms_updated_at   → 顯示強制條款更新 Modal
  ├─ privacy_accepted_at < privacy_updated_at → 顯示強制隱私政策更新 Modal
  └─ 兩者皆 OK → 進入主 App
```

> **更新條款時**：只需在 Supabase Dashboard 把 `app_config.terms_updated_at` 更新為新日期，
> 所有 `profiles.terms_accepted_at` 較舊的用戶，下次啟動 App 就會被要求重新接受。

**RLS 政策：**

```sql
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- 所有已登入用戶可讀取設定值
CREATE POLICY "authenticated_read_app_config"
  ON app_config FOR SELECT TO authenticated USING (TRUE);

-- 只有 admin 可修改
CREATE POLICY "admins_manage_app_config"
  ON app_config FOR ALL
  USING (auth.jwt() ->> 'user_role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'user_role' = 'admin');
```

---

### 2-10. user_events（用戶行為追蹤）

> 記錄用戶在 App 內的行為事件，供產品分析、A/B 測試、轉化漏斗使用。
> 資料只寫不對用戶開放讀取；分析由後端或 BI 工具直接查詢。

```sql
CREATE TABLE user_events (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name  TEXT        NOT NULL,        -- 見下方事件命名規範
  properties  JSONB       DEFAULT '{}',    -- 事件相關參數（彈性欄位）
  session_id  TEXT,                        -- 同一次 App 開啟的 UUID
  platform    TEXT        CHECK (platform IN ('ios', 'android')),
  app_version TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**事件命名規範（`snake_case`，`{物件}_{動作}`）：**

| event_name | 觸發時機 | properties 範例 |
|-----------|---------|----------------|
| `screen_view` | 進入任何頁面 | `{"screen": "discover"}` |
| `swipe_like` | 滑右（喜歡） | `{"target_user_id": "uuid"}` |
| `swipe_pass` | 滑左（略過） | `{"target_user_id": "uuid"}` |
| `match_created` | 配對成功彈窗出現 | `{"match_id": "uuid"}` |
| `message_sent` | 發送訊息 | `{"match_id": "uuid", "char_count": 42}` |
| `profile_view` | 查看他人詳細資料 | `{"target_user_id": "uuid"}` |
| `apply_step_completed` | 完成申請步驟 | `{"step": 3}` |
| `photo_uploaded` | 上傳照片成功 | `{"count": 2}` |
| `session_start` | App 冷啟動或 resume | `{"source": "push_notification"}` |

**Index：**

```sql
CREATE INDEX idx_user_events_user_created ON user_events(user_id, created_at DESC);
CREATE INDEX idx_user_events_name_created ON user_events(event_name, created_at DESC);
CREATE INDEX idx_user_events_properties   ON user_events USING gin(properties);
```

---

## 3. Row Level Security（RLS）政策

> ⚠️ 所有資料表都必須開啟 RLS，否則任何人都能讀取所有資料。

### 3-1. applications

```sql
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- 用戶只能讀取自己的申請
CREATE POLICY "users_read_own_application"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

-- 用戶只能新增自己的申請
CREATE POLICY "users_insert_own_application"
  ON applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 管理員可以讀取所有申請
CREATE POLICY "admins_read_all_applications"
  ON applications FOR SELECT
  USING (auth.jwt() ->> 'user_role' = 'admin');

-- 管理員可以更新審核狀態
CREATE POLICY "admins_update_applications"
  ON applications FOR UPDATE
  USING (auth.jwt() ->> 'user_role' = 'admin');
```

### 3-2. profiles

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 已通過審核的用戶可以看其他用戶的 profile（未刪除、啟用中）
CREATE POLICY "approved_users_read_profiles"
  ON profiles FOR SELECT
  USING (
    is_deleted = FALSE AND is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM applications
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

-- 用戶只能更新自己的 profile
CREATE POLICY "users_update_own_profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 用戶可以 soft delete 自己的帳號
CREATE POLICY "users_delete_own_profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

### 3-3. swipes

```sql
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;

-- 用戶只能讀取自己發出的 swipe
CREATE POLICY "users_read_own_swipes"
  ON swipes FOR SELECT
  USING (auth.uid() = from_user_id);

-- 用戶只能新增自己的 swipe
CREATE POLICY "users_insert_own_swipes"
  ON swipes FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);
```

### 3-4. matches

```sql
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- 用戶只能看自己的配對
CREATE POLICY "users_read_own_matches"
  ON matches FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);
```

### 3-5. messages

```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 用戶只能看自己參與的配對的訊息
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

-- 用戶只能發送自己配對中的訊息
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
```

### 3-6. blocks

```sql
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

-- 用戶只能看自己的封鎖列表
CREATE POLICY "users_manage_own_blocks"
  ON blocks FOR ALL
  USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);
```

### 3-8. user_events

```sql
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;

-- 用戶只能寫入自己的事件（不允許讀取，分析由後端進行）
CREATE POLICY "users_insert_own_events"
  ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 管理員可以讀取所有事件供分析
CREATE POLICY "admins_read_all_events"
  ON user_events FOR SELECT USING (auth.jwt() ->> 'user_role' = 'admin');
```

### 3-9. reports

```sql
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- 用戶只能新增檢舉
CREATE POLICY "users_insert_reports"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- 管理員可以讀取和更新所有檢舉
CREATE POLICY "admins_manage_reports"
  ON reports FOR ALL
  USING (auth.jwt() ->> 'user_role' = 'admin');
```

---

## 4. Index 索引規劃

```sql
-- ─── applications ────────────────────────────────
-- 審核後台按狀態篩選
CREATE INDEX idx_applications_status
  ON applications(status, created_at DESC);

-- 用戶查詢自己的申請
CREATE INDEX idx_applications_user_id
  ON applications(user_id);

-- ─── profiles ────────────────────────────────────
-- 探索頁：篩選活躍用戶，用 cursor 分頁
CREATE INDEX idx_profiles_active
  ON profiles(is_active, is_deleted, created_at DESC)
  WHERE is_active = TRUE AND is_deleted = FALSE;

-- ─── swipes ──────────────────────────────────────
-- 探索頁：排除已滑過的用戶（最核心的查詢）
CREATE INDEX idx_swipes_from_user
  ON swipes(from_user_id, to_user_id);

-- 配對觸發：檢查對方是否 like 過我
CREATE INDEX idx_swipes_like_check
  ON swipes(to_user_id, from_user_id, direction)
  WHERE direction = 'like';

-- ─── matches ─────────────────────────────────────
-- 配對列表查詢
CREATE INDEX idx_matches_user1
  ON matches(user1_id, created_at DESC);

CREATE INDEX idx_matches_user2
  ON matches(user2_id, created_at DESC);

-- ─── messages ────────────────────────────────────
-- 聊天室載入訊息
CREATE INDEX idx_messages_match_time
  ON messages(match_id, created_at ASC);

-- ─── blocks ──────────────────────────────────────
-- 探索頁：排除已封鎖的用戶
CREATE INDEX idx_blocks_blocker
  ON blocks(blocker_id, blocked_id);
```

---

## 5. Storage Bucket 設計

### Bucket 1：`application-photos`（私有）

```
用途：    申請審核照片，只有本人和管理員可存取
存取：    私有（需 signed URL，有效期 1 小時）
路徑規則：application-photos/{user_id}/{filename}.jpg
保留策略：審核拒絕後 → 30 天自動刪除（Edge Function 排程）
```

### Bucket 2：`profile-photos`（私有）

```
用途：    個人頭貼與照片，只有通過審核的用戶可存取
存取：    私有（需 signed URL）
路徑規則：profile-photos/{user_id}/{filename}.jpg
保留策略：帳號刪除後 → 立即刪除
```

### Storage RLS Policy

```sql
-- application-photos：用戶只能上傳自己的資料夾
CREATE POLICY "users_upload_own_photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'application-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 管理員可以讀取所有申請照片
CREATE POLICY "admins_read_all_application_photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'application-photos' AND
    auth.jwt() ->> 'user_role' = 'admin'
  );
```

---

## 6. Edge Functions 清單

| Function 名稱 | 觸發時機 | 功能 |
|-------------|---------|------|
| `on-application-reviewed` | applications.status 更新時 | 發送審核結果 Email + FCM 推播給申請者 |
| `on-match-created` | matches INSERT 時 | 向雙方發送「配對成功」FCM 推播 |
| `on-message-sent` | messages INSERT 時 | 向對方（背景中）發送「新訊息」FCM 推播 |
| `cleanup-rejected-photos` | 每日排程（CRON）| 刪除被拒絕且超過 30 天的申請照片 |
| `cleanup-deleted-accounts` | 每日排程（CRON）| 清除軟刪除超過 30 天的帳號資料 |
| `cleanup-stale-tokens` | 每週排程（CRON）| 刪除超過 60 天未更新的失效 FCM Token |
| `aggregate-user-events` | 每日排程（CRON）| 彙總前一天的行為事件，寫入 daily_stats 分析表 |

---

## 7. 初始化執行順序

```
在 Supabase SQL Editor 依序執行：

Step 1：建立 update_updated_at Function
Step 2：建立 applications 表 + trigger
Step 3：建立 profiles 表 + trigger
Step 4：建立 swipes 表
Step 5：建立 check_and_create_match Function + trigger
Step 6：建立 matches 表
Step 7：建立 messages 表
Step 8：建立 reports 表
Step 9：建立 blocks 表
Step 10：建立 device_tokens 表 + trigger
Step 11：建立 user_events 表
Step 12：開啟所有資料表的 RLS + 新增 Policy（含 user_events）
Step 13：建立所有 Index（含 user_events GIN index）
Step 14：執行 storage_buckets migration（建立 Bucket + RLS Policy）
Step 15：在 Firebase Console 建立 FCM 專案，取得 Service Account Key
Step 16：將 FCM Service Account Key 存入 Supabase Secrets
Step 17：部署 Edge Functions

> ✅ **已完成（CLI 自動化）**：Steps 1–14 已透過 `supabase db push` 完成。
> 專案 Reference ID：`xzqwzpwpjofpkbewkwzx`（Tokyo region）
```

---

> 📌 **重要提醒**：每次修改 Schema 都需要同步更新本文件，保持文件與實際 DB 一致。
