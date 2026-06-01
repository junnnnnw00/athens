import { notFound } from 'next/navigation';
import { isAdminAuthed } from '../auth';
import { logout } from '../actions';
import { getDashboardStats, type DashboardStats } from '../stats';
import LoginForm from '../LoginForm';

export const dynamic = 'force-dynamic';
export const metadata = {
  title: 'Athens — 개발자 대시보드',
  robots: { index: false, follow: false },
};

const fmt = (n: number) => n.toLocaleString('ko-KR');
const fmt1 = (n: number) => n.toLocaleString('ko-KR', { maximumFractionDigits: 1 });

function StatCard({
  label,
  value,
  sub,
  accent,
}: {
  label: string;
  value: string;
  sub?: string;
  accent?: boolean;
}) {
  return (
    <div
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--line)',
        borderRadius: 16,
        padding: '20px 22px',
        boxShadow: '0 2px 12px var(--shadow)',
      }}
    >
      <div
        style={{
          fontSize: 12.5,
          fontWeight: 600,
          letterSpacing: '0.02em',
          color: 'var(--muted)',
          textTransform: 'uppercase',
        }}
      >
        {label}
      </div>
      <div
        style={{
          marginTop: 8,
          fontSize: 34,
          fontWeight: 800,
          letterSpacing: '-0.03em',
          color: accent ? 'var(--accent-text)' : 'var(--text)',
          lineHeight: 1.05,
        }}
      >
        {value}
      </div>
      {sub && (
        <div style={{ marginTop: 6, fontSize: 13, color: 'var(--faint)' }}>{sub}</div>
      )}
    </div>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <h2
      style={{
        margin: '48px 0 16px',
        fontSize: 13,
        fontWeight: 700,
        letterSpacing: '0.16em',
        textTransform: 'uppercase',
        color: 'var(--accent-text)',
      }}
    >
      {children}
    </h2>
  );
}

const grid: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
  gap: 14,
};

function Dashboard({ stats }: { stats: DashboardStats }) {
  return (
    <main
      style={{
        position: 'relative',
        zIndex: 1,
        width: '100%',
        maxWidth: 980,
        margin: '0 auto',
        padding: '64px 24px 96px',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'baseline',
          justifyContent: 'space-between',
          gap: 16,
          flexWrap: 'wrap',
        }}
      >
        <div>
          <span
            style={{
              display: 'block',
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: '0.18em',
              textTransform: 'uppercase',
              color: 'var(--accent-text)',
              marginBottom: 10,
            }}
          >
            Admin · Athens
          </span>
          <h1
            style={{
              margin: 0,
              fontSize: 'clamp(30px, 6vw, 44px)',
              fontWeight: 800,
              letterSpacing: '-0.04em',
              color: 'var(--text)',
            }}
          >
            개발자 대시보드
          </h1>
        </div>
        <form action={logout}>
          <button
            type="submit"
            style={{
              height: 38,
              padding: '0 16px',
              borderRadius: 999,
              background: 'var(--surface)',
              border: '1px solid var(--line)',
              color: 'var(--muted)',
              fontSize: 13.5,
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            로그아웃
          </button>
        </form>
      </div>

      {/* 유저 / 성장 */}
      <SectionTitle>유저 · 성장</SectionTitle>
      <div style={grid}>
        <StatCard label="총 유저" value={fmt(stats.totalUsers)} accent />
        <StatCard label="신규 (24h)" value={`+${fmt(stats.new24h)}`} />
        <StatCard label="신규 (7일)" value={`+${fmt(stats.new7d)}`} />
        <StatCard label="신규 (30일)" value={`+${fmt(stats.new30d)}`} />
        <StatCard
          label="프리미엄"
          value={stats.premiumUsers === null ? '—' : fmt(stats.premiumUsers)}
          sub={
            stats.premiumUsers === null
              ? '미적용 (0010 마이그레이션)'
              : stats.totalUsers
                ? `${fmt1((stats.premiumUsers / stats.totalUsers) * 100)}% 전환`
                : undefined
          }
        />
        <StatCard label="공개 프로필" value={fmt(stats.publicProfiles)} />
        <StatCard label="Spotify 연결" value={fmt(stats.spotifyConnected)} />
      </div>

      {/* 참여도 */}
      <SectionTitle>참여도</SectionTitle>
      <div style={grid}>
        <StatCard
          label="활성 유저 (7일)"
          value={fmt(stats.activeUsers7d)}
          sub="최근 7일 duel 기록 기준"
          accent
        />
        <StatCard label="총 평가" value={fmt(stats.totalRatings)} />
        <StatCard
          label="유저당 평균 평가"
          value={fmt1(stats.avgRatingsPerUser)}
        />
        <StatCard
          label="총 duel"
          value={fmt(stats.totalComparisons)}
          sub={`최근 7일 +${fmt(stats.duels7d)}`}
        />
        <StatCard
          label="평가 활동 (7일)"
          value={`+${fmt(stats.ratings7d)}`}
          sub="갱신된 평가 수"
        />
        <StatCard label="총 리뷰" value={fmt(stats.totalReviews)} />
        <StatCard label="카탈로그 아이템" value={fmt(stats.totalItems)} />
      </div>

      {/* 최근 가입자 */}
      <SectionTitle>최근 가입자</SectionTitle>
      <div
        style={{
          background: 'var(--surface)',
          border: '1px solid var(--line)',
          borderRadius: 16,
          overflow: 'hidden',
        }}
      >
        {stats.recentUsers.length === 0 ? (
          <div style={{ padding: '24px 22px', color: 'var(--faint)', fontSize: 14 }}>
            아직 가입자가 없습니다.
          </div>
        ) : (
          stats.recentUsers.map((u, i) => (
            <div
              key={u.handle}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: 12,
                padding: '14px 22px',
                borderTop: i === 0 ? 'none' : '1px solid var(--line)',
              }}
            >
              <div style={{ minWidth: 0 }}>
                <div
                  style={{
                    fontSize: 15,
                    fontWeight: 600,
                    color: 'var(--text)',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                >
                  {u.display_name || u.handle}
                </div>
                <div style={{ fontSize: 13, color: 'var(--faint)' }}>@{u.handle}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                {u.is_public && (
                  <span
                    style={{
                      fontSize: 11,
                      fontWeight: 700,
                      color: 'var(--accent-text)',
                      background: 'var(--accent-soft)',
                      padding: '3px 8px',
                      borderRadius: 999,
                    }}
                  >
                    PUBLIC
                  </span>
                )}
                <span style={{ fontSize: 13, color: 'var(--muted)', whiteSpace: 'nowrap' }}>
                  {new Date(u.created_at).toLocaleDateString('ko-KR', {
                    year: '2-digit',
                    month: '2-digit',
                    day: '2-digit',
                  })}
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      <p style={{ marginTop: 28, fontSize: 12.5, color: 'var(--faint)' }}>
        생성: {new Date(stats.generatedAt).toLocaleString('ko-KR')} · 매 요청마다 갱신
      </p>
    </main>
  );
}

function ErrorState({ message }: { message: string }) {
  return (
    <main
      style={{
        position: 'relative',
        zIndex: 1,
        width: '100%',
        maxWidth: 560,
        margin: '0 auto',
        padding: '100px 24px',
      }}
    >
      <h1 style={{ margin: 0, fontSize: 24, fontWeight: 800, color: 'var(--text)' }}>
        데이터를 불러오지 못했습니다
      </h1>
      <p style={{ marginTop: 12, fontSize: 14.5, color: 'var(--muted)', lineHeight: 1.6 }}>
        {message}
      </p>
      <p style={{ marginTop: 16, fontSize: 13.5, color: 'var(--faint)', lineHeight: 1.6 }}>
        Vercel 프로젝트와 <code>web/.env.local</code> 에{' '}
        <code>SUPABASE_SERVICE_ROLE_KEY</code> 가 설정되어 있는지 확인하세요.
      </p>
    </main>
  );
}

// Secret URL segment. The real entrance is /admin/<ADMIN_PATH_SECRET>.
// Any other value (including bare /admin, which has no page) yields a real 404,
// so the dashboard is not discoverable by guessing /admin.
export default async function AdminGatePage({
  params,
}: {
  params: Promise<{ gate: string }>;
}) {
  const { gate } = await params;
  const secret = process.env.ADMIN_PATH_SECRET ?? '';
  if (!secret || gate !== secret) notFound();

  if (!(await isAdminAuthed())) {
    return (
      <>
        <div className="bg-glow" />
        <LoginForm />
      </>
    );
  }

  let stats: DashboardStats | null = null;
  let error: string | null = null;
  try {
    stats = await getDashboardStats();
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
  }

  return (
    <>
      <div className="bg-glow" />
      {stats ? <Dashboard stats={stats} /> : <ErrorState message={error ?? '알 수 없는 오류'} />}
    </>
  );
}
