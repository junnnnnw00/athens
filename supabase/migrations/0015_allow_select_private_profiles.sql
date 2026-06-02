-- Migration: Allow all authenticated users to read all profiles (including private ones) for search and friendship
-- Drop the restrictive profiles_select policy
DROP POLICY IF EXISTS profiles_select ON public.profiles;

-- Create a new policy that allows any authenticated user to view any profile
CREATE POLICY profiles_select_all ON public.profiles
    FOR SELECT TO authenticated
    USING (true);

-- Create a policy for anonymous users (like public web profile site) to only select public profiles
CREATE POLICY profiles_select_anonymous ON public.profiles
    FOR SELECT TO anon
    USING (is_public = true);
