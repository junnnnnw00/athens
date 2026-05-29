-- ============================================================================
-- Public profile view (readable by anon via security definer)
-- Only exposes data for profiles where is_public = true.
-- ============================================================================

CREATE OR REPLACE VIEW public_profiles
WITH (security_invoker = false)
AS
SELECT
    p.id,
    p.handle,
    p.display_name,
    p.avatar_url,
    p.bio,
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

-- Grant anon read access to the view.
GRANT SELECT ON public_profiles TO anon;
GRANT SELECT ON public_profiles TO authenticated;
