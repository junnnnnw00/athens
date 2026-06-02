import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const BASE_URL = "https://ws.audioscrobbler.com/2.0/";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const apiKey = Deno.env.get("LASTFM_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Last.fm API key not configured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const url = new URL(req.url);
  const method = url.searchParams.get("method");

  if (!method) {
    return new Response(
      JSON.stringify({ error: "Missing 'method' parameter" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const lfmUrl = new URL(BASE_URL);
  for (const [key, value] of url.searchParams.entries()) {
    lfmUrl.searchParams.set(key, value);
  }
  lfmUrl.searchParams.set("api_key", apiKey);
  lfmUrl.searchParams.set("format", "json");
  if (!lfmUrl.searchParams.has("limit")) {
    lfmUrl.searchParams.set("limit", "10");
  }
  if (!lfmUrl.searchParams.has("autocorrect")) {
    lfmUrl.searchParams.set("autocorrect", "1");
  }

  const response = await fetch(lfmUrl.toString(), {
    headers: { "User-Agent": "Athens/0.1" },
  });

  if (!response.ok) {
    return new Response(
      JSON.stringify({ error: "Last.fm API error", status: response.status }),
      { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const data = await response.json();
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
