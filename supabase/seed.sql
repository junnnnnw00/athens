-- Seed data for development/testing.
-- Run after migrations via: supabase db reset

-- Note: auth.users rows must exist before profiles can be inserted.
-- For local dev, create users via Supabase Auth UI or API, then:
-- UPDATE profiles SET is_public = true, handle = 'demo' WHERE id = '<your-user-id>';

-- Example items (shared catalog cache entries).
INSERT INTO items (kind, source, source_id, title, primary_artist, tags)
VALUES
(
    'track', 'spotify', 'demo-1', 'Only Shallow', 'My Bloody Valentine',
    '[{"name":"shoegaze","source":"lastfm"},{"name":"dreamy","source":"lastfm"},{"name":"noise pop","source":"musicbrainz"}]'
),
(
    'track', 'spotify', 'demo-2', 'Sometimes', 'My Bloody Valentine',
    '[{"name":"shoegaze","source":"lastfm"},{"name":"dreampop","source":"lastfm"}]'
),
(
    'album', 'spotify', 'demo-3', 'Loveless', 'My Bloody Valentine',
    '[{"name":"shoegaze","source":"lastfm"},{"name":"alternative rock","source":"lastfm"}]'
)
ON CONFLICT (source, source_id) DO NOTHING;

-- Seed promo codes for testing
INSERT INTO public.promo_codes (code, is_used)
VALUES
('HEREISYOURCOFFEESIR', false),
('ATHENS_VIP_PASS', false),
('BACKER_LIFETIME_100', false),
('TUMBLBUG_THANK_YOU', false)
ON CONFLICT (code) DO NOTHING;
