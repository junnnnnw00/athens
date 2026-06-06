// Shared read-through cache + global token-bucket limiter for the shared-key
// upstream proxies (lastfm, musicbrainz). Backed by the api_cache / api_rate
// tables + functions from migration 0022. See DECISIONS.md (2026-06-06).
//
// Flow per request:
//   1. cache hit (fresh) → return immediately, no upstream, no token spent.
//   2. miss → take a token from the per-upstream bucket, backing off + retrying
//      in THIS isolate (no DB connection parked) until granted or maxWait.
//   3. granted → call upstream, write cache. On upstream error or a too-deep
//      queue → serve any stale cached value, else an empty object (the client
//      already degrades gracefully on empty/error).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Far-future age used to fetch a stale value regardless of TTL.
const STALE_ANY = "3650 days";

export async function cacheGet(key: string, maxAge: string): Promise<unknown | null> {
  const { data, error } = await supa.rpc("api_cache_get", {
    p_key: key,
    p_max_age: maxAge,
  });
  if (error) return null;
  return data ?? null;
}

export async function cachePut(key: string, payload: unknown): Promise<void> {
  await supa.rpc("api_cache_put", { p_key: key, p_payload: payload });
}

// Acquire one token with bounded, jittered backoff. Returns false if the queue
// is deeper than maxWaitMs (caller then serves stale / empty).
async function rateAcquire(bucket: string, maxWaitMs = 4000): Promise<boolean> {
  const start = Date.now();
  for (;;) {
    const { data, error } = await supa.rpc("api_rate_take", { p_bucket: bucket });
    if (!error && data === true) return true;
    if (Date.now() - start >= maxWaitMs) return false;
    await sleep(150 + Math.floor(Math.random() * 120));
  }
}

export interface WithCacheOpts {
  key: string; // stable cache key
  maxAge: string; // fresh TTL, e.g. "90 days" or "90 seconds"
  bucket: string; // rate bucket name (api_rate.bucket)
  upstream: () => Promise<{ ok: boolean; data: unknown }>;
}

export async function withCache(
  opts: WithCacheOpts,
): Promise<{ data: unknown; status: number }> {
  const fresh = await cacheGet(opts.key, opts.maxAge);
  if (fresh !== null) return { data: fresh, status: 200 };

  const granted = await rateAcquire(opts.bucket);
  if (!granted) {
    const stale = await cacheGet(opts.key, STALE_ANY);
    return { data: stale ?? {}, status: 200 };
  }

  try {
    const res = await opts.upstream();
    if (res.ok) {
      await cachePut(opts.key, res.data);
      return { data: res.data, status: 200 };
    }
    const stale = await cacheGet(opts.key, STALE_ANY);
    return { data: stale ?? res.data, status: 200 };
  } catch (_) {
    const stale = await cacheGet(opts.key, STALE_ANY);
    return { data: stale ?? {}, status: 200 };
  }
}
