# Athens — Tag Pipeline (Genre + Mood)

## Overview

Athens enriches catalog items with deep genre and mood tags sourced from:
1. **Last.fm** — crowd-sourced tags (primary source, very descriptive)
2. **MusicBrainz** — structured genre taxonomy (secondary, rate-limited)

These tags approximate the RYM (RateYourMusic) genre/descriptor experience — terms like "shoegaze", "dreamy", "melancholic", "post-punk" — sourced legally via public APIs.

**DO NOT scrape RateYourMusic.** RYM has no public API and explicitly forbids scraping.

## Last.fm Tags

### Endpoints Used

- `track.getTopTags` — top crowd tags for a specific track
- `artist.getTopTags` — top crowd tags for an artist

### Tag Quality

Last.fm tags are crowd-sourced and highly descriptive:
- Genre: `shoegaze`, `indie rock`, `post-punk`, `dreampop`, `jazz`
- Mood: `melancholic`, `dreamy`, `energetic`, `calm`, `dark`
- Era: `90s`, `80s`, `2000s`
- Format: `ep`, `live`

We take the top 10 tags by count, filter noise (tags with count < 10), and store them.

### Rate Limiting

Last.fm allows ~5 requests/second with an API key. We proxy through the `lastfm-proxy` edge function to keep the API key server-side.

### API Key Setup

1. Create account at https://www.last.fm/api/account/create
2. Note your API key
3. Set as edge function secret: `supabase secrets set LASTFM_API_KEY=...`

## MusicBrainz Tags

### Endpoints Used

- `https://musicbrainz.org/ws/2/recording/{mbid}?inc=tags&fmt=json`
- `https://musicbrainz.org/ws/2/artist/{mbid}?inc=tags&fmt=json`

### Rate Limiting

**Maximum 1 request per second** — enforced in code. MusicBrainz will IP-ban clients that exceed this.

Required User-Agent: `AppName/Version ( contact@email.com )` — set via `MUSICBRAINZ_USER_AGENT` env var.

### MusicBrainz ID Lookup

To enrich with MusicBrainz, we first need a MBID. We look it up via:
```
https://musicbrainz.org/ws/2/recording/?query=artist:{artist}+recording:{title}&fmt=json
```

This search is also rate-limited (1 req/sec).

## Tag Storage

Tags are stored in `items.tags` as a JSONB array:

```json
{
  "tags": [
    {"name": "shoegaze", "source": "lastfm", "count": 100},
    {"name": "dreampop", "source": "lastfm", "count": 85},
    {"name": "indie rock", "source": "musicbrainz", "count": null},
    {"name": "melancholic", "source": "lastfm", "count": 60}
  ]
}
```

## Tag Freshness

Tags are considered stale after 7 days. On stale items, the enrichment pipeline re-runs on next access. This balances API rate limits with tag freshness.

## Tag Categories

Tags are displayed in two categories in the UI:

| Category | Examples |
|----------|---------|
| **Genre** | shoegaze, post-punk, jazz fusion, dreampop, ambient |
| **Mood** | melancholic, energetic, dreamy, dark, uplifting |

We use a keyword list to classify tags into genre vs. mood. Unknown tags default to genre.

## Stats Integration

`StatsEngine` uses `items.tags` to compute:
- Top genres across your library
- Top moods across your library
- Genre/mood breakdown by score range (e.g., your top-rated genres)

These are displayed as bar charts on the StatsScreen.
