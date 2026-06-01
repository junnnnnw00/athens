-- 1. Add is_premium column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false;

-- 2. Update public_profiles view to include is_premium
CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = false)
AS
SELECT
    p.id,
    p.handle,
    p.display_name,
    p.avatar_url,
    p.bio,
    p.is_premium,
    p.created_at,
    -- Top 10 rated items
    (
        SELECT COALESCE(JSON_AGG(ranked ORDER BY ranked.score DESC), '[]'::json)
        FROM (
            SELECT
                i.id,
                i.kind,
                i.title,
                i.primary_artist,
                i.image_url,
                i.tags,
                r.score,
                r.comparisons
            FROM ratings r
            INNER JOIN items i ON r.item_id = i.id
            WHERE r.user_id = p.id AND r.comparisons >= 1
            ORDER BY r.score DESC
            LIMIT 10
        ) ranked
    ) AS top_items,
    -- Aggregate stats
    (
        SELECT
            JSON_BUILD_OBJECT(
                'total_rated', COUNT(*),
                'avg_score', ROUND(AVG(score)::numeric, 2),
                'total_comparisons', SUM(comparisons)
            )
        FROM ratings
        WHERE user_id = p.id
    ) AS stats
FROM profiles p
WHERE p.is_public = true;

-- 3. Create follows table for friendship/following connection
CREATE TABLE IF NOT EXISTS public.follows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    following_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (follower_id, following_id),
    CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

-- Enable RLS on follows
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for follows table
CREATE POLICY follows_select ON public.follows
    FOR SELECT TO authenticated USING (true);

CREATE POLICY follows_insert ON public.follows
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);

CREATE POLICY follows_delete ON public.follows
    FOR DELETE TO authenticated USING (auth.uid() = follower_id);

-- 4. Enable public reading of ratings if the rating's owner profile is public
CREATE POLICY ratings_select_public ON public.ratings
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE public.profiles.id = ratings.user_id AND public.profiles.is_public = true
        )
    );
