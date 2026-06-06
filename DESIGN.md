# DESIGN.md — Visual design language (replaces ACCEPTANCE.md Part C)

> Reference: the real Podiums app. The aesthetic is **refined minimalism** — clean, high-contrast,
> spacious, modern. NOT editorial/zine, NOT moody, NOT decorative. The album art carries all the
> color; the UI chrome stays neutral and quiet. The companion prototype `docs/internal/Athens-prototype.jsx`
> embodies this — match its feel. If anything here conflicts with a "make it expressive" instinct,
> restraint wins.

## North star
Quiet, confident, content-first. Most of the screen is neutral (black or warm grey) and white
space. Color appears in exactly two places: the album artwork, and one mint accent used sparingly
for scores and selected state. A first-time user should read it as "clean and modern", never "busy".

## Modes
Ship BOTH, dark default:
- **Dark:** true black background `#000000`. Surfaces `#141414`/`#1C1C1C`, hairlines `#262626`.
- **Light:** warm grey background `#E9E7E2`. Surfaces `#F5F3EF`/`#FFFFFF`, hairlines `#DAD7D0`.

## Color tokens
| token | dark | light |
| --- | --- | --- |
| bg | `#000000` | `#E9E7E2` |
| surface | `#141414` | `#F5F3EF` |
| surface2 | `#1C1C1C` | `#FFFFFF` |
| line (hairline) | `#262626` | `#DAD7D0` |
| text | `#F2F1EE` | `#171614` |
| muted | `#8C8C8C` | `#6E6B64` |
| faint | `#5A5A5A` | `#A19D94` |
| **accent (mint)** | `#74E0A4` | `#3DBE6E` |
| accent-soft (chip bg) | `#1E3A2C` | `#CFEFD8` |
| accent-text (score) | `#56D08D` | `#2E9E58` |
| match-pill | `#8C8A3E` | `#EADF9E` |

**One accent only — mint/spring green.** No pink, no purple, no blue, no multi-color charts.
Charts use mint + neutral tints. The ONLY thing allowed to be colorful is real album art.

## Typography
- **Display + UI:** **Hanken Grotesk** (clean grotesque with slight warmth; avoids generic Inter feel). Headings are heavy: weight 800, letter-spacing −0.02em, title case. Numbers (scores, stats) also Hanken, bold.
- **Korean:** **Pretendard** (pairs cleanly with Hanken). All Korean UI strings read naturally.
- **Mono accents (optional):** small uppercase labels/tags only.
- Define styles once in a tokens file; never scatter ad-hoc `TextStyle(fontSize: …)`.
- Hierarchy: screen title 32–34/800; card title 16–18/800; body 14–15/500; meta 13/500 muted.

## Signature components

**Score ring (the iconic element).** A circular SVG/painter ring, ~48px, mint stroke filling
proportionally to score/10 over a hairline track, with the score (e.g. `9.8`) centered in mint,
Hanken bold. Used on every ranked row and review card. This is the single most recognizable element
— get it right and consistent.

**Ranked library row.** `[rank #] [56px cover, 10px radius] [title 800 / "Kind · Year" meta muted] [score ring, right-aligned]`. Hairline divider between rows. Crown glyph on #1 only.

**The duel ("Which did you like more?").** Two square-ish cards side by side. Each card uses the
item's album art as a **blurred, scaled, scrimmed background** with the title (800) + artist (muted)
in the lower-left over the scrim — frosted-glass feel. Tap → chosen card lifts (translateY −4px) and
gets a mint border; the other dims to ~0.4 opacity. Below: `Undo • Too tough` in muted text.
Can be presented full-screen (Rate tab) or as a bottom sheet over a list.

**Filter chips.** Pill, horizontally scrollable. Default = neutral chip bg + muted text + hairline
border. Selected = mint-soft bg + mint text + bold, no border. (See "Rock"/"All" in the reference.)

**Floating bottom nav.** A single rounded pill (radius ~34) floating ~18px above the bottom,
translucent with `backdrop-filter: blur(20px)` and a hairline border. Three items:
`Home` · center `Add` (solid square, bg = text color, radius ~12, plus icon in bg color) · `Me`.
Active item = full-contrast text; inactive = faint. Labels 11px/600.

**Collection cards (profile).** Title + a fan of stacked album thumbnails with rounded corners and a
`+N` overflow badge on the last tile. Neutral card surface.

**Match pill / stats.** Big bold numbers with small muted labels underneath (reviews / followers /
following). Match % as a soft pill (olive on dark, soft yellow on light) with dark text.

## Layout & spacing
- 8px spacing scale. Generous outer padding (~20px). Let rows breathe.
- Radii: covers 10px, cards 18px, chips/buttons 20px (pill), nav 34px.
- Hairline borders (1px at token `line`), not heavy shadows. Subtle elevation only.
- Content-first: minimal chrome, no gradients-for-decoration, no glow effects, no noise textures.

## Motion (subtle)
- Screen/list entrance: gentle fade + 8px rise.
- Tap feedback on every control (scale ~0.97).
- Score ring animates its fill on mount/update (~0.5s ease-out).
- Duel pick: 0.45s lift/dim transition. Nothing flashy beyond this.

## Hard "don'ts" (these produced the bad first build)
- ❌ Default Material blue/purple/teal anywhere. Every default color overridden.
- ❌ Unstyled default `ElevatedButton`/`Card`/`BottomNavigationBar`.
- ❌ Serif display type, zine/editorial styling, heavy gradients, decorative accents.
- ❌ More than one accent color; colorful multi-series charts.
- ❌ Rainbow/gradient placeholder tiles for missing art — use a quiet neutral tile with small initials.

## Verification (augments ACCEPTANCE Part D/E)
- A central theme/tokens file exists; a test asserts scaffold/primary colors equal tokens, not Material defaults.
- Golden tests render Home/Duel/Library/Item-detail/Stats/IG-card in BOTH light and dark from seeded data; commit the PNGs to `test/golden/` for morning review.
- Manual 30-second check: open each screen — is it black/warm-grey + neutral chrome + mint-only accent + album-art color, with score rings present and a floating pill nav? If any screen looks like stock Material, it fails.
