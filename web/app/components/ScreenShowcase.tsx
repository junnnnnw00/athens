"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

type Shot = { src: string; en: string; ko: string; desc: string };

const SHOTS: Shot[] = [
  { src: "/landing/screens/duel.png", en: "Battle Your Music", ko: "1:1 평가",
    desc: "Compare two items side-by-side and tap the one you prefer. That’s all it takes to rate." },
  { src: "/landing/screens/home.png", en: "Anywhere, Anytime", ko: "둘러보기",
    desc: "Get fresh personalized recommendations daily. Rate with a single hand, anytime, anywhere." },
  { src: "/landing/screens/stats.png", en: "Analyze Your Taste", ko: "취향 분석",
    desc: "See your score distribution, averages, and most dueled items at a glance. Your taste in numbers." },
  { src: "/landing/screens/genre.png", en: "Genre & Mood", ko: "장르 · 무드",
    desc: "Deep dive into tags powered by Last.fm and MusicBrainz. From shoegaze to melancholy." },
  { src: "/landing/screens/profile.png", en: "Share Your Profile", ko: "프로필 공유",
    desc: "Showcase your top rankings and album cover wall in a single page. Instantly share via a link." },
];

const INTERVAL = 4500;

export default function ScreenShowcase() {
  const [active, setActive] = useState(0);
  const [paused, setPaused] = useState(false);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (paused) return;
    timer.current = setInterval(() => setActive((a) => (a + 1) % SHOTS.length), INTERVAL);
    return () => { if (timer.current) clearInterval(timer.current); };
  }, [paused]);

  return (
    <div className="ss" onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)}>
      {/* feature list (tabs) */}
      <ul className="ss-list">
        {SHOTS.map((s, i) => {
          const on = i === active;
          return (
            <li key={s.src}>
              <button
                type="button"
                className={`ss-item${on ? " is-active" : ""}`}
                onClick={() => setActive(i)}
              >
                <span className="ss-item-en" style={{ fontSize: "16px", fontWeight: 700 }}>{s.en}</span>
                {on && <span className="ss-item-desc" style={{ marginTop: "6px" }}>{s.desc}</span>}
                {on && !paused && (
                  <span className="ss-progress" key={`p-${i}-${active}`}>
                    <span className="ss-progress-fill" />
                  </span>
                )}
              </button>
            </li>
          );
        })}
      </ul>

      {/* stage */}
      <div className="ss-stage">
        <div className="ss-stage-glow" />
        {SHOTS.map((s, i) => (
          <Image
            key={s.src}
            src={s.src}
            alt={s.en}
            width={620}
            height={680}
            priority={i === 0}
            className={`ss-shot${i === active ? " is-active" : ""}`}
          />
        ))}
      </div>
    </div>
  );
}
