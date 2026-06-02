-- Migration: Add multi-use promo codes support
-- Add columns to promo_codes for multi-use support
ALTER TABLE public.promo_codes 
    ADD COLUMN IF NOT EXISTS max_uses integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS uses_count integer NOT NULL DEFAULT 0;

-- Create redemptions join table to track who redeemed what and when
CREATE TABLE IF NOT EXISTS public.promo_code_redemptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL REFERENCES public.promo_codes(code) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    redeemed_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(code, user_id)
);

-- Enable RLS on promo_code_redemptions
ALTER TABLE public.promo_code_redemptions ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own redemptions
CREATE POLICY select_my_redemptions ON public.promo_code_redemptions
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Migrate legacy single-use redemptions to the new join table
INSERT INTO public.promo_code_redemptions (code, user_id, redeemed_at)
SELECT code, used_by, used_at 
FROM public.promo_codes
WHERE is_used = true AND used_by IS NOT NULL
ON CONFLICT (code, user_id) DO NOTHING;

-- Adjust uses_count for legacy redeemed codes
UPDATE public.promo_codes
SET uses_count = 1, max_uses = 1
WHERE is_used = true AND uses_count = 0;

-- Actually defining the body of the function
CREATE OR REPLACE FUNCTION public.redeem_promo_code(input_code text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    normalized_code text;
    code_rec record;
    already_redeemed boolean;
BEGIN
    -- Ensure the user is logged in
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Normalize the code (uppercase, trimmed)
    normalized_code := UPPER(TRIM(input_code));

    -- Lock and select the code row to prevent race conditions during redemption
    SELECT * FROM public.promo_codes 
    WHERE code = normalized_code
    FOR UPDATE
    INTO code_rec;

    -- Return false if the code doesn't exist
    IF code_rec IS NULL THEN
        RETURN false;
    END IF;

    -- Check if this specific user has already redeemed this code
    SELECT EXISTS (
        SELECT 1 FROM public.promo_code_redemptions
        WHERE code = normalized_code AND user_id = auth.uid()
    ) INTO already_redeemed;

    IF already_redeemed THEN
        RETURN false;
    END IF;

    -- Check if the code has reached its maximum uses
    IF code_rec.uses_count >= code_rec.max_uses THEN
        RETURN false;
    END IF;

    -- Record the new redemption
    INSERT INTO public.promo_code_redemptions (code, user_id, redeemed_at)
    VALUES (normalized_code, auth.uid(), now());

    -- Increment the uses count and update is_used flag for backward compatibility
    UPDATE public.promo_codes
    SET uses_count = uses_count + 1,
        is_used = (uses_count + 1 >= max_uses),
        used_by = auth.uid(), -- fallback for single-use columns
        used_at = now()       -- fallback for single-use columns
    WHERE code = normalized_code;

    -- Activate premium for the user
    UPDATE public.profiles
    SET is_premium = true
    WHERE id = auth.uid();

    RETURN true;
END;
$$;

-- Insert the PUBMAGATHENS code with 20 max uses
INSERT INTO public.promo_codes (code, max_uses, uses_count, is_used)
VALUES ('PUBMAGATHENS', 20, 0, false)
ON CONFLICT (code) DO UPDATE 
SET max_uses = EXCLUDED.max_uses;
