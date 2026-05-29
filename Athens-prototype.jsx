import React, { useState, useEffect, useCallback } from "react";
import { Home, Plus, User, ArrowUpDown, Crown } from "lucide-react";

/* =============================== THEME =============================== */
const THEMES = {
  dark: {
    bg: "#000000",
    surface: "#141414",
    surface2: "#1C1C1C",
    chip: "#1E1E1E",
    line: "#262626",
    text: "#F2F1EE",
    muted: "#8C8C8C",
    faint: "#5A5A5A",
    mint: "#74E0A4",
    mintSoft: "#1E3A2C",
    mintText: "#56D08D",
    match: "#8C8A3E",
    matchText: "#0A0A0A",
    navBg: "rgba(26,26,26,0.86)",
  },
  light: {
    bg: "#E9E7E2",
    surface: "#F5F3EF",
    surface2: "#FFFFFF",
    chip: "#FFFFFF",
    line: "#DAD7D0",
    text: "#171614",
    muted: "#6E6B64",
    faint: "#A19D94",
    mint: "#3DBE6E",
    mintSoft: "#CFEFD8",
    mintText: "#2E9E58",
    match: "#EADF9E",
    matchText: "#3A3722",
    navBg: "rgba(240,238,233,0.86)",
  },
};

/* ============================== DATA ============================== */
const SEED = [
  { title: "Loveless", artist: "My Bloody Valentine", kind: "Album", year: "1991" },
  { title: "머리에 꽃을", artist: "실리카겔", kind: "Album", year: "2023" },
  { title: "Souvlaki", artist: "Slowdive", kind: "Album", year: "1993" },
  { title: "Heaven or Las Vegas", artist: "Cocteau Twins", kind: "Album", year: "1990" },
  { title: "新しい果実", artist: "長谷川白紙", kind: "Album", year: "2021" },
  { title: "비행운", artist: "새소년", kind: "Track", year: "2024" },
  { title: "VIVID", artist: "ADOY", kind: "Album", year: "2017" },
  { title: "In Rainbows", artist: "Radiohead", kind: "Album", year: "2007" },
];

const expected = (a, b) => 1 / (1 + Math.pow(10, (b - a) / 400));
const toScore = (r) => Math.max(0, Math.min(10, 10 / (1 + Math.pow(10, (1000 - r) / 320))));
const hash = (s) => { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return Math.abs(h); };
const initials = (s) => s.replace(/[^\p{L}\p{N} ]/gu, "").trim().slice(0, 2).toUpperCase();

async function fetchCover(term) {
  try {
    const c = new AbortController();
    const t = setTimeout(() => c.abort(), 3000);
    const r = await fetch(`https://itunes.apple.com/search?term=${encodeURIComponent(term)}&media=music&limit=1`, { signal: c.signal });
    clearTimeout(t);
    const d = await r.json();
    const a = d.results?.[0]?.artworkUrl100;
    return a ? a.replace("100x100bb", "600x600bb") : null;
  } catch { return null; }
}

const mk = (o) => ({ id: Math.random().toString(36).slice(2), rating: 1000 + (Math.random() * 60 - 30), comparisons: 0, cover: null, ...o });

/* ============================== APP ============================== */
export default function App() {
  const [mode, setMode] = useState("dark");
  const T = THEMES[mode];
  const [items, setItems] = useState(() => SEED.map(mk));
  const [view, setView] = useState("rate");
  const [pair, setPair] = useState(null);
  const [picked, setPicked] = useState(null);

  useEffect(() => {
    items.forEach(async (it) => {
      if (it.cover === null) {
        const c = await fetchCover(`${it.artist} ${it.title}`);
        setItems((p) => p.map((x) => (x.id === it.id ? { ...x, cover: c || false } : x)));
      }
    });
  }, []); // eslint-disable-line

  const makePair = useCallback((list) => {
    if (list.length < 2) return null;
    const a = [...list].sort((x, y) => x.comparisons - y.comparisons)[Math.floor(Math.random() * 2)];
    const rest = list.filter((x) => x.id !== a.id).sort((x, y) => Math.abs(x.rating - a.rating) - Math.abs(y.rating - a.rating));
    const b = rest[Math.floor(Math.random() * Math.min(3, rest.length))];
    return Math.random() > 0.5 ? [a, b] : [b, a];
  }, []);

  useEffect(() => { if (!pair) setPair(makePair(items)); }, [pair, items, makePair]);

  const choose = (winId) => {
    if (!pair || picked) return;
    setPicked(winId);
    const [a, b] = pair;
    const w = a.id === winId ? a : b, l = a.id === winId ? b : a;
    const ew = expected(w.rating, l.rating);
    const next = items.map((it) =>
      it.id === w.id ? { ...it, rating: it.rating + 32 * (1 - ew), comparisons: it.comparisons + 1 }
      : it.id === l.id ? { ...it, rating: it.rating + 32 * (0 - (1 - ew)), comparisons: it.comparisons + 1 }
      : it);
    setItems(next);
    setTimeout(() => { setPicked(null); setPair(makePair(next)); }, 480);
  };

  const ranked = [...items].sort((a, b) => b.rating - a.rating);

  return (
    <div style={{ ...sx.root, background: T.bg, color: T.text }}>
      <style>{CSS}</style>

      <header style={sx.header}>
        <span style={{ ...sx.h1, color: T.text }}>{view === "rate" ? "Rate" : "Library"}</span>
        <button onClick={() => setMode(mode === "dark" ? "light" : "dark")} style={{ ...sx.modeBtn, background: T.chip, color: T.muted, border: `1px solid ${T.line}` }}>
          {mode === "dark" ? "Light" : "Dark"}
        </button>
      </header>

      <main style={sx.main}>
        {view === "rate" ? <Rate T={T} pair={pair} picked={picked} onChoose={choose} /> : <Library T={T} ranked={ranked} />}
      </main>

      <nav style={{ ...sx.nav, background: T.navBg, border: `1px solid ${T.line}` }} className="nav-blur">
        <button style={{ ...sx.navItem, color: view === "rate" ? T.text : T.faint }} onClick={() => setView("rate")}>
          <Home size={22} strokeWidth={view === "rate" ? 2.6 : 2} /><span style={sx.navLabel}>Home</span>
        </button>
        <button style={{ ...sx.navAdd, background: T.text }}><Plus size={22} color={T.bg} strokeWidth={2.8} /></button>
        <button style={{ ...sx.navItem, color: view === "library" ? T.text : T.faint }} onClick={() => setView("library")}>
          <User size={22} strokeWidth={view === "library" ? 2.6 : 2} /><span style={sx.navLabel}>Me</span>
        </button>
      </nav>
    </div>
  );
}

/* ============================== RATE (duel) ============================== */
function Rate({ T, pair, picked, onChoose }) {
  if (!pair) return null;
  const [a, b] = pair;
  return (
    <div style={sx.rateWrap}>
      <p style={{ ...sx.sub, color: T.muted }}>Popular on Athens this week</p>
      <Chips T={T} items={["All", "Indie", "Shoegaze", "Rock", "Ambient"]} active="Shoegaze" />

      <p style={{ ...sx.question, color: T.text }}>Which did you like more?</p>
      <div style={sx.duel}>
        <DuelCard T={T} item={a} dim={picked && picked !== a.id} win={picked === a.id} onClick={() => onChoose(a.id)} />
        <DuelCard T={T} item={b} dim={picked && picked !== b.id} win={picked === b.id} onClick={() => onChoose(b.id)} />
      </div>
      <div style={sx.duelActions}>
        <span style={{ color: T.muted }}>Undo</span>
        <span style={{ color: T.faint }}>•</span>
        <span style={{ color: T.muted }}>Too tough</span>
      </div>
    </div>
  );
}

function DuelCard({ T, item, dim, win, onClick }) {
  return (
    <button onClick={onClick} className="duel-card"
      style={{ ...sx.duelCard, background: T.surface, border: `1px solid ${win ? T.mint : T.line}`,
        opacity: dim ? 0.4 : 1, transform: win ? "translateY(-4px)" : "none" }}>
      <ArtBlur item={item} T={T} />
      <div style={sx.duelCardInner}>
        <p style={{ ...sx.duelTitle, color: T.text }}>{item.title}</p>
        <p style={{ ...sx.duelArtist, color: T.muted }}>{item.artist}</p>
      </div>
    </button>
  );
}

function ArtBlur({ item, T }) {
  return (
    <div style={sx.artBlurWrap}>
      {item.cover ? (
        <img src={item.cover} alt="" style={sx.artBlurImg} />
      ) : (
        <div style={{ ...sx.artBlurImg, background: T.surface2 }} />
      )}
      <div style={{ ...sx.artBlurScrim, background: `linear-gradient(180deg, ${T.surface}33, ${T.surface}dd)` }} />
    </div>
  );
}

/* ============================== LIBRARY ============================== */
function Library({ T, ranked }) {
  return (
    <div style={sx.libWrap}>
      <div style={sx.sortRow}>
        <button style={{ ...sx.sortBtn, background: T.chip, color: T.text, border: `1px solid ${T.line}` }}>
          <ArrowUpDown size={13} style={{ marginRight: 6 }} /> Rating
        </button>
        <Chips T={T} items={["All", "Albums", "Tracks", "Artists"]} active="All" inline />
      </div>
      {ranked.map((it, i) => (
        <div key={it.id} style={{ ...sx.row, borderBottom: `1px solid ${T.line}` }} className="lib-row">
          <span style={{ ...sx.rank, color: T.faint }}>{i + 1}</span>
          <Cover item={it} T={T} size={56} />
          <div style={sx.rowMid}>
            <p style={{ ...sx.rowTitle, color: T.text }}>{it.title}</p>
            <p style={{ ...sx.rowMeta, color: T.muted }}>
              {it.kind} · {it.year}{i === 0 && <Crown size={12} style={{ marginLeft: 6, marginBottom: -1, color: T.mintText }} />}
            </p>
          </div>
          <ScoreRing T={T} value={toScore(it.rating)} />
        </div>
      ))}
    </div>
  );
}

function Cover({ item, T, size }) {
  return (
    <div style={{ width: size, height: size, borderRadius: 10, overflow: "hidden", flexShrink: 0, background: T.surface2 }}>
      {item.cover ? (
        <img src={item.cover} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      ) : (
        <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: T.faint, fontSize: 13, fontWeight: 700, fontFamily: "'Hanken Grotesk', sans-serif" }}>
          {initials(item.title)}
        </div>
      )}
    </div>
  );
}

/* The signature element: circular score ring */
function ScoreRing({ T, value }) {
  const r = 20, c = 2 * Math.PI * r, frac = value / 10;
  return (
    <div style={sx.ringWrap}>
      <svg width="48" height="48" viewBox="0 0 48 48">
        <circle cx="24" cy="24" r={r} fill="none" stroke={T.line} strokeWidth="2.5" />
        <circle cx="24" cy="24" r={r} fill="none" stroke={T.mint} strokeWidth="2.5" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c * (1 - frac)} transform="rotate(-90 24 24)"
          style={{ transition: "stroke-dashoffset .5s cubic-bezier(.2,.8,.2,1)" }} />
        <text x="24" y="24" textAnchor="middle" dominantBaseline="central"
          fontFamily="'Hanken Grotesk', sans-serif" fontSize="14" fontWeight="700" fill={T.mintText}>
          {value.toFixed(1)}
        </text>
      </svg>
    </div>
  );
}

/* ============================== shared ============================== */
function Chips({ T, items, active, inline }) {
  return (
    <div style={{ ...sx.chips, ...(inline ? { margin: 0, paddingLeft: 10 } : {}) }} className="chips-scroll">
      {items.map((c) => {
        const on = c === active;
        return (
          <span key={c} style={{
            ...sx.chip,
            background: on ? T.mintSoft : T.chip,
            color: on ? T.mintText : T.muted,
            border: `1px solid ${on ? "transparent" : T.line}`,
            fontWeight: on ? 700 : 500,
          }}>{c}</span>
        );
      })}
    </div>
  );
}

/* ============================== styles ============================== */
const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700;800&family=Pretendard:wght@400;500;600;700&display=swap');
@import url('https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.css');
* { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
.duel-card { transition: transform .45s cubic-bezier(.2,.8,.2,1), opacity .3s ease, border-color .3s ease; cursor: pointer; }
.duel-card:active { transform: scale(.97) !important; }
.lib-row { transition: background .15s ease; }
.chips-scroll { overflow-x: auto; scrollbar-width: none; }
.chips-scroll::-webkit-scrollbar { display: none; }
.nav-blur { backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); }
@keyframes fade { from { opacity: 0; transform: translateY(8px);} to { opacity:1; transform:none;} }
`;

const FONT = "'Hanken Grotesk', 'Pretendard', sans-serif";

const sx = {
  root: { width: "100%", maxWidth: 420, margin: "0 auto", height: "100vh", minHeight: 680, display: "flex", flexDirection: "column", fontFamily: FONT, overflow: "hidden", position: "relative" },
  header: { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "22px 20px 8px" },
  h1: { fontSize: 34, fontWeight: 800, letterSpacing: "-0.02em" },
  modeBtn: { fontSize: 12, fontWeight: 600, padding: "6px 13px", borderRadius: 20, cursor: "pointer", fontFamily: FONT },
  main: { flex: 1, overflowY: "auto", animation: "fade .35s ease" },

  /* rate */
  rateWrap: { padding: "0 20px 120px" },
  sub: { fontSize: 14, fontWeight: 500, marginTop: 2, marginBottom: 16 },
  question: { fontSize: 21, fontWeight: 800, letterSpacing: "-0.01em", margin: "30px 0 18px" },
  duel: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 },
  duelCard: { borderRadius: 18, padding: 0, overflow: "hidden", position: "relative", textAlign: "left", aspectRatio: "1 / 1.18" },
  artBlurWrap: { position: "absolute", inset: 0 },
  artBlurImg: { width: "100%", height: "100%", objectFit: "cover", filter: "blur(14px) saturate(1.1)", transform: "scale(1.25)" },
  artBlurScrim: { position: "absolute", inset: 0 },
  duelCardInner: { position: "absolute", left: 0, right: 0, bottom: 0, padding: 16 },
  duelTitle: { fontSize: 18, fontWeight: 800, letterSpacing: "-0.01em", lineHeight: 1.15, margin: 0 },
  duelArtist: { fontSize: 13.5, fontWeight: 500, marginTop: 4 },
  duelActions: { display: "flex", gap: 10, justifyContent: "center", marginTop: 26, fontSize: 14, fontWeight: 600 },

  /* library */
  libWrap: { padding: "4px 0 120px" },
  sortRow: { display: "flex", alignItems: "center", gap: 8, padding: "4px 20px 14px" },
  sortBtn: { display: "flex", alignItems: "center", fontSize: 13, fontWeight: 700, padding: "8px 13px", borderRadius: 20, cursor: "pointer", fontFamily: FONT, flexShrink: 0 },
  row: { display: "flex", alignItems: "center", gap: 14, padding: "12px 20px" },
  rank: { width: 18, textAlign: "center", fontSize: 14, fontWeight: 600, flexShrink: 0 },
  rowMid: { flex: 1, minWidth: 0 },
  rowTitle: { fontSize: 16.5, fontWeight: 800, letterSpacing: "-0.01em", margin: 0, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" },
  rowMeta: { fontSize: 13, fontWeight: 500, marginTop: 3, display: "flex", alignItems: "center" },
  ringWrap: { flexShrink: 0 },

  /* chips */
  chips: { display: "flex", gap: 8, margin: "0 -20px", padding: "0 20px", whiteSpace: "nowrap" },
  chip: { fontSize: 13.5, padding: "8px 15px", borderRadius: 20, flexShrink: 0 },

  /* nav */
  nav: { position: "absolute", bottom: 18, left: "50%", transform: "translateX(-50%)", display: "flex", alignItems: "center", gap: 26, padding: "10px 22px", borderRadius: 34 },
  navItem: { display: "flex", flexDirection: "column", alignItems: "center", gap: 3, background: "none", border: "none", cursor: "pointer", fontFamily: FONT, width: 52 },
  navLabel: { fontSize: 11, fontWeight: 600 },
  navAdd: { width: 42, height: 42, borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", border: "none", cursor: "pointer" },
};
