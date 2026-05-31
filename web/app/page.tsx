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
              웹 앱 시작하기 →
            </Link>
            <a
              href="https://github.com/junnnnnw00/athens/releases/latest"
              target="_blank"
              rel="noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 8,
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
              Android 앱 다운로드
            </a>
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

        {/* Android Sideload Guide */}
        <section
          style={{
            marginTop: 72,
            background: 'linear-gradient(180deg, var(--surface) 0%, rgba(20, 20, 20, 0.4) 100%)',
            border: '1px solid var(--line)',
            borderRadius: 24,
            padding: '40px 32px',
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
            <span style={{ fontSize: 32 }}>🤖</span>
            <div>
              <h2
                style={{
                  margin: 0,
                  fontSize: 20,
                  fontWeight: 700,
                  color: 'var(--text)',
                  letterSpacing: '-0.02em',
                }}
              >
                안드로이드 앱 설치 가이드
              </h2>
              <p style={{ margin: '4px 0 0', fontSize: 14, color: 'var(--muted)' }}>
                Google Play 스토어 외 수동 설치(Sideload) 방법 안내
              </p>
            </div>
          </div>

          <ol style={{ margin: 0, paddingLeft: 20, color: 'var(--muted)', fontSize: 14.5, lineHeight: 1.8 }}>
            <li style={{ marginBottom: 12 }}>
              <strong style={{ color: 'var(--text)' }}>APK 파일 다운로드</strong>
              <br />
              위의 <span style={{ color: 'var(--accent-text)', fontWeight: 600 }}>Android 앱 다운로드</span> 버튼 또는{' '}
              <a
                href="https://github.com/junnnnnw00/athens/releases/latest"
                target="_blank"
                rel="noreferrer"
                style={{ color: 'var(--accent-text)', textDecoration: 'underline' }}
              >
                GitHub Releases
              </a>
              에서 최신 버전의 <code style={{ background: 'var(--line)', padding: '2px 6px', borderRadius: 4, fontFamily: 'monospace', fontSize: 13 }}>athens-1.1.4.apk</code> 파일을 다운로드합니다.
            </li>
            <li style={{ marginBottom: 12 }}>
              <strong style={{ color: 'var(--text)' }}>출처를 알 수 없는 앱 설치 권한 허용</strong>
              <br />
              다운로드 완료 후 파일을 실행할 때 보안 경고가 나타나면, 설정에서 <span style={{ color: 'var(--text)', fontWeight: 600 }}>'이 출처의 앱 허용'</span> 또는 브라우저의 파일 설치 권한을 활성화해 주세요.
            </li>
            <li style={{ marginBottom: 0 }}>
              <strong style={{ color: 'var(--text)' }}>설치 완료 및 실행</strong>
              <br />
              설치 프로그램에 따라 설치를 완료한 후 앱을 실행해 홈 화면의 아이콘이나 앱 서랍에서 Athens를 시작할 수 있습니다.
            </li>
          </ol>

          {/* Sideload note */}
          <div
            style={{
              marginTop: 24,
              padding: '16px 20px',
              borderRadius: 12,
              background: 'rgba(255, 120, 0, 0.05)',
              border: '1px solid rgba(255, 120, 0, 0.15)',
              fontSize: 13.5,
              color: '#FFB87A',
              lineHeight: 1.6,
            }}
          >
            💡 <strong>팁:</strong> 안드로이드 앱 설치 후 앱을 실행할 때마다 최신 업데이트를 자동으로 검사합니다. 새로운 릴리즈가 출시되면 홈 화면에 업데이트 알림 배너가 표시되며 편리하게 최신 APK를 받아보실 수 있습니다.
          </div>
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
