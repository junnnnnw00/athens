-- ============================================================================
-- Sync the per-user duel log (comparisons) across devices.
--
-- Until now `recordComparison` wrote comparison rows to local Drift only and
-- never to Supabase, so a fresh device saw the synced `ratings.comparisons`
-- counter but had no underlying events — breaking the per-item "내 Elo 변화"
-- trend (point count << duel count). We now push/pull the log.
--
-- `client_id` carries the device-local comparison id so push (upsert) and pull
-- are idempotent and backfill-safe. Nullable + unique; existing rows (none in
-- prod) stay valid. RLS unchanged (owner-only, from 0001). Reversible: drop the
-- column + index.
-- ============================================================================

ALTER TABLE public.comparisons
    ADD COLUMN IF NOT EXISTS client_id text;

CREATE UNIQUE INDEX IF NOT EXISTS comparisons_client_id_key
    ON public.comparisons (client_id)
    WHERE client_id IS NOT NULL;
