"use client";

import { useCallback, useEffect, useRef, useState } from "react";

type Song = { title: string; artist: string; cover: string };

// Real album art fetched from iTunes (the app's own fallback source) into
// /public/landing/covers. The deck cycles so the demo never runs out.
const DECK: Song[] = [
  { title: "Idioteque", artist: "Radiohead", cover: "/landing/covers/idioteque.jpg" },
  { title: "Space Song", artist: "Beach House", cover: "/landing/covers/spacesong.jpg" },
  { title: "Just", artist: "Radiohead", cover: "/landing/covers/just.jpg" },
  { title: "Sugar for the Pill", artist: "Slowdive", cover: "/landing/covers/sugar.jpg" },
  { title: "The Less I Know the Better", artist: "Tame Impala", cover: "/landing/covers/lessiknow.jpg" },
  { title: "The Spirit of Radio", artist: "Rush", cover: "/landing/covers/spiritradio.jpg" },
  { title: "Reptilia", artist: "The Strokes", cover: "/landing/covers/reptilia.jpg" },
  { title: "Innuendo", artist: "Queen", cover: "/landing/covers/innuendo.jpg" },
];

type Nudge = { text: string; kind: "win" | "loss" } | null;

export default function DuelDemo() {
  const [deckPos, setDeckPos] = useState(0);
  const [picked, setPicked] = useState<0 | 1 | null>(null);
  const [nudge, setNudge] = useState<Nudge>(null);
  // Per-song streak: positive = win streak, negative = loss streak (mirrors
  // LibraryRepository.getItemStreak in the app).
  const streaks = useRef<Record<string, number>>({});
  const advance = useRef<ReturnType<typeof setTimeout> | null>(null);
  const hide = useRef<ReturnType<typeof setTimeout> | null>(null);

  const left = DECK[deckPos % DECK.length];
  const right = DECK[(deckPos + 1) % DECK.length];

  useEffect(() => () => {
    if (advance.current) clearTimeout(advance.current);
    if (hide.current) clearTimeout(hide.current);
  }, []);

  const pick = useCallback((side: 0 | 1) => {
    if (picked !== null) return;
    setPicked(side);

    const winner = side === 0 ? left : right;
    const loser = side === 0 ? right : left;
    const ws = streaks.current[winner.title] > 0 ? streaks.current[winner.title] + 1 : 1;
    const ls = streaks.current[loser.title] < 0 ? streaks.current[loser.title] - 1 : -1;
    streaks.current[winner.title] = ws;
    streaks.current[loser.title] = ls;

    // Match the app: settle the pick, then surface a streak nudge for 2s.
    advance.current = setTimeout(() => {
      setDeckPos((p) => p + 2);
      setPicked(null);
      let next: Nudge = null;
      if (ws >= 2) next = { text: `🔥 ${winner.title} ${ws}연승!`, kind: "win" };
      else if (ls <= -2) next = { text: `💀 ${loser.title} ${-ls}연패...`, kind: "loss" };
      if (next) {
        setNudge(next);
        if (hide.current) clearTimeout(hide.current);
        hide.current = setTimeout(() => setNudge(null), 2000);
      }
    }, 450);
  }, [picked, left, right]);

  return (
    <div className="dd">
      {/* streak nudge — transient, per-song, like the app */}
      <div className="dd-nudge-zone">
        {nudge && (
          <span className={`dd-nudge dd-nudge-${nudge.kind}`}>{nudge.text}</span>
        )}
      </div>

      <div className="dd-cards">
        {[left, right].map((song, i) => {
          const side = i as 0 | 1;
          const isPicked = picked === side;
          const isDimmed = picked !== null && picked !== side;
          return (
            <button
              key={`${deckPos}-${i}`}
              type="button"
              onClick={() => pick(side)}
              className={`dd-card${isPicked ? " is-picked" : ""}${isDimmed ? " is-dimmed" : ""}`}
              style={{ backgroundImage: `url(${song.cover})` }}
              aria-label={`${song.title} — ${song.artist} 선택`}
            >
              <span className="dd-scrim" />
              {isPicked && <span className="dd-check">✓</span>}
              <span className="dd-meta">
                <span className="dd-title">{song.title}</span>
                <span className="dd-artist">{song.artist}</span>
              </span>
            </button>
          );
        })}
      </div>

      <div className="dd-foot">
        <span className="dd-q">어느 곡이 더 좋아요?</span>
        <span className="dd-hint">탭해서 골라보세요 →</span>
      </div>
    </div>
  );
}
