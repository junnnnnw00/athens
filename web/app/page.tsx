import Link from "next/link";
import AuthRedirectHandler from "./components/AuthRedirectHandler";
import DuelDemo from "./components/DuelDemo";
import ScreenShowcase from "./components/ScreenShowcase";
import FeatureCards from "./components/FeatureCards";

export const metadata = {
  title: "Athens — Battle your music",
  description:
    "두 곡 중 더 끌리는 쪽을 고르면 끝. Elo 레이팅이 당신만의 음악 순위를 실시간으로 매깁니다.",
};

const RELEASES = "https://github.com/junnnnnw00/athens/releases/latest";
const REPO = "https://github.com/junnnnnw00/athens";

const DownloadIcon = () => (
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 17V3" /><path d="m6 11 6 6 6-6" /><path d="M19 21H5" />
  </svg>
);

export default function Home() {
  return (
    <>
      <AuthRedirectHandler />
      <div className="lp">
        {/* top bar */}
        <header className="lp-bar">
          <span className="lp-wordmark">Athens</span>
          <Link href="/app" className="lp-bar-link">앱 열기 →</Link>
        </header>

        {/* hero — interactive duel */}
        <section className="lp-hero">
          <div className="lp-hero-copy">
            <span className="lp-eyebrow">Pairwise Music Rating</span>
            <h1 className="lp-h1">Don&apos;t rate music.<br />Choose it.</h1>
            <p className="lp-sub">
              두 곡 중 더 끌리는 쪽을 고르면 평가 끝. 별점도 리뷰도 없이,
              Elo가 알아서 당신만의 순위를 매겨요.
            </p>
            <div className="lp-cta-row">
              <Link href="/app" className="lp-btn lp-btn-primary">웹에서 시작하기 →</Link>
              <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-btn lp-btn-ghost">
                <DownloadIcon /> 앱 다운로드
              </a>
            </div>
          </div>
          <DuelDemo />
        </section>

        {/* rate → rank → reflect, animated */}
        <FeatureCards />

        {/* real screens showcase */}
        <section className="lp-section">
          <h2 className="lp-section-title">진짜 앱은 이렇게 생겼어요.</h2>
          <p className="lp-section-lead">평가 → 순위 → 분석까지, 손에 들고 도는 전부.</p>
          <ScreenShowcase />
        </section>

        {/* download */}
        <section className="lp-section lp-cta-end">
          <h2 className="lp-section-title">어디서나, 같은 서재.</h2>
          <p className="lp-section-lead">
            오프라인에서 평가해도 기기 간 자동 동기화. 프로필은{" "}
            <strong style={{ color: "var(--text)" }}>athens.vercel.app/u/handle</strong> 로 공유.
          </p>
          <div className="lp-download">
            <Link href="/app" className="lp-chip lp-chip-primary">웹에서 시작하기 →</Link>
            <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-chip"><DownloadIcon /> Android</a>
            <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-chip"><DownloadIcon /> macOS</a>
            <a href={REPO} target="_blank" rel="noreferrer" className="lp-chip">GitHub</a>
          </div>
        </section>

        {/* footer */}
        <footer className="lp-footer">
          <Link href="/app">앱 열기</Link>
          <span className="lp-dot">·</span>
          <span>오픈소스 · MIT</span>
          <span className="lp-dot">·</span>
          <Link href="/privacy">개인정보처리방침</Link>
        </footer>
      </div>
    </>
  );
}
