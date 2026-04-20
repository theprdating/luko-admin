-- Backfill identity_verifications for existing beta users who have source_verify_urls
-- but no identity_verifications row (they registered in the old Supabase org).
-- Mapping: [1]=front_face, [2]=side_face, [last]=action1+action2 (shown twice).
-- action codes stored as '' since beta users had no liveness challenge codes.

INSERT INTO identity_verifications (
  user_id, front_face_path, side_face_path,
  action1_code, action1_path,
  action2_code, action2_path,
  status
)
SELECT
  au.id,
  pe.source_verify_urls[1],
  pe.source_verify_urls[2],
  '',
  pe.source_verify_urls[array_length(pe.source_verify_urls, 1)],
  '',
  pe.source_verify_urls[array_length(pe.source_verify_urls, 1)],
  'approved'
FROM preapproved_emails pe
JOIN auth.users au ON lower(au.email) = lower(pe.email)
WHERE pe.source_verify_urls IS NOT NULL
  AND array_length(pe.source_verify_urls, 1) >= 2
  AND NOT EXISTS (
    SELECT 1 FROM identity_verifications iv WHERE iv.user_id = au.id
  );
