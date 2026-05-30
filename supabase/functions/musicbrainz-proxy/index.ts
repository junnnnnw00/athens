import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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
  const limit = url.searchParams.get("limit") ?? "1";

  if (!query) {
    return new Response(JSON.stringify({ error: "Missing 'query' parameter" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const mbUrl = new URL(`${BASE_URL}${entity}`);
  mbUrl.searchParams.set("query", query);
  mbUrl.searchParams.set("fmt", "json");
  mbUrl.searchParams.set("limit", limit);

  const response = await fetch(mbUrl.toString(), {
    headers: { "User-Agent": USER_AGENT },
  });

  if (!response.ok) {
    return new Response(
      JSON.stringify({ error: "MusicBrainz API error", status: response.status }),
      { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const data = await response.json();
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
