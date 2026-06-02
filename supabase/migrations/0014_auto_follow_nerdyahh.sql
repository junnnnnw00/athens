-- Migration: Auto follow nerdyahh_ (both ways) to enable easy testing of social features

-- Create a function that handles auto-following when a new profile is created
CREATE OR REPLACE FUNCTION public.handle_auto_follow_nerdyahh()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    nerdyahh_rec record;
BEGIN
    -- 1. If the newly created user is 'nerdyahh_', they should follow everyone, and everyone should follow them.
    IF NEW.handle = 'nerdyahh_' THEN
        -- nerdyahh_ follows everyone else
        INSERT INTO public.follows (follower_id, following_id)
        SELECT NEW.id, id FROM public.profiles 
        WHERE id <> NEW.id
        ON CONFLICT (follower_id, following_id) DO NOTHING;

        -- Everyone else follows nerdyahh_
        INSERT INTO public.follows (follower_id, following_id)
        SELECT id, NEW.id FROM public.profiles 
        WHERE id <> NEW.id
        ON CONFLICT (follower_id, following_id) DO NOTHING;
        
    ELSE
        -- 2. If it's a regular user, check if 'nerdyahh_' exists
        SELECT * FROM public.profiles WHERE handle = 'nerdyahh_' INTO nerdyahh_rec;
        IF nerdyahh_rec IS NOT NULL THEN
            -- New user follows nerdyahh_
            INSERT INTO public.follows (follower_id, following_id)
            VALUES (NEW.id, nerdyahh_rec.id)
            ON CONFLICT (follower_id, following_id) DO NOTHING;

            -- nerdyahh_ follows new user
            INSERT INTO public.follows (follower_id, following_id)
            VALUES (nerdyahh_rec.id, NEW.id)
            ON CONFLICT (follower_id, following_id) DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger on profiles
DROP TRIGGER IF EXISTS trigger_auto_follow_nerdyahh ON public.profiles;
CREATE TRIGGER trigger_auto_follow_nerdyahh
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_auto_follow_nerdyahh();

-- Existing users migration:
-- If 'nerdyahh_' profile already exists, establish bidirectional follow relations with all existing profiles.
DO $$
DECLARE
    nerdyahh_id uuid;
BEGIN
    SELECT id FROM public.profiles WHERE handle = 'nerdyahh_' INTO nerdyahh_id;
    IF nerdyahh_id IS NOT NULL THEN
        -- nerdyahh_ follows everyone
        INSERT INTO public.follows (follower_id, following_id)
        SELECT nerdyahh_id, id FROM public.profiles
        WHERE id <> nerdyahh_id
        ON CONFLICT (follower_id, following_id) DO NOTHING;

        -- Everyone follows nerdyahh_
        INSERT INTO public.follows (follower_id, following_id)
        SELECT id, nerdyahh_id FROM public.profiles
        WHERE id <> nerdyahh_id
        ON CONFLICT (follower_id, following_id) DO NOTHING;
    END IF;
END;
$$;
