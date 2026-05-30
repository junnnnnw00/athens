import Link from 'next/link';

export const metadata = {
  title: 'Athens — 음악을 평가하고, 취향을 발견하세요',
  description:
    '둘 중 하나를 고르는 간단한 게임으로 당신의 음악 취향을 0–10점으로 정리하고, 랭킹과 공개 프로필로 공유하세요.',
};

const features: { title: string; body: string }[] = [
  {
    title: '둘 중 하나만 고르세요',
    body: '“어느 쪽이 더 좋아요?” 한 번의 탭이 쌓여 0–10점 점수와 개인 랭킹이 됩니다. 별점 고민은 그만.',
  },
  {
    title: '깊이 있는 태그',
    body: 'Last.fm과 MusicBrainz에서 가져온 장르·무드 태그로 슈게이즈, 몽환적, 멜랑콜리까지 — RateYourMusic의 감성.',
  },
  {
    title: '어디서나 동기화',
    body: '기기 간 자동 동기화. 오프라인에서 평가해도 다시 연결되면 그대로 이어집니다.',
  },
  {
    title: '공개 프로필로 공유',
    body: '당신의 Top 랭킹과 점수 분포를 담은 페이지를 athens.vercel.app/u/내핸들 로 공유하세요.',
  },
];

export default function Home() {
  return (
    <>
      <div className="bg-glow" />
      <main
        style={{
          position: 'relative',
          zIndex: 1,
          width: '100%',
          maxWidth: 680,
          margin: '0 auto',
          padding: '88px 24px 96px',
        }}
      >
        {/* Hero */}
        <section style={{ textAlign: 'center' }}>
          <span
            style={{
              display: 'inline-block',
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: '0.18em',
              textTransform: 'uppercase',
              color: 'var(--accent-text)',
              marginBottom: 20,
            }}
          >
            Pairwise music rating
          </span>
          <h1
            style={{
              margin: 0,
              fontSize: 'clamp(44px, 9vw, 76px)',
              fontWeight: 800,
              letterSpacing: '-0.045em',
              lineHeight: 1.02,
              color: 'var(--text)',
            }}
          >
            음악을 평가하고,
            <br />
            취향을 발견하세요.
          </h1>
          <p
            style={{
              margin: '24px auto 0',
              maxWidth: 460,
              fontSize: 17,
              lineHeight: 1.6,
              color: 'var(--muted)',
            }}
          >
            둘 중 하나를 고르는 간단한 게임이 당신의 트랙·앨범·아티스트를
            0–10점으로 정리합니다. Athens에서 시작하세요.
          </p>

          <div
            style={{
              display: 'flex',
              gap: 12,
              justifyContent: 'center',
              flexWrap: 'wrap',
              marginTop: 36,
            }}
          >
            <Link
              href="/app"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 8,
                height: 50,
                padding: '0 28px',
                borderRadius: 999,
                background: 'var(--accent)',
                color: '#0E1F16',
                fontWeight: 700,
                fontSize: 15,
                boxShadow: '0 8px 30px var(--glow)',
              }}
            >
              앱 시작하기 →
            </Link>
            <a
              href="https://github.com/junnnnnw00/athens"
              target="_blank"
              rel="noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                height: 50,
                padding: '0 24px',
                borderRadius: 999,
                background: 'var(--surface)',
                border: '1px solid var(--line)',
                color: 'var(--text)',
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
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
            gap: 14,
            marginTop: 72,
          }}
        >
          {features.map((f) => (
            <div
              key={f.title}
              style={{
                background: 'var(--surface)',
                border: '1px solid var(--line)',
                borderRadius: 18,
                padding: '24px 22px',
                boxShadow: '0 2px 12px var(--shadow)',
              }}
            >
              <h3
                style={{
                  margin: 0,
                  fontSize: 17,
                  fontWeight: 700,
                  color: 'var(--text)',
                  letterSpacing: '-0.01em',
                }}
              >
                {f.title}
              </h3>
              <p
                style={{
                  margin: '10px 0 0',
                  fontSize: 14.5,
                  lineHeight: 1.6,
                  color: 'var(--muted)',
                }}
              >
                {f.body}
              </p>
            </div>
          ))}
        </section>

        {/* Footer */}
        <footer
          style={{
            marginTop: 80,
            textAlign: 'center',
            fontSize: 13,
            color: 'var(--faint)',
          }}
        >
          <Link href="/app" style={{ color: 'var(--accent-text)', fontWeight: 600 }}>
            앱 열기
          </Link>
          <span style={{ margin: '0 10px' }}>·</span>
          <span>오픈소스 · MIT</span>
        </footer>
      </main>
    </>
  );
}
