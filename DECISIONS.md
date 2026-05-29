# Crate — Architecture Decisions

## Tech Stack

| Decision | Choice | Reason |
|----------|--------|--------|
| Flutter state | Riverpod | Locked in PROMPT.md |
| Routing | go_router | Locked in PROMPT.md |
| Local cache | Drift (SQLite) | Locked in PROMPT.md |
| Charts | fl_chart | Locked in PROMPT.md |
| Share image | screenshot + share_plus | Locked in PROMPT.md |
| Spotify auth | PKCE, no client secret in app | Security — secret handled by edge function |
| Mood/energy data | Last.fm tags only | Spotify removed audio-features for new apps |
| RYM-style tags | Last.fm crowd tags + MusicBrainz genres | RYM has no public API and forbids scraping |

## API Design

### Spotify Client Credentials
The Spotify app token (Client Credentials) is fetched server-side via a Supabase Edge Function
(`spotify-app-token`). The client never holds `SPOTIFY_CLIENT_SECRET`. The client calls the edge
function which returns a short-lived token for catalog search.

### Tag Pipeline
1. Search item via Spotify (app token) or iTunes fallback
2. Enrich with Last.fm `track.getTopTags` + `artist.getTopTags` (top 10 tags each)
3. Augment with MusicBrainz genres (rate-limited to 1 req/sec)
4. Store merged tag array in `items.tags` (jsonb)
5. Tags are cached — only re-fetch if stale (>7 days)

### Elo Score Mapping
`scoreFromElo(elo)` uses a logistic function: `10 / (1 + exp(-(elo - 1000) / 200))`
- elo 1000 → 5.0 (midpoint)
- elo 1400 → ~9.0
- elo 600 → ~1.0

## Package Substitutions
None yet — all specified packages verified available on pub.dev.
