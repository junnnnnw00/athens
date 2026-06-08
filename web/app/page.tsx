import Link from "next/link";
import AuthRedirectHandler from "./components/AuthRedirectHandler";
import DuelDemo from "./components/DuelDemo";
import ScreenShowcase from "./components/ScreenShowcase";
import FeatureCards from "./components/FeatureCards";

export const metadata = {
  title: "Athens Music Rating & App — Battle your music",
  description:
    "Athens is a pairwise music rating app where you choose between two tracks/albums instead of writing complex star reviews. Start ranking your favorites today.",
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
          <Link href="/app" className="lp-bar-link">Open App →</Link>
        </header>

        {/* hero — interactive duel */}
        <section className="lp-hero">
          <div className="lp-hero-copy">
            <span className="lp-eyebrow">Athens Music — Pairwise Music Rating</span>
            <h1 className="lp-h1">Don&apos;t rate music.<br />Choose it.</h1>
            <p className="lp-sub">
              <strong>Athens</strong> is an intuitive <strong>Music Rating</strong> app. Instead of writing complex star reviews, simply choose between two tracks or albums to mathematically calculate your personal <strong>Athens Music</strong> rankings.
            </p>
            <div className="lp-cta-row">
              <Link href="/app" className="lp-btn lp-btn-primary">Launch Web App →</Link>
              <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-btn lp-btn-ghost">
                <DownloadIcon /> Download App
              </a>
            </div>
            <div className="lp-badge-row">
              <a 
                href="https://www.producthunt.com/products/athens?embed=true&amp;utm_source=badge-featured&amp;utm_medium=badge&amp;utm_campaign=badge-athens" 
                target="_blank" 
                rel="noopener noreferrer"
                className="lp-ph-badge"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img 
                  src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1166056&amp;theme=light&amp;t=1780878078773" 
                  alt="Athens - Battle your music, stack your taste | Product Hunt" 
                  width="250" 
                  height="54" 
                  style={{ width: "250px", height: "54px" }} 
                />
              </a>
              <a
                href="https://ko-fi.com/C3V820LKKR"
                target="_blank"
                rel="noopener noreferrer"
                className="lp-kofi-btn"
              >
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                  style={{ transform: "translateY(-1px)" }}
                >
                  <path
                    fill="#ffffff"
                    d="M23.881 8.948c-.773-4.085-4.859-4.593-4.859-4.593H.723c-.604 0-.679.798-.679.798s-.082 7.324-.022 11.822c.164 12.3 7.854 12.61 7.854 12.61h9.133c9.562-.178 8.044-10.74 8.044-10.74 2.202-.174 3.06-2.455 3.06-4.526 0-2.072-.254-5.371-3.254-5.371zm-4.707 9.872a4.42 4.42 0 0 1-4.094 3.256H3.143c-.452 0-.566-.414-.566-.414s-.735-8.49-.754-12.756c0-.453.49-.528.49-.528h17.38c.49 0 .452.452.452.452s-.414 4.903-.52 9.99zm2.451-2.903s-.452.075-.49.075c.189-2.263.34-4.412.415-5.996h.641c.867 0 1.395.754 1.395 2.112 0 1.357-.641 3.809-1.961 3.809zm-8.825-7.052c-1.395-1.546-4.593-1.357-4.593-1.357s-.528 2.828.604 4.375c1.131 1.546 3.991 1.621 3.991 1.621s.754-2.225-.002-4.639z"
                  />
                </svg>
                Support me on Ko-fi
              </a>
            </div>
          </div>
          <DuelDemo />
        </section>

        {/* rate → rank → reflect, animated */}
        <FeatureCards />

        {/* real screens showcase */}
        <section className="lp-section">
          <h2 className="lp-section-title">What the app looks like.</h2>
          <p className="lp-section-lead">A complete music rating engine, built for mobile.</p>
          <ScreenShowcase />
        </section>

        {/* download */}
        <section className="lp-section lp-cta-end">
          <h2 className="lp-section-title">Anywhere, the same library.</h2>
          <p className="lp-section-lead">
            Automatic cross-device sync, even when offline. Share your taste with a public profile at{" "}
            <strong style={{ color: "var(--text)" }}>athens.vercel.app/u/handle</strong>.
          </p>
          <div className="lp-download">
            <Link href="/app" className="lp-chip lp-chip-primary">Launch Web App →</Link>
            <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-chip"><DownloadIcon /> Android</a>
            <a href={RELEASES} target="_blank" rel="noreferrer" className="lp-chip"><DownloadIcon /> macOS</a>
            <a href={REPO} target="_blank" rel="noreferrer" className="lp-chip">GitHub</a>
          </div>
        </section>

        {/* footer */}
        <footer className="lp-footer">
          <Link href="/app">Open App</Link>
          <span className="lp-dot">·</span>
          <span>Open Source · MIT</span>
          <span className="lp-dot">·</span>
          <Link href="/privacy">Privacy Policy</Link>
        </footer>
      </div>
    </>
  );
}
