-- 1. Drop public_profiles view
DROP VIEW IF EXISTS public.public_profiles CASCADE;

-- 2. Create public_profiles view to include is_premium, distribution, and tag_preferences
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
                r.comparisons,
                r.updated_at
            FROM ratings r
            INNER JOIN items i ON r.item_id = i.id
            WHERE r.user_id = p.id AND r.comparisons >= 1
            ORDER BY r.score DESC
        ) ranked
    ) AS top_items,
    -- Aggregate stats with distribution bucket counts & tag preferences
    (
        SELECT
            JSON_BUILD_OBJECT(
                'total_rated', COUNT(*),
                'avg_score', ROUND(AVG(score)::numeric, 2),
                'total_comparisons', SUM(comparisons),
                'distribution', JSON_BUILD_OBJECT(
                    '0', COUNT(*) FILTER (WHERE score >= 0 AND score < 1),
                    '1', COUNT(*) FILTER (WHERE score >= 1 AND score < 2),
                    '2', COUNT(*) FILTER (WHERE score >= 2 AND score < 3),
                    '3', COUNT(*) FILTER (WHERE score >= 3 AND score < 4),
                    '4', COUNT(*) FILTER (WHERE score >= 4 AND score < 5),
                    '5', COUNT(*) FILTER (WHERE score >= 5 AND score < 6),
                    '6', COUNT(*) FILTER (WHERE score >= 6 AND score < 7),
                    '7', COUNT(*) FILTER (WHERE score >= 7 AND score < 8),
                    '8', COUNT(*) FILTER (WHERE score >= 8 AND score < 9),
                    '9', COUNT(*) FILTER (WHERE score >= 9 AND score <= 10)
                ),
                'tag_preferences', (
                    SELECT COALESCE(JSON_AGG(tag_pref), '[]'::json)
                    FROM (
                        SELECT
                            TRIM(LOWER(t->>'name')) AS name,
                            ROUND(AVG(r2.score)::numeric, 2) AS avg_score,
                            COUNT(*) AS count
                        FROM ratings r2
                        INNER JOIN items i2 ON r2.item_id = i2.id
                        CROSS JOIN LATERAL jsonb_array_elements(i2.tags) AS t
                        WHERE r2.user_id = p.id AND r2.comparisons >= 1
                        GROUP BY TRIM(LOWER(t->>'name'))
                        ORDER BY avg_score DESC, count DESC
                        LIMIT 150
                    ) tag_pref
                )
            )
        FROM ratings
        WHERE user_id = p.id
    ) AS stats
FROM profiles p
WHERE p.is_public = true;

-- 3. Grant select privileges
GRANT SELECT ON public.public_profiles TO anon;
GRANT SELECT ON public.public_profiles TO authenticated;
