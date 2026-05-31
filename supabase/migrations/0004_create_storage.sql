-- ============================================================================
-- Create storage bucket 'avatars' and set up RLS policies
-- ============================================================================

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;


-- Allow public read access to all avatars
DROP POLICY IF EXISTS "Public Read Access" ON storage.objects;
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload/insert avatars
DROP POLICY IF EXISTS "Insert Avatar Policy" ON storage.objects;
CREATE POLICY "Insert Avatar Policy"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Allow authenticated users to update their own/any avatars in the bucket
DROP POLICY IF EXISTS "Update Avatar Policy" ON storage.objects;
CREATE POLICY "Update Avatar Policy"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Allow authenticated users to delete avatars in the bucket
DROP POLICY IF EXISTS "Delete Avatar Policy" ON storage.objects;
CREATE POLICY "Delete Avatar Policy"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');
