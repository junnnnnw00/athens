-- Migration: add play_purchase_token to profiles
-- Stores the Google Play purchase token for receipt verification and
-- refund detection. Nullable — only populated for Play Store purchases.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS play_purchase_token TEXT;

COMMENT ON COLUMN public.profiles.play_purchase_token IS
  'Google Play purchase token set by the verify-play-purchase edge function. '
  'Used for server-side receipt validation and refund detection.';
