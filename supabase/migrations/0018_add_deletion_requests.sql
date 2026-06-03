-- Migration: add deletion_requests table for GDPR/Google Play compliance
-- Allows users to submit account and data deletion requests from the web.

CREATE TABLE IF NOT EXISTS public.deletion_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.deletion_requests ENABLE ROW LEVEL SECURITY;

-- Allow public insert only (cannot select/update/delete for privacy)
CREATE POLICY "Allow public insert to deletion_requests" ON public.deletion_requests
  FOR INSERT WITH CHECK (true);
