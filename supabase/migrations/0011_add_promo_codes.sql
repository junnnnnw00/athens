-- Create promo_codes table
CREATE TABLE IF NOT EXISTS public.promo_codes (
    code text PRIMARY KEY,
    is_used boolean NOT NULL DEFAULT false,
    used_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    used_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on promo_codes
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

-- Allow users to view only their own redeemed promo codes
CREATE POLICY select_my_promo_codes ON public.promo_codes
    FOR SELECT TO authenticated
    USING (used_by = auth.uid());

-- Function to redeem a promo code and activate premium
CREATE OR REPLACE FUNCTION public.redeem_promo_code(input_code text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code_exists_and_valid boolean;
BEGIN
    -- Ensure the user is logged in
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Normalize the code (trim whitespace and make uppercase for user convenience)
    input_code := UPPER(TRIM(input_code));

    -- Check if the code is valid and unused
    SELECT EXISTS (
        SELECT 1 FROM public.promo_codes 
        WHERE code = input_code AND is_used = false
    ) INTO code_exists_and_valid;

    IF code_exists_and_valid THEN
        -- Mark code as used
        UPDATE public.promo_codes
        SET is_used = true,
            used_by = auth.uid(),
            used_at = now()
        WHERE code = input_code;

        -- Update user profile to premium
        UPDATE public.profiles
        SET is_premium = true
        WHERE id = auth.uid();

        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$;

-- Insert default promo code
INSERT INTO public.promo_codes (code, is_used)
VALUES ('HEREISYOURCOFFEESIR', false)
ON CONFLICT (code) DO NOTHING;
