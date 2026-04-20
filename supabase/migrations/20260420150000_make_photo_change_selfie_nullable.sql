-- photo_change_requests.selfie_path を nullable に変更
-- 理由：review-photo-change edge function が審核後に selfie_path = null を
-- セットしようとするが、NOT NULL 制約で UPDATE 失敗 → status が 'pending'
-- のまま残り、管理画面に審核済み申請が再表示されるバグを修正。
ALTER TABLE photo_change_requests
  ALTER COLUMN selfie_path DROP NOT NULL;
