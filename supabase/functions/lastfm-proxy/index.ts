import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { withCache } from "../_shared/cache.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const BASE_URL = "https://ws.audioscrobbler.com/2.0/";

// Read methods the app actually uses. The anon key ships in the client (public)
// and the function is deployed --no-verify-jwt, so without this the proxy is an
// open relay anyone could use to burn the shared LASTFM_API_KEY quota.
const ALLOWED_METHODS = new Set([
  "track.getTopTags",
  "artist.getTopTags",
  "track.getInfo",
  "artist.getInfo",
  "artist.getTopTracks",
  "user.getRecentTracks",
  "tag.getTopTracks",
]);

// Cache TTL per method. Almost everything Last.fm returns here is effectively
// static, so 90 days. Recent plays are time-sensitive → short TTL (still
// collapses rapid home re-fetches without freezing the list).
function maxAgeFor(method: string): string {
  return method === "user.getRecentTracks" ? "90 seconds" : "90 days";
}

// Stable cache key from the request params (sorted), minus volatile/irrelevant
// keys. api_key + format are added server-side and never part of the key.
function cacheKeyFor(params: URLSearchParams): string {
  const entries: [string, string][] = [];
  for (const [k, v] of params.entries()) {
    if (k === "api_key" || k === "format") continue;
    entries.push([k, v]);
  }
  entries.sort((a, b) => (a[0] === b[0] ? a[1].localeCompare(b[1]) : a[0].localeCompare(b[0])));
  return "lastfm:" + entries.map(([k, v]) => `${k}=${v}`).join("&");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const apiKey = Deno.env.get("LASTFM_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Last.fm API key not configured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const url = new URL(req.url);
  const method = url.searchParams.get("method");

  if (!method) {
    return new Response(
      JSON.stringify({ error: "Missing 'method' parameter" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (!ALLOWED_METHODS.has(method)) {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const key = cacheKeyFor(url.searchParams);

  const { data } = await withCache({
    key,
    maxAge: maxAgeFor(method),
    bucket: "lastfm",
    upstream: async () => {
      const lfmUrl = new URL(BASE_URL);
      for (const [k, v] of url.searchParams.entries()) {
        lfmUrl.searchParams.set(k, v);
      }
      lfmUrl.searchParams.set("api_key", apiKey);
      lfmUrl.searchParams.set("format", "json");
      if (!lfmUrl.searchParams.has("limit")) lfmUrl.searchParams.set("limit", "10");
      if (!lfmUrl.searchParams.has("autocorrect")) lfmUrl.searchParams.set("autocorrect", "1");

      const response = await fetch(lfmUrl.toString(), {
        headers: { "User-Agent": "Athens/0.1" },
      });
      const body = response.ok ? await response.json() : null;
      return { ok: response.ok, data: body ?? {} };
    },
  });

  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
