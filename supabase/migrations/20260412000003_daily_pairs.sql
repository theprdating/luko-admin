-- ══════════════════════════════════════════════════════════════════════════════
-- daily_pairs — 每日對稱配對系統
--
-- 設計概念：
--   每天台灣時間凌晨 12:00（UTC 16:00），批次為所有資格用戶產生當日配對 pair。
--   一個 pair 只存一筆（user_a_id < user_b_id），雙方都能看到彼此。
--   批次使用 greedy b-matching：隨機排序所有相容 pair，依序納入，
--   只要雙方都還有名額（≤ daily_pair_limit）即成立。
--   每日結束後不做任何清理——用戶明天自然看到新的人，舊 pair 留存供分析。
-- ══════════════════════════════════════════════════════════════════════════════


-- ── 1. daily_pairs 資料表 ──────────────────────────────────────────────────────

CREATE TABLE daily_pairs (
  user_a_id   uuid  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b_id   uuid  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pair_date   date  NOT NULL,   -- 台灣日期，例如 '2026-04-13'
  created_at  timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (user_a_id, user_b_id, pair_date),

  -- 強制 user_a_id < user_b_id，確保每對 pair 只有一種方向
  CONSTRAINT daily_pairs_order CHECK (user_a_id < user_b_id)
);

-- 兩個方向的查詢各自需要一個 index：
--   WHERE user_a_id = $me AND pair_date = $today
--   WHERE user_b_id = $me AND pair_date = $today
CREATE INDEX idx_daily_pairs_a ON daily_pairs (user_a_id, pair_date);
CREATE INDEX idx_daily_pairs_b ON daily_pairs (user_b_id, pair_date);


-- ── 2. RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE daily_pairs ENABLE ROW LEVEL SECURITY;

-- 用戶只能看到自己所在的 pair
CREATE POLICY "users_see_own_pairs"
  ON daily_pairs FOR SELECT
  USING (
    auth.uid() = user_a_id OR
    auth.uid() = user_b_id
  );

-- 只有 service role 可以寫入（由批次函式負責）
CREATE POLICY "service_role_insert_pairs"
  ON daily_pairs FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "service_role_delete_pairs"
  ON daily_pairs FOR DELETE
  USING (auth.role() = 'service_role');


-- ── 3. app_config：每日配對人數上限 ──────────────────────────────────────────

-- 批次執行時從此讀取，調整此值即可改變每日配對人數，無需改 code
INSERT INTO app_config (key, value)
VALUES ('daily_pair_limit', '3')
ON CONFLICT (key) DO NOTHING;


-- ── 4. 批次函式：generate_daily_pairs() ──────────────────────────────────────
--
-- 演算法：greedy b-matching
--   1. 撈出所有今日資格用戶（approved + phone + interests + questions）
--   2. 產生所有相容 pair（雙向 seeking 符合 + 近 30 天沒出現過）並隨機排序
--   3. 依序遍歷：雙方都還有名額 → 納入，否則跳過
--   4. 直到所有 pair 都處理完，或所有人都填滿名額為止
--
-- 時間複雜度：O(E)，E = 相容 pair 數量
--   1K 用戶 ≈ 250K pairs → < 1 秒
--   10K 用戶 ≈ 25M pairs → 約 30–60 秒（仍在可接受範圍）
--
-- 冪等性：每次執行前先刪除今日舊資料，安全重跑。

CREATE OR REPLACE FUNCTION generate_daily_pairs()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_pair_date    date;
  v_daily_limit  int;
  v_pair         record;
  v_slots_a      int;
  v_slots_b      int;
  v_inserted     int := 0;
  v_skipped      int := 0;
  v_total_slots  int;
BEGIN
  -- ── 台灣當日日期（UTC+8，無夏令時間）
  v_pair_date := (NOW() AT TIME ZONE 'Asia/Taipei')::date;

  -- ── 從 app_config 讀取每日上限（預設 3）
  SELECT COALESCE(value::int, 3) INTO v_daily_limit
  FROM app_config
  WHERE key = 'daily_pair_limit';

  -- ── 冪等：重跑時先清除今天的舊資料
  DELETE FROM daily_pairs WHERE pair_date = v_pair_date;

  -- ── 建立 temp table：今日資格用戶 + 剩餘名額
  DROP TABLE IF EXISTS _eligible;
  CREATE TEMP TABLE _eligible (
    user_id   uuid PRIMARY KEY,
    gender    text NOT NULL,
    seeking   text[] NOT NULL,
    slots     int  NOT NULL    -- 還能配幾個人
  ) ON COMMIT DROP;

  INSERT INTO _eligible (user_id, gender, seeking, slots)
  SELECT
    p.id,
    p.gender,
    p.seeking,
    v_daily_limit
  FROM profiles p
  JOIN applications a ON a.user_id = p.id
  JOIN auth.users   u ON u.id      = p.id
  WHERE p.is_active  = true
    AND p.is_deleted = false
    AND a.status     = 'approved'
    AND u.phone IS NOT NULL AND u.phone <> ''
    AND p.interests IS NOT NULL
    AND array_length(p.interests, 1) > 0
    AND p.question_answers IS NOT NULL
    AND jsonb_array_length(p.question_answers) > 0;

  -- ── 建立 temp table：所有相容 pair，隨機排序（只建一次）
  --
  --    條件：
  --      • user_a_id < user_b_id（避免 A-B 和 B-A 重複）
  --      • 雙向 seeking 相容
  --      • 近 30 天沒有配過（防止一直看到同一個人）
  --      • swipes 表中任一方向無紀錄（有紀錄代表已表態過，不再配對）
  --        - A liked B 但 B 沒回應 → swipes(A→B) 存在 → 永久排除
  --        - B liked A 但 A 沒回應 → swipes(B→A) 存在 → 永久排除
  --        - 雙方都 liked → 已配對，同樣排除
  --        - 雙方都沒動作 → swipes 無紀錄 → 30 天後可重新配
  --
  --    備註：若 seeking 包含 'everyone'，需在條件中加入
  --          'everyone' = ANY(seeking) 的判斷。

  DROP TABLE IF EXISTS _candidates;
  CREATE TEMP TABLE _candidates (
    rn        bigint PRIMARY KEY,  -- 隨機排序後的序號，方便依序遍歷
    user_a_id uuid NOT NULL,
    user_b_id uuid NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO _candidates (rn, user_a_id, user_b_id)
  SELECT
    ROW_NUMBER() OVER (ORDER BY random()),
    LEAST(a.user_id, b.user_id),
    GREATEST(a.user_id, b.user_id)
  FROM _eligible a
  JOIN _eligible b ON b.user_id > a.user_id
  WHERE
    -- 雙向 seeking 相容
    (b.gender = ANY(a.seeking) OR 'everyone' = ANY(a.seeking))
    AND (a.gender = ANY(b.seeking) OR 'everyone' = ANY(b.seeking))
    -- 近 30 天沒有在同一個 pair 出現過（雙方都無動作才允許重配）
    AND NOT EXISTS (
      SELECT 1
      FROM daily_pairs dp
      WHERE dp.user_a_id = LEAST(a.user_id, b.user_id)
        AND dp.user_b_id = GREATEST(a.user_id, b.user_id)
        AND dp.pair_date >= v_pair_date - INTERVAL '30 days'
    )
    -- 任一方向曾有 like 紀錄 → 永久排除（已表態，不再安排見面）
    AND NOT EXISTS (
      SELECT 1
      FROM swipes s
      WHERE (s.from_user_id = a.user_id AND s.to_user_id = b.user_id)
         OR (s.from_user_id = b.user_id AND s.to_user_id = a.user_id)
    );

  -- ── greedy b-matching 主迴圈
  --
  --    Early exit：當所有人的剩餘名額加總為 0，代表全員填滿，提前結束。
  --    這讓迴圈在用戶數少、名額快速填滿時比 O(E) 更快結束。

  FOR v_pair IN
    SELECT rn, user_a_id, user_b_id FROM _candidates ORDER BY rn
  LOOP
    -- 檢查雙方目前剩餘名額（讀取最新狀態，不是快照）
    SELECT slots INTO v_slots_a FROM _eligible WHERE user_id = v_pair.user_a_id;
    SELECT slots INTO v_slots_b FROM _eligible WHERE user_id = v_pair.user_b_id;

    IF v_slots_a > 0 AND v_slots_b > 0 THEN
      -- 雙方都有名額，納入這個 pair
      INSERT INTO daily_pairs (user_a_id, user_b_id, pair_date)
      VALUES (v_pair.user_a_id, v_pair.user_b_id, v_pair_date)
      ON CONFLICT DO NOTHING;

      UPDATE _eligible SET slots = slots - 1 WHERE user_id = v_pair.user_a_id;
      UPDATE _eligible SET slots = slots - 1 WHERE user_id = v_pair.user_b_id;

      v_inserted := v_inserted + 1;
    ELSE
      v_skipped := v_skipped + 1;
    END IF;

    -- Early exit：所有人都填滿了
    SELECT COALESCE(SUM(slots), 0) INTO v_total_slots FROM _eligible;
    EXIT WHEN v_total_slots = 0;
  END LOOP;

  RETURN jsonb_build_object(
    'date',           v_pair_date,
    'pairs_inserted', v_inserted,
    'pairs_skipped',  v_skipped,
    'daily_limit',    v_daily_limit
  );

EXCEPTION WHEN OTHERS THEN
  -- 記錄錯誤但不讓整個批次靜默失敗
  RAISE WARNING 'generate_daily_pairs failed: %', SQLERRM;
  RETURN jsonb_build_object(
    'error', SQLERRM,
    'date',  v_pair_date
  );
END;
$$;


-- ── 5. pg_cron 排程：每天 UTC 16:00 = 台灣凌晨 12:00 ────────────────────────
--
-- 前置條件：需在 Supabase Dashboard → Database → Extensions 啟用 pg_cron。
-- 確認方式：SELECT * FROM cron.job;

SELECT cron.schedule(
  'luko-daily-pair-generation',       -- job 名稱（唯一）
  '0 16 * * *',                       -- cron 表達式，UTC 16:00
  'SELECT generate_daily_pairs()'     -- 執行的 SQL
);
