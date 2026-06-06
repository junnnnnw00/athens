import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { withCache } from "../_shared/cache.ts";

// MusicBrainz blocks browser requests (no CORS headers). This proxy forwards the
// query server-side with a proper User-Agent and returns JSON the web app can read.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const BASE_URL = "https://musicbrainz.org/ws/2/";
const USER_AGENT = "Athens/0.1 ( https://github.com/junnnnnw00/athens )";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const entity = url.searchParams.get("entity") ?? "recording";
  const query = url.searchParams.get("query") ?? "";
  // Clamp limit to a small range — the app only ever needs the top hit, and an
  // unbounded limit would let a caller pull huge result sets per request.
  const rawLimit = parseInt(url.searchParams.get("limit") ?? "1", 10);
  const limit = String(Number.isFinite(rawLimit) ? Math.min(Math.max(rawLimit, 1), 25) : 1);

  if (!query) {
    return new Response(JSON.stringify({ error: "Missing 'query' parameter" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // The app only searches recordings. Allowlist that entity so the proxy can't
  // be repurposed for arbitrary MusicBrainz endpoints on the shared User-Agent.
  const ALLOWED_ENTITIES = new Set(["recording"]);
  if (!ALLOWED_ENTITIES.has(entity)) {
    return new Response(JSON.stringify({ error: "Entity not allowed" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Recording genres/year are static → long TTL. The token bucket (hard 1 req/s
  // on the shared User-Agent) serialises cache misses so bursts never trip a ban.
  const key = `mb:${entity}:limit=${limit}:${query}`;

  const { data } = await withCache({
    key,
    maxAge: "90 days",
    bucket: "musicbrainz",
    upstream: async () => {
      const mbUrl = new URL(`${BASE_URL}${entity}`);
      mbUrl.searchParams.set("query", query);
      mbUrl.searchParams.set("fmt", "json");
      mbUrl.searchParams.set("limit", limit);
      const response = await fetch(mbUrl.toString(), {
        headers: { "User-Agent": USER_AGENT },
      });
      const body = response.ok ? await response.json() : null;
      return { ok: response.ok, data: body ?? {} };
    },
  });

  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
