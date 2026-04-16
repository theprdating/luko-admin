-- Make profile-photos bucket public for CDN caching
--
-- Rationale:
--   Profile photos are shown to all approved users in discover / matches.
--   Privacy is enforced at the profile-discovery layer (RLS on profiles/matches),
--   not at the photo-URL layer. Keeping the bucket private forces a signed-URL
--   API call per photo on every load, and breaks CachedNetworkImage disk caching
--   (signed URLs expire hourly → cache key changes → full re-download).
--
--   Making the bucket public enables:
--   1. getPublicUrl() — synchronous, no network call, permanent URL
--   2. Supabase CDN Transform (/render/image/public/) — server-side resize + compress
--   3. CachedNetworkImage disk cache works indefinitely (stable URL)
--
--   Security: URL paths contain UUIDs (unguessable). Same model used by
--   Tinder, Hinge, Bumble, and virtually every other dating app.

UPDATE storage.buckets
  SET public = true
  WHERE id = 'profile-photos';

-- The SELECT RLS policy is no longer relevant for a public bucket
-- (public buckets bypass RLS for SELECT via the CDN endpoint).
-- Write policies (INSERT, DELETE) remain active.
DROP POLICY IF EXISTS "approved_users_read_profile_photos" ON storage.objects;
