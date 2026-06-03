-- ============================================================================
-- Per-item rating statistics (community + public reviews + daily trend)
--
-- Goal: on a song/album/artist detail page, show aggregate rating stats drawn
-- from ALL accounts (public AND private), while exposing only NON-IDENTIFYING
-- aggregates of private data. Individual reviews remain public-only.
--
-- Privacy model:
--   * ratings rows stay protected by the existing per-user / public-only RLS.
--   * Aggregates over private ratings are exposed ONLY through SECURITY DEFINER
--     functions that return counts / averages / distributions — never a row that
--     can be attributed to a single private user.
--   * A small-N guard (min_n) hides avg + distribution until enough accounts have
--     rated the item, so a single private rating can't be reverse-engineered.
--   * Reviews are surfaced only for accounts with profiles.is_public = true.
--
-- Reversible: DROP the two objects + functions + cron job; no column changes to
-- existing tables. See DECISIONS.md "Per-item community rating stats".
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Public reviews are readable when the author's profile is public.
--    (Mirrors ratings_select_public from 0010 for the reviews table.)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS reviews_select_public ON public.reviews;
CREATE POLICY reviews_select_public ON public.reviews
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE public.profiles.id = reviews.user_id
              AND public.profiles.is_public = true
        )
    );

-- ----------------------------------------------------------------------------
-- 2. Daily per-item aggregate snapshots — the only source of "trend over time".
--    ratings holds current state only, so trend is captured going forward by a
--    nightly job. Only aggregates are stored (no per-user data), so the table is
--    safe to read directly.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.item_rating_daily (
    item_id uuid NOT NULL REFERENCES public.items (id) ON DELETE CASCADE,
    day date NOT NULL,
    rating_count int NOT NULL,
    avg_score numeric NOT NULL,
    PRIMARY KEY (item_id, day)
);

ALTER TABLE public.item_rating_daily ENABLE ROW LEVEL SECURITY;

-- Aggregate-only, non-identifying → readable by any authenticated user.
DROP POLICY IF EXISTS item_rating_daily_select ON public.item_rating_daily;
CREATE POLICY item_rating_daily_select ON public.item_rating_daily
    FOR SELECT TO authenticated USING (true);
-- No insert/update/delete policy: only the SECURITY DEFINER snapshot fn writes.

-- ----------------------------------------------------------------------------
-- 3. item_rating_stats(item_id) — point-in-time aggregate across ALL accounts.
--    Returns: { count, avg, distribution: [c0..c9] }.
--    avg + distribution are withheld until count >= min_n (default 3) so a lone
--    private rating cannot be read off the average.
-- ----------------------------------------------------------------------------
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
        WHERE item_id = p_item_id AND comparisons >= 1
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

GRANT EXECUTE ON FUNCTION public.item_rating_stats(uuid, int) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 4. item_rating_trend(item_id) — daily community average over time.
--    Sourced from item_rating_daily; only days with enough accounts are returned.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.item_rating_trend(
    p_item_id uuid,
    min_n int DEFAULT 3
)
RETURNS TABLE (day date, rating_count int, avg_score numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT day, rating_count, avg_score
    FROM item_rating_daily
    WHERE item_id = p_item_id AND rating_count >= min_n
    ORDER BY day ASC;
$$;

GRANT EXECUTE ON FUNCTION public.item_rating_trend(uuid, int) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 5. item_public_reviews(item_id) — reviews from PUBLIC accounts only, with
--    enough author profile info to render an attribution row.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.item_public_reviews(p_item_id uuid)
RETURNS TABLE (
    user_id uuid,
    handle citext,
    display_name text,
    avatar_url text,
    body text,
    rating_snapshot numeric,
    updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        rv.user_id,
        p.handle,
        p.display_name,
        p.avatar_url,
        rv.body,
        rv.rating_snapshot,
        rv.updated_at
    FROM reviews rv
    JOIN profiles p ON p.id = rv.user_id
    WHERE rv.item_id = p_item_id
      AND p.is_public = true
      AND length(trim(rv.body)) > 0
    ORDER BY rv.updated_at DESC
    LIMIT 50;
$$;

GRANT EXECUTE ON FUNCTION public.item_public_reviews(uuid) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 6. snapshot_item_ratings() — upserts today's aggregate for every item that
--    has at least one real (compared) rating. Idempotent within a day.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.snapshot_item_ratings()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    INSERT INTO item_rating_daily (item_id, day, rating_count, avg_score)
    SELECT item_id, CURRENT_DATE, COUNT(*)::int, ROUND(AVG(score)::numeric, 2)
    FROM ratings
    WHERE comparisons >= 1
    GROUP BY item_id
    ON CONFLICT (item_id, day)
    DO UPDATE SET rating_count = EXCLUDED.rating_count,
                  avg_score = EXCLUDED.avg_score;
$$;

-- Seed today's point so the trend isn't empty on day one.
SELECT public.snapshot_item_ratings();

-- ----------------------------------------------------------------------------
-- 7. Nightly schedule via pg_cron. Wrapped so the migration still applies on
--    stacks where pg_cron isn't available (e.g. some local setups); the hosted
--    project has it. Re-running the migration replaces the job cleanly.
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'snapshot-item-ratings') THEN
        PERFORM cron.unschedule('snapshot-item-ratings');
    END IF;
    PERFORM cron.schedule(
        'snapshot-item-ratings',
        '5 0 * * *',
        'SELECT public.snapshot_item_ratings();'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron not scheduled (extension unavailable): %', SQLERRM;
END $$;
