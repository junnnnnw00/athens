// supabase/functions/verify-play-purchase/index.ts
//
// Verifies a Google Play purchase token server-side and sets is_premium=true
// in the `profiles` table for the authenticated user.
//
// Required secrets (set via `supabase secrets set`):
//   GOOGLE_PLAY_PACKAGE_NAME   — e.g. com.example.athens
//   GOOGLE_SERVICE_ACCOUNT_JSON — full JSON of the service account key

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const PACKAGE_NAME =
  Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME') ?? '';
const SERVICE_ACCOUNT_JSON =
  Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON') ?? '';

// ── Google OAuth2 helpers ──────────────────────────────────────────────────

async function getGoogleAccessToken(): Promise<string> {
  const sa = JSON.parse(SERVICE_ACCOUNT_JSON);

  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = btoa(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );

  const signingInput = `${header}.${payload}`;

  // Import the RSA private key.
  const keyData = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '');

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${btoa(
    String.fromCharCode(...new Uint8Array(signature)),
  )}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get Google access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

// ── Main handler ────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    // ① Auth: require a valid user session.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const anonClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: userError,
    } = await anonClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
      });
    }

    // ② Parse body.
    const { purchaseToken, productId } = await req.json();
    if (!purchaseToken || !productId) {
      return new Response(
        JSON.stringify({ error: 'purchaseToken and productId are required' }),
        { status: 400 },
      );
    }

    // ③ Verify with Google Play Developer API.
    const accessToken = await getGoogleAccessToken();

    const playUrl =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${PACKAGE_NAME}/purchases/products/${productId}/tokens/${purchaseToken}`;

    const playRes = await fetch(playUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!playRes.ok) {
      const body = await playRes.text();
      console.error('Play API error:', playRes.status, body);
      return new Response(
        JSON.stringify({ error: 'Purchase verification failed', detail: body }),
        { status: 400 },
      );
    }

    const playData = await playRes.json();

    // purchaseState: 0 = Purchased, 1 = Cancelled, 2 = Pending
    if (playData.purchaseState !== 0) {
      return new Response(
        JSON.stringify({ error: 'Purchase not in purchased state', state: playData.purchaseState }),
        { status: 400 },
      );
    }

    // ④ Grant premium in database (using service role to bypass RLS).
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        is_premium: true,
        // Store the token for future reference / refund detection.
        play_purchase_token: purchaseToken,
      })
      .eq('id', user.id);

    if (updateError) {
      console.error('DB update error:', updateError);
      return new Response(
        JSON.stringify({ error: 'Failed to grant premium', detail: updateError.message }),
        { status: 500 },
      );
    }

    console.log(`Premium granted to user ${user.id} via Play purchase.`);

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('verify-play-purchase error:', err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
