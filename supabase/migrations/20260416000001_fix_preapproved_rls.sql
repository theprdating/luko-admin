-- Fix: preapproved_emails RLS was querying auth.users directly,
-- which the 'authenticated' role has no SELECT permission on.
-- Replace with auth.email() built-in function.

DROP POLICY IF EXISTS "Users can check their own preapproval" ON preapproved_emails;

CREATE POLICY "Users can check their own preapproval"
  ON preapproved_emails FOR SELECT
  TO authenticated
  USING (email = auth.email());
