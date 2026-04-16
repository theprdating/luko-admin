-- Fix source tag for PD Dating migrated rows
-- All 275 rows inserted by 20260415000002 got default source='beta_v1'
-- Update them based on emails that existed in pd_dating applications
-- Since we can't easily distinguish, update all non-beta rows by checking
-- they have display_name (beta_v1 rows were inserted without display_name initially)
-- Actually: the one original row (407411353@gms.tku.edu.tw) has display_name=NULL
-- All 275 new rows have display_name set → safe to use as discriminator

UPDATE preapproved_emails
SET source = 'pd_dating_v1'
WHERE source = 'beta_v1'
  AND display_name IS NOT NULL;
