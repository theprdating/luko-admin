-- Fix: beta import user (407411353@gms.tku.edu.tw) had full public URLs stored
-- in profiles.photo_paths and photo_change_requests.new_photo_paths instead of
-- relative storage paths. getSignedUrl() expects relative paths only.

UPDATE profiles
SET photo_paths = ARRAY[
  'beta_import/407411353@gms.tku.edu.tw/0.png',
  'beta_import/407411353@gms.tku.edu.tw/1.png'
]
WHERE id = '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d'
  AND photo_paths[1] LIKE 'https://%';

UPDATE photo_change_requests
SET new_photo_paths = ARRAY[
  'beta_import/407411353@gms.tku.edu.tw/0.png',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_1.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_2.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_3.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_4.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_5.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_6.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_7.jpg',
  '03af7f5a-3226-4c4f-89fe-7ba6ca3ee00d/1776629167037_8.jpg'
]
WHERE id = '0402163c-9c7d-46f8-bc27-01c0c9075586'
  AND new_photo_paths[1] LIKE 'https://%';
