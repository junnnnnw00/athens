-- ============================================================================
-- 0023_admin_dashboard.sql
-- Server-side aggregation for the developer dashboard. Replaces the previous
-- approach (pull whole tables into the Next.js server, aggregate in JS) which
-- got slow and pulled tens of thousands of rows per page view.
--
-- One SECURITY DEFINER function returns the entire dashboard payload as jsonb in
-- a single round-trip; the database does the counting. service_role only.
--
-- Reversible: DROP the functions. No table/RLS changes. See the dashboard
-- rewrite (2026-06-07).
-- ============================================================================

-- Global aggregate snapshot. All counts/series computed in-DB.
CREATE OR REPLACE FUNCTION public.admin_dashboard()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
WITH
-- ── activity windows (real duels = comparisons rows) ───────────────────────
duel_users AS (
    SELECT user_id, created_at FROM comparisons
),
rating_users AS (
    SELECT user_id, updated_at FROM ratings
),
-- ── per-user rating counts (for "empty library" + averages) ────────────────
ratings_per_user AS (
    SELECT user_id, count(*) AS n FROM ratings GROUP BY user_id
)
SELECT jsonb_build_object(
    -- users / growth
    'totalUsers',        (SELECT count(*) FROM profiles),
    'new24h',            (SELECT count(*) FROM profiles WHERE created_at >= now() - interval '1 day'),
    'new7d',             (SELECT count(*) FROM profiles WHERE created_at >= now() - interval '7 days'),
    'new30d',            (SELECT count(*) FROM profiles WHERE created_at >= now() - interval '30 days'),
    'publicProfiles',    (SELECT count(*) FROM profiles WHERE is_public),
    'lastfmConnected',   (SELECT count(*) FROM profiles WHERE lastfm_username IS NOT NULL AND length(trim(lastfm_username)) > 0),
    'emptyLibraryUsers', (SELECT count(*) FROM profiles p WHERE NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id = p.id)),
    'deletionPending',   (SELECT count(*) FROM deletion_requests),

    -- engagement
    'totalRatings',  (SELECT count(*) FROM ratings),
    'totalDuels',    (SELECT count(*) FROM comparisons),
    'totalReviews',  (SELECT count(*) FROM reviews),
    'totalItems',    (SELECT count(*) FROM items),

    -- active users (distinct, by real duels)
    'dau', (SELECT count(DISTINCT user_id) FROM duel_users WHERE created_at >= now() - interval '1 day'),
    'wau', (SELECT count(DISTINCT user_id) FROM duel_users WHERE created_at >= now() - interval '7 days'),
    'mau', (SELECT count(DISTINCT user_id) FROM duel_users WHERE created_at >= now() - interval '30 days'),
    'duels7d',   (SELECT count(*) FROM comparisons WHERE created_at >= now() - interval '7 days'),
    'ratings7d', (SELECT count(*) FROM rating_users WHERE updated_at >= now() - interval '7 days'),

    -- activation / retention (approximate)
    --   activation = share of users who have rated at least one item
    --   retention  = of users ≥7d old, share active (duel) in the last 7d
    'activatedUsers', (SELECT count(*) FROM ratings_per_user),
    'retain7d', (
        SELECT count(DISTINCT d.user_id)
        FROM comparisons d
        JOIN profiles p ON p.id = d.user_id
        WHERE p.created_at < now() - interval '7 days'
          AND d.created_at >= now() - interval '7 days'
    ),
    'eligibleRetain', (SELECT count(*) FROM profiles WHERE created_at < now() - interval '7 days'),

    -- charts: daily signups (30d)
    'signupsDaily', (
        SELECT coalesce(jsonb_agg(jsonb_build_object('label', to_char(g.d, 'DD'), 'value', coalesce(c.n, 0)) ORDER BY g.d), '[]'::jsonb)
        FROM generate_series((now() - interval '29 days')::date, now()::date, interval '1 day') AS g(d)
        LEFT JOIN (SELECT created_at::date AS d, count(*) AS n FROM profiles GROUP BY 1) c ON c.d = g.d
    ),
    -- charts: daily duels (30d) — real activity
    'duelsDaily', (
        SELECT coalesce(jsonb_agg(jsonb_build_object('label', to_char(g.d, 'DD'), 'value', coalesce(c.n, 0)) ORDER BY g.d), '[]'::jsonb)
        FROM generate_series((now() - interval '29 days')::date, now()::date, interval '1 day') AS g(d)
        LEFT JOIN (SELECT created_at::date AS d, count(*) AS n FROM comparisons GROUP BY 1) c ON c.d = g.d
    ),
    -- charts: score distribution (0–9 buckets)
    'scoreDist', (
        SELECT coalesce(jsonb_agg(jsonb_build_object('label', s.b::text, 'value', coalesce(c.n, 0)) ORDER BY s.b), '[]'::jsonb)
        FROM generate_series(0, 9) AS s(b)
        LEFT JOIN (SELECT least(9, greatest(0, floor(score)::int)) AS b, count(*) AS n FROM ratings GROUP BY 1) c ON c.b = s.b
    ),
    -- charts: items by kind
    'itemsByKind', (
        SELECT coalesce(jsonb_agg(jsonb_build_object('label', k, 'value', coalesce(c.n, 0)) ORDER BY k), '[]'::jsonb)
        FROM (VALUES ('track'), ('album'), ('artist')) AS kinds(k)
        LEFT JOIN (SELECT kind, count(*) AS n FROM items GROUP BY kind) c ON c.kind = kinds.k
    ),

    -- global top items (most-rated across all users)
    'topItems', (
        SELECT coalesce(jsonb_agg(t), '[]'::jsonb) FROM (
            SELECT i.title, i.primary_artist AS artist, i.kind,
                   count(*) AS "ratingCount",
                   round(avg(r.score)::numeric, 2) AS "avgScore"
            FROM ratings r JOIN items i ON i.id = r.item_id
            GROUP BY i.id, i.title, i.primary_artist, i.kind
            ORDER BY count(*) DESC, avg(r.score) DESC
            LIMIT 15
        ) t
    ),

    -- recent signups feed
    'recentSignups', (
        SELECT coalesce(jsonb_agg(s), '[]'::jsonb) FROM (
            SELECT id, handle, display_name, created_at, is_public
            FROM profiles ORDER BY created_at DESC LIMIT 10
        ) s
    ),

    'generatedAt', now()
);
$$;

-- Per-user table (id, handle, rating count) for the user list. Single grouped
-- query instead of pulling every rating row.
CREATE OR REPLACE FUNCTION public.admin_user_list()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT coalesce(jsonb_agg(u ORDER BY u."created_at" DESC), '[]'::jsonb) FROM (
        SELECT p.id, p.handle, p.display_name, p.created_at, p.is_public,
               (p.lastfm_username IS NOT NULL AND length(trim(p.lastfm_username)) > 0) AS "lastfmConnected",
               coalesce(rc.n, 0) AS "ratingCount"
        FROM profiles p
        LEFT JOIN (SELECT user_id, count(*) AS n FROM ratings GROUP BY user_id) rc ON rc.user_id = p.id
    ) u;
$$;

REVOKE ALL ON FUNCTION public.admin_dashboard() FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_user_list() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_dashboard() TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_user_list() TO service_role;
