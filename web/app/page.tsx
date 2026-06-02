import Link from "next/link";
import AuthRedirectHandler from "./components/AuthRedirectHandler";

export const metadata = {
  title: "취향을 쌓다, 기록을 쌓다",
  description:
    "둘 중 하나를 고르는 간단한 게임으로 언제 어디서든 취향을 쌓으세요",
};

const features: { title: string; body: string }[] = [
  {
    title: "1대1 취향 월드컵",
    body: "애매한 별점 평가 대신, 두 곡 중 더 마음에 드는 곡을 직관적으로 고르세요. Elo 레이팅 알고리즘이 실시간으로 서열을 매깁니다.",
  },
  {
    title: "다양한 장르 및 무드의 태그",
    body: "Last.fm 및 MusicBrainz API와 연동된 깊이 있는 장르·무드 정보. 슈게이즈, 몽환적, 멜랑콜리 등 세밀한 감성까지 파헤칩니다.",
  },
  {
    title: "어디서나 동기화",
    body: "오프라인에서 평가해도 문제없습니다. 기기 간 자동 동기화로 언제 어디서나 중단 없이 음악 라이브러리를 가꾸세요.",
  },
  {
    title: "나만의 음악 프로필 공유",
    body: "나의 Top 랭킹과 실시간 선호 장르 분포가 기록된 나만의 프로필 페이지(athens.vercel.app/u/handle)를 친구들과 공유해 보세요.",
  },
];

export default function Home() {
  return (
    <>
      <AuthRedirectHandler />
      <main
        style={{
          position: "relative",
          zIndex: 1,
          width: "100%",
          maxWidth: 680,
          margin: "0 auto",
          padding: "88px 24px 96px",
        }}
      >
        {/* Hero */}
        <section style={{ textAlign: "center" }}>
          <span
            style={{
              display: "inline-block",
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: "0.18em",
              textTransform: "uppercase",
              color: "var(--accent-text)",
              marginBottom: 20,
            }}
          >
            Pairwise music rating
          </span>
          <h1
            style={{
              margin: 0,
              fontSize: "clamp(40px, 8vw, 68px)",
              fontWeight: 800,
              letterSpacing: "-0.04em",
              lineHeight: 1.05,
              color: "var(--text)",
            }}
          >
            취향을 쌓다.
            <br />
            기록을 쌓다.
          </h1>
          <p
            style={{
              margin: "24px auto 0",
              maxWidth: 480,
              fontSize: 16.5,
              lineHeight: 1.6,
              color: "var(--muted)",
            }}
          >
            둘 중 하나를 고르는 간단한 게임으로 언제 어디서든 취향을 쌓으세요
          </p>

          <div
            style={{
              display: "flex",
              gap: 12,
              justifyContent: "center",
              flexWrap: "wrap",
              marginTop: 36,
            }}
          >
            <Link
              href="/app"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                height: 50,
                padding: "0 28px",
                borderRadius: 999,
                background: "var(--accent)",
                color: "#0E1F16",
                fontWeight: 700,
                fontSize: 15,
              }}
            >
              웹 앱 시작하기 →
            </Link>
            <a
              href="https://github.com/junnnnnw00/athens/releases/latest"
              target="_blank"
              rel="noreferrer"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                height: 50,
                padding: "0 24px",
                borderRadius: 999,
                background: "var(--surface)",
                border: "1px solid var(--line)",
                color: "var(--text)",
                fontWeight: 600,
                fontSize: 15,
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 17V3" />
                <path d="m6 11 6 6 6-6" />
                <path d="M19 21H5" />
              </svg>
              Android 앱
            </a>
            <a
              href="https://github.com/junnnnnw00/athens/releases/latest"
              target="_blank"
              rel="noreferrer"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                height: 50,
                padding: "0 24px",
                borderRadius: 999,
                background: "var(--surface)",
                border: "1px solid var(--line)",
                color: "var(--text)",
                fontWeight: 600,
                fontSize: 15,
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 17V3" />
                <path d="m6 11 6 6 6-6" />
                <path d="M19 21H5" />
              </svg>
              macOS 앱
            </a>
            <a
              href="https://github.com/junnnnnw00/athens"
              target="_blank"
              rel="noreferrer"
              style={{
                display: "inline-flex",
                alignItems: "center",
                height: 50,
                padding: "0 24px",
                borderRadius: 999,
                background: "var(--surface)",
                border: "1px solid var(--line)",
                color: "var(--text)",
                fontWeight: 600,
                fontSize: 15,
              }}
            >
              GitHub
            </a>
          </div>
        </section>

        {/* Feature grid */}
        <section
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
            gap: 14,
            marginTop: 56,
          }}
        >
          {features.map((f) => (
            <div
              key={f.title}
              style={{
                background: "var(--surface)",
                border: "1px solid var(--line)",
                borderRadius: 18,
                padding: "24px 22px",
              }}
            >
              <h3
                style={{
                  margin: 0,
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--text)",
                  letterSpacing: "-0.01em",
                }}
              >
                {f.title}
              </h3>
              <p
                style={{
                  margin: "10px 0 0",
                  fontSize: 13.5,
                  lineHeight: 1.6,
                  color: "var(--muted)",
                }}
              >
                {f.body}
              </p>
            </div>
          ))}
        </section>

        {/* Sideload Guide Mini Note */}
        <section
          style={{
            marginTop: 56,
            background: "var(--surface)",
            border: "1px solid var(--line)",
            borderRadius: 18,
            padding: "20px 24px",
            textAlign: "left",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <span style={{ fontSize: 20 }}>🤖</span>
            <div style={{ flex: 1 }}>
              <h4
                style={{
                  margin: 0,
                  fontSize: 14.5,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                안드로이드/macOS 수동 설치 안내
              </h4>
              <p
                style={{
                  margin: "4px 0 0",
                  fontSize: 13,
                  color: "var(--muted)",
                  lineHeight: 1.5,
                }}
              >
                APK 또는 zip 파일을 다운로드한 후 기기 보안 설정에서 '이 출처의
                앱 허용'을 활성화하여 설치할 수 있습니다. 앱 실행 시 자동으로
                최신 릴리즈를 감지하여 업데이트 안내를 제공합니다.
              </p>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer
          style={{
            marginTop: 80,
            textAlign: "center",
            fontSize: 13,
            color: "var(--faint)",
          }}
        >
          <Link
            href="/app"
            style={{ color: "var(--accent-text)", fontWeight: 600 }}
          >
            앱 열기
          </Link>
          <span style={{ margin: "0 10px" }}>·</span>
          <span>오픈소스 · MIT</span>
        </footer>
      </main>
    </>
  );
}
