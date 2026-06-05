"use client";

import { useEffect, useRef } from "react";

// rate → rank → reflect. Mini-visuals animate on hover (desktop) and on
// scroll-into-view (mobile, where :hover never fires).
export default function FeatureCards() {
  const root = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const cards = root.current?.querySelectorAll(".rrr-card");
    if (!cards) return;
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => e.target.classList.toggle("is-in", e.isIntersecting));
      },
      { threshold: 0.55 },
    );
    cards.forEach((c) => io.observe(c));
    return () => io.disconnect();
  }, []);

  return (
    <div className="lp-rrr" ref={root}>
      {/* RATE — a real mini duel with album art */}
      <div className="rrr-card">
        <div className="rrr-viz">
          <div className="rrr-duel">
            <span className="rrr-thumb" style={{ backgroundImage: "url(/landing/covers/idioteque.jpg)" }} />
            <span className="rrr-vs">VS</span>
            <span className="rrr-thumb is-pick" style={{ backgroundImage: "url(/landing/covers/spacesong.jpg)" }}>
              <span className="rrr-thumb-check">✓</span>
            </span>
          </div>
        </div>
        <span className="rrr-step">01 — RATE</span>
        <h3 className="rrr-title">고른다</h3>
        <p className="rrr-desc">두 곡 중 더 끌리는 쪽을 탭. 그게 끝.</p>
      </div>

      {/* RANK — colored bars growing to width, with rank + score */}
      <div className="rrr-card">
        <div className="rrr-viz">
          <div className="rrr-rows">
            {[
              { r: "1", w: "78%", s: "9.8", crown: true },
              { r: "2", w: "62%", s: "9.1", crown: false },
              { r: "3", w: "47%", s: "8.7", crown: false },
            ].map((row) => (
              <div className="rrr-row" key={row.r} style={{ ["--w" as string]: row.w }}>
                <span className="rrr-rank">{row.crown ? "👑" : row.r}</span>
                <span className="rrr-line" />
                <span className="rrr-score">{row.s}</span>
              </div>
            ))}
          </div>
        </div>
        <span className="rrr-step">02 — RANK</span>
        <h3 className="rrr-title">줄 세운다</h3>
        <p className="rrr-desc">Elo가 매 선택을 반영해 순위를 다시 짜요.</p>
      </div>

      {/* REFLECT — taste bars + genre/mood tags */}
      <div className="rrr-card">
        <div className="rrr-viz">
          <div className="rrr-reflect">
            <div className="rrr-bars">
              {[36, 64, 92, 72, 50].map((h, i) => (
                <i key={i} style={{ ["--h" as string]: `${h}%` }} />
              ))}
            </div>
            <div className="rrr-tags">
              <span>Shoegaze</span>
              <span>Dreamy</span>
            </div>
          </div>
        </div>
        <span className="rrr-step">03 — REFLECT</span>
        <h3 className="rrr-title">들여다본다</h3>
        <p className="rrr-desc">장르·무드 분포로 내 취향을 읽어줘요.</p>
      </div>
    </div>
  );
}
