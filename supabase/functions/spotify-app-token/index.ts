import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Module-scope token cache. Edge function instances are reused across requests
// (warm starts), so caching the Client-Credentials token here avoids minting a
// fresh one on every search — which was rapidly exhausting Spotify's app-level
// rate limit and 429ing catalog search. Spotify tokens last 3600s; we refresh
// 60s early to absorb clock skew.
let cachedToken: string | null = null;
let cachedTokenType = "Bearer";
let tokenExpiresAt = 0; // epoch ms

async function getToken(clientId: string, clientSecret: string): Promise<{
  access_token: string;
  token_type: string;
  expires_in: number;
}> {
  const now = Date.now();
  if (cachedToken && now < tokenExpiresAt) {
    return {
      access_token: cachedToken,
      token_type: cachedTokenType,
      expires_in: Math.max(1, Math.floor((tokenExpiresAt - now) / 1000)),
    };
  }

  const credentials = btoa(`${clientId}:${clientSecret}`);
  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Spotify token fetch failed: ${response.status} ${detail}`);
  }

  const data = await response.json();
  cachedToken = data.access_token;
  cachedTokenType = data.token_type ?? "Bearer";
  tokenExpiresAt = Date.now() + Math.max(0, (data.expires_in ?? 3600) - 60) * 1000;
  return data;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const clientId = Deno.env.get("SPOTIFY_CLIENT_ID");
  const clientSecret = Deno.env.get("SPOTIFY_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    return new Response(
      JSON.stringify({ error: "Spotify credentials not configured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  let data;
  try {
    data = await getToken(clientId, clientSecret);
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Spotify token fetch failed", detail: String(err) }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({
      access_token: data.access_token,
      expires_in: data.expires_in,
      token_type: data.token_type,
    }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
