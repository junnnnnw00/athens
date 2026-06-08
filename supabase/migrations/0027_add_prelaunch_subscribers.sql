-- Migration: add prelaunch_subscribers table for newsletter signups on the landing page
-- Allows anonymous visitors to subscribe to launch notifications.

CREATE TABLE IF NOT EXISTS public.prelaunch_subscribers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.prelaunch_subscribers ENABLE ROW LEVEL SECURITY;

-- Allow public insert only (cannot select/update/delete for privacy)
CREATE POLICY "Allow public insert to prelaunch_subscribers" ON public.prelaunch_subscribers
  FOR INSERT WITH CHECK (true);
