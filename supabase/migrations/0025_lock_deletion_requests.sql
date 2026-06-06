-- ============================================================================
-- 0025_lock_deletion_requests.sql
-- Lock down deletion_requests: the old "Allow public insert" policy let ANYONE
-- (anon, no auth) insert an arbitrary email — spam / malicious deletion requests
-- against the table. In-app deletion now runs through the authenticated
-- `delete-account` edge function (real cascade delete); the web form is a backup
-- that signs the user in first, so authenticated-only insert is sufficient.
--
-- Reversible: restore the old policy WITH CHECK (true) FOR INSERT.
-- ============================================================================

-- The old policy name (with spaces) must be quoted verbatim to drop it.
DROP POLICY IF EXISTS "Allow public insert to deletion_requests" ON public.deletion_requests;  -- noqa: RF05

-- Authenticated users may file a request for their OWN email only. service_role
-- (the edge function path) bypasses RLS entirely, so this only governs the web
-- backup form.
CREATE POLICY deletion_requests_insert_self
ON public.deletion_requests
FOR INSERT TO authenticated
WITH CHECK (lower(email) = lower(auth.jwt() ->> 'email'));
