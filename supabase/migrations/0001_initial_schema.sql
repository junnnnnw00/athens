-- Enable required extensions
-- (uuid generation uses the built-in gen_random_uuid(); no uuid-ossp needed)
CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================================================
-- profiles
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    handle citext UNIQUE NOT NULL,
    display_name text,
    avatar_url text,
    bio text,
    is_public boolean NOT NULL DEFAULT false,
    spotify_enabled boolean NOT NULL DEFAULT false,
    spotify_user_id text,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select
ON profiles FOR SELECT
USING (is_public = true OR auth.uid() = id);

CREATE POLICY profiles_insert
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_update
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Auto-create a profile row when a user signs up.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, handle, display_name)
  VALUES (
    NEW.id,
    LOWER(REPLACE(SPLIT_PART(NEW.email, '@', 1), '.', '_')),
    SPLIT_PART(NEW.email, '@', 1)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- items  (shared catalog cache)
-- ============================================================================
CREATE TABLE IF NOT EXISTS items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kind text NOT NULL CHECK (kind IN ('track', 'album', 'artist')),
    source text NOT NULL,   -- 'spotify', 'itunes', 'musicbrainz'
    source_id text NOT NULL,
    title text NOT NULL,
    primary_artist text,
    image_url text,
    tags jsonb NOT NULL DEFAULT '[]'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (source, source_id)
);

ALTER TABLE items ENABLE ROW LEVEL SECURITY;

CREATE POLICY items_select
ON items FOR SELECT
TO authenticated
USING (true);

CREATE POLICY items_insert
ON items FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY items_update
ON items FOR UPDATE
TO authenticated
USING (true);

-- ============================================================================
-- ratings
-- ============================================================================
CREATE TABLE IF NOT EXISTS ratings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    item_id uuid NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    elo numeric NOT NULL DEFAULT 1000,
    comparisons int NOT NULL DEFAULT 0,
    score numeric GENERATED ALWAYS AS (
        10.0 / (1.0 + exp(-(elo - 1000.0) / 200.0))
    ) STORED,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, item_id)
);

ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY ratings_select
ON ratings FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY ratings_insert
ON ratings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY ratings_update
ON ratings FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY ratings_delete
ON ratings FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- comparisons
-- ============================================================================
CREATE TABLE IF NOT EXISTS comparisons (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    winner_item_id uuid NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    loser_item_id uuid NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE comparisons ENABLE ROW LEVEL SECURITY;

CREATE POLICY comparisons_select
ON comparisons FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY comparisons_insert
ON comparisons FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY comparisons_delete
ON comparisons FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- reviews
-- ============================================================================
CREATE TABLE IF NOT EXISTS reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    item_id uuid NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    body text NOT NULL,
    rating_snapshot numeric,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, item_id)
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY reviews_select
ON reviews FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY reviews_insert
ON reviews FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reviews_update
ON reviews FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY reviews_delete
ON reviews FOR DELETE
USING (auth.uid() = user_id);
