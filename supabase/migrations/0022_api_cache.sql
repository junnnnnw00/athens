-- ============================================================================
-- 0022_api_cache.sql
-- Server-side read-through cache + global token-bucket limiter for the two
-- shared-key upstream proxies (lastfm-proxy, musicbrainz-proxy).
--
-- Why: catalog search is iTunes called per-user-IP (no shared bottleneck) and
-- the Spotify path is dead code, so the only shared-key upstreams are Last.fm
-- (~5 req/s on one key) and MusicBrainz (hard 1 req/s on one User-Agent). The
-- cache collapses repeat lookups of popular catalog to ~0 upstream calls; the
-- token bucket serialises residual misses so bursts spread over time at a safe
-- rate instead of bursting into 429s / bans.
--
-- Reversible: DROP the two tables + three functions; revert the edge functions
-- to direct pass-through. No changes to existing tables. See DECISIONS.md
-- "api_cache table" (2026-06-06).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Cache. Only the edge functions (service role, which bypasses RLS) touch
--    it; RLS ON with zero policies denies anon/authenticated.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.api_cache (
    cache_key text PRIMARY KEY,
    payload jsonb NOT NULL,
    fetched_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.api_cache ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 2. Token buckets, one row per upstream. Last.fm held at 4/s (ToS ~5/s),
--    MusicBrainz at its hard 1/s with a small burst.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.api_rate (
    bucket text PRIMARY KEY,
    tokens double precision NOT NULL,
    rate_per_sec double precision NOT NULL,
    burst double precision NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.api_rate ENABLE ROW LEVEL SECURITY;

INSERT INTO public.api_rate (bucket, tokens, rate_per_sec, burst) VALUES
('lastfm', 8, 4, 8),
('musicbrainz', 2, 1, 2)
ON CONFLICT (bucket) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Functions. SECURITY DEFINER, callable only by the service_role used by the
--    edge functions (anon/authenticated must not drain the bucket or read cache).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.api_cache_get(p_key text, p_max_age interval)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT payload
    FROM public.api_cache
    WHERE cache_key = p_key
      AND now() - fetched_at < p_max_age;
$$;

CREATE OR REPLACE FUNCTION public.api_cache_put(p_key text, p_payload jsonb)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    INSERT INTO public.api_cache (cache_key, payload, fetched_at)
    VALUES (p_key, p_payload, now())
    ON CONFLICT (cache_key) DO UPDATE
        SET payload = excluded.payload,
            fetched_at = now();
$$;

-- Atomic, sleep-free token take. Locks only the single bucket row for the
-- accounting UPDATE (no pg_sleep → no DB connection parked), so concurrent
-- takers serialise briefly without exhausting the pool. Returns TRUE if a token
-- was granted; the caller backs off + retries in its own isolate to drain the
-- queue at rate_per_sec.
CREATE OR REPLACE FUNCTION public.api_rate_take(p_bucket text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    r         public.api_rate%ROWTYPE;
    elapsed   double precision;
    newtokens double precision;
BEGIN
    SELECT * INTO r FROM public.api_rate WHERE bucket = p_bucket FOR UPDATE;
    IF NOT FOUND THEN
        RETURN true;
    END IF;

    elapsed := extract(epoch FROM (now() - r.updated_at));
    newtokens := least(r.burst, r.tokens + elapsed * r.rate_per_sec);

    IF newtokens >= 1 THEN
        UPDATE public.api_rate
            SET tokens = newtokens - 1, updated_at = now()
            WHERE bucket = p_bucket;
        RETURN true;
    ELSE
        UPDATE public.api_rate
            SET tokens = newtokens, updated_at = now()
            WHERE bucket = p_bucket;
        RETURN false;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.api_cache_get(text, interval) FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.api_cache_put(text, jsonb) FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.api_rate_take(text) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.api_cache_get(text, interval) TO service_role;
GRANT EXECUTE ON FUNCTION public.api_cache_put(text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.api_rate_take(text) TO service_role;
