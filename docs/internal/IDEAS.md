# IDEAS.md — considered, intentionally NOT built

Improvement ideas weighed during the build but deliberately left out to stay in
scope / preserve restraint. For the morning review. Not bugs, not TODOs.

## Product
- **Rate-streak nudge** — a gentle "3 in a row!" cue on the duel to encourage a
  session. Left out: risks gamifying the calm core loop; revisit with real usage.
- **Filter library by tag/mood** — chips beyond kind (e.g. tap "shoegaze" to filter).
  The data (tags) already supports it; left out to keep the first Library simple.
- **Compare-history view** — a log of past duels with undo-per-comparison. The
  duel currently has skip / too-tough; a full reversible history needs a new repo
  surface (store previous Elos) — deferred as more than a small change.
- **Tag taxonomy grouping** — map crowd tags onto an open genre tree for tidy
  genre vs mood separation (currently a keyword heuristic in StatsEngine).

## UX / polish
- Animated rank changes in the Library after a duel (subtle reorder transition).
- Pull-to-refresh on Home to re-pull recently-played.
- Haptics on duel pick (mobile only).
- Per-item "why this score" explanation from comparison history.

## Platform
- Realtime sync subscription (currently last-write-wins push/pull via SyncService;
  live Realtime channel not wired into the UI yet).
- Light/dark toggle in-app (theme supports both; currently dark-locked at runtime).
- Localized strings via `intl` ARB files (UI is Korean-first hardcoded for now).

## Refactor (cleanup run 2026-06-03)
- **friend_comparison_screen.dart decomposition (~1487 lines, one State class).**
  stats_screen and search_screen were split into `part` files (leaf widgets moved
  out, zero behavior change). friend_comparison can't be `part`-split the same way:
  it's a single giant `State` class, and `part` only splits at top-level
  declarations. Reducing it means extracting tab-content `_buildX()` methods into
  standalone widget classes that take their data as params — a real refactor with
  meaningful regression surface (ref/context/setState coupling, premium gating,
  two TabBarView tabs). Deferred deliberately: do it as its own focused PR with
  golden coverage per extracted widget, not inside the broad cleanup run.

## Why these are parked
Each is either (a) outside PROMPT.md's data sources/constraints, (b) more than a
small self-contained change, or (c) a feature that would add chrome to a loop whose
value is its simplicity. Restraint wins per CLAUDE.md.
