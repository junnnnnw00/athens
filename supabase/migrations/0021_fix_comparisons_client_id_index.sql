-- ============================================================================
-- Fix: the partial unique index from 0020 (WHERE client_id IS NOT NULL) can't be
-- used as an ON CONFLICT arbiter by PostgREST upserts — Postgres won't infer a
-- partial index unless the statement repeats its predicate, which PostgREST does
-- not. Replace it with a plain unique index. NULL client_ids are still allowed
-- (NULLs are distinct in a unique index), and every synced row sets client_id.
-- ============================================================================

DROP INDEX IF EXISTS public.comparisons_client_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS comparisons_client_id_key
    ON public.comparisons (client_id);
