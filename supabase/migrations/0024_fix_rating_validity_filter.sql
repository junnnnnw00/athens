-- ============================================================================
-- 0024_fix_rating_validity_filter.sql
-- Fix the community-stats "valid rating" filter so a directly-scored rating
-- (user set a score on add, e.g. via the initial-score dialog → elo != 1000)
-- counts even if it hasn't been through a duel yet (comparisons = 0).
--
-- Bug: item_rating_stats / snapshot_item_ratings used `comparisons >= 1`, which
-- dropped such ratings. A song with 3 raters where one scored it directly showed
-- count 2 → below the min_n=3 privacy threshold → community avg/distribution
-- stayed hidden. The only true placeholder is `comparisons = 0 AND elo = 1000`
-- (added but never scored or dueled); everything else is a real rating.
--
-- Scope: only the two item-level community functions. The public_profiles views
-- keep their own `comparisons >= 1` rule (separate concern, not touched here).
--
-- Reversible: re-CREATE the two functions with the old `comparisons >= 1` filter.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.item_rating_stats(
    p_item_id uuid,
    min_n int DEFAULT 3
)
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH r AS (
        SELECT score
        FROM ratings
        WHERE item_id = p_item_id AND (comparisons >= 1 OR elo <> 1000)
    ), agg AS (
        SELECT COUNT(*)::int AS n, ROUND(AVG(score)::numeric, 2) AS avg_score
        FROM r
    )
    SELECT JSON_BUILD_OBJECT(
        'count', agg.n,
        'avg', CASE WHEN agg.n >= min_n THEN agg.avg_score ELSE NULL END,
        'distribution', CASE WHEN agg.n >= min_n THEN (
            SELECT JSON_BUILD_ARRAY(
                COUNT(*) FILTER (WHERE score >= 0 AND score < 1),
                COUNT(*) FILTER (WHERE score >= 1 AND score < 2),
                COUNT(*) FILTER (WHERE score >= 2 AND score < 3),
                COUNT(*) FILTER (WHERE score >= 3 AND score < 4),
                COUNT(*) FILTER (WHERE score >= 4 AND score < 5),
                COUNT(*) FILTER (WHERE score >= 5 AND score < 6),
                COUNT(*) FILTER (WHERE score >= 6 AND score < 7),
                COUNT(*) FILTER (WHERE score >= 7 AND score < 8),
                COUNT(*) FILTER (WHERE score >= 8 AND score < 9),
                COUNT(*) FILTER (WHERE score >= 9 AND score <= 10)
            ) FROM r
        ) ELSE NULL END
    )
    FROM agg;
$$;

CREATE OR REPLACE FUNCTION public.snapshot_item_ratings()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    INSERT INTO item_rating_daily (item_id, day, rating_count, avg_score)
    SELECT item_id, CURRENT_DATE, COUNT(*)::int, ROUND(AVG(score)::numeric, 2)
    FROM ratings
    WHERE comparisons >= 1 OR elo <> 1000
    GROUP BY item_id
    ON CONFLICT (item_id, day)
    DO UPDATE SET rating_count = excluded.rating_count,
                  avg_score = excluded.avg_score;
$$;

-- Refresh today's snapshot so the fix reflects immediately.
SELECT public.snapshot_item_ratings();
