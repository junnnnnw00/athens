"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

type Shot = { src: string; en: string; ko: string; desc: string };

const SHOTS: Shot[] = [
  { src: "/landing/screens/duel.png", en: "Battle Your Music", ko: "1:1 평가",
    desc: "두 곡을 나란히 놓고 더 끌리는 쪽을 탭. 그게 평가의 전부예요." },
  { src: "/landing/screens/home.png", en: "Anywhere, Anytime", ko: "둘러보기",
    desc: "자주 듣는 곡이 매일 새로 추천돼요. 평가는 한 손으로, 언제 어디서나." },
  { src: "/landing/screens/stats.png", en: "Analyze Your Taste", ko: "취향 분석",
    desc: "평가가 쌓이면 점수 분포·평균·최다 듀얼이 한눈에. 내 취향이 숫자로 보여요." },
  { src: "/landing/screens/genre.png", en: "Genre & Mood", ko: "장르 · 무드",
    desc: "Last.fm·MusicBrainz 태그로 장르와 분위기까지 깊게. 슈게이즈부터 멜랑콜리까지." },
  { src: "/landing/screens/profile.png", en: "Share Your Profile", ko: "프로필 공유",
    desc: "내 Top 랭킹과 커버 월을 프로필 한 장으로. 친구에게 링크로 바로 공유." },
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
                <span className="ss-item-en">{s.en}</span>
                <span className="ss-item-ko">{s.ko}</span>
                {on && <span className="ss-item-desc">{s.desc}</span>}
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
