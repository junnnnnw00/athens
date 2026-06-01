import { notFound } from 'next/navigation';
import { isAdminAuthed } from '../auth';
import { logout } from '../actions';
import {
  getDashboardStats,
  getUserDetail,
  type DashboardStats,
  type UserDetail,
  type ChartPoint,
} from '../stats';
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

// 의존성 없는 CSS 막대 차트.
function BarChart({
  data,
  height = 140,
  color = 'var(--accent)',
}: {
  data: ChartPoint[];
  height?: number;
  color?: string;
}) {
  const max = Math.max(1, ...data.map((d) => d.value));
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height }}>
      {data.map((d, i) => (
        <div
          key={i}
          style={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'flex-end',
            gap: 6,
            height: '100%',
          }}
          title={`${d.label || i}: ${d.value}`}
        >
          <div
            style={{
              width: '100%',
              height: `${(d.value / max) * 100}%`,
              minHeight: d.value > 0 ? 3 : 0,
              background: color,
              borderRadius: '4px 4px 0 0',
              transition: 'height 0.2s',
            }}
          />
          <span
            style={{
              fontSize: 9.5,
              color: 'var(--faint)',
              whiteSpace: 'nowrap',
              height: 12,
            }}
          >
            {d.label}
          </span>
        </div>
      ))}
    </div>
  );
}

function ChartCard({
  title,
  hint,
  children,
}: {
  title: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--line)',
        borderRadius: 16,
        padding: '20px 22px 16px',
        boxShadow: '0 2px 12px var(--shadow)',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'baseline',
          justifyContent: 'space-between',
          gap: 8,
          marginBottom: 16,
        }}
      >
        <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--text)' }}>
          {title}
        </span>
        {hint && <span style={{ fontSize: 12, color: 'var(--faint)' }}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

function UserDetailPanel({
  user,
  backHref,
}: {
  user: UserDetail;
  backHref: string;
}) {
  const meta: { label: string; value: string }[] = [
    { label: '평가 수', value: fmt(user.ratingCount) },
    { label: '평균 점수', value: fmt1(user.avgScore) },
    { label: '평균 Elo', value: fmt(Math.round(user.avgElo)) },
    { label: 'duel', value: fmt(user.comparisonCount) },
    { label: '리뷰', value: fmt(user.reviewCount) },
  ];
  return (
    <section
      style={{
        marginTop: 40,
        background: 'var(--surface)',
        border: '1px solid var(--line)',
        borderRadius: 18,
        padding: '24px 24px 28px',
        boxShadow: '0 4px 20px var(--shadow)',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'baseline',
          justifyContent: 'space-between',
          gap: 12,
          flexWrap: 'wrap',
        }}
      >
        <div style={{ minWidth: 0 }}>
          <div
            style={{
              fontSize: 24,
              fontWeight: 800,
              letterSpacing: '-0.03em',
              color: 'var(--text)',
            }}
          >
            {user.display_name || user.handle}
          </div>
          <div style={{ fontSize: 13.5, color: 'var(--muted)', marginTop: 2 }}>
            @{user.handle} · 가입{' '}
            {new Date(user.created_at).toLocaleDateString('ko-KR')}
            {user.is_public ? ' · 공개' : ' · 비공개'}
            {user.spotify_enabled ? ' · Spotify' : ''}
          </div>
        </div>
        <a
          href={backHref}
          style={{
            fontSize: 13,
            fontWeight: 600,
            color: 'var(--accent-text)',
            whiteSpace: 'nowrap',
          }}
        >
          ← 전체로
        </a>
      </div>

      {user.bio && (
        <p style={{ marginTop: 14, fontSize: 14, color: 'var(--muted)', lineHeight: 1.6 }}>
          {user.bio}
        </p>
      )}

      <div style={{ ...grid, marginTop: 20 }}>
        {meta.map((m) => (
          <StatCard key={m.label} label={m.label} value={m.value} />
        ))}
      </div>

      <h3
        style={{
          margin: '28px 0 12px',
          fontSize: 12.5,
          fontWeight: 700,
          letterSpacing: '0.12em',
          textTransform: 'uppercase',
          color: 'var(--accent-text)',
        }}
      >
        Top 랭킹 (Elo 순)
      </h3>
      {user.topItems.length === 0 ? (
        <div style={{ fontSize: 14, color: 'var(--faint)' }}>아직 평가가 없습니다.</div>
      ) : (
        <div
          style={{
            border: '1px solid var(--line)',
            borderRadius: 12,
            overflow: 'hidden',
          }}
        >
          {user.topItems.map((it, i) => (
            <div
              key={i}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: '11px 16px',
                borderTop: i === 0 ? 'none' : '1px solid var(--line)',
              }}
            >
              <span
                style={{
                  fontSize: 13,
                  fontWeight: 700,
                  color: 'var(--faint)',
                  width: 22,
                }}
              >
                {i + 1}
              </span>
              <div style={{ minWidth: 0, flex: 1 }}>
                <div
                  style={{
                    fontSize: 14.5,
                    fontWeight: 600,
                    color: 'var(--text)',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                >
                  {it.title}
                </div>
                <div style={{ fontSize: 12.5, color: 'var(--faint)' }}>
                  {it.artist || '—'} · {it.kind}
                </div>
              </div>
              <span
                style={{
                  fontSize: 15,
                  fontWeight: 800,
                  color: 'var(--accent-text)',
                  whiteSpace: 'nowrap',
                }}
              >
                {fmt1(it.score)}
              </span>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

function Dashboard({
  stats,
  basePath,
  userDetail,
}: {
  stats: DashboardStats;
  basePath: string;
  userDetail: UserDetail | null;
}) {
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

      {userDetail && <UserDetailPanel user={userDetail} backHref={basePath} />}

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

      {/* 차트 */}
      <SectionTitle>추이 · 분포</SectionTitle>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: 14,
        }}
      >
        <ChartCard title="일별 가입" hint="최근 30일">
          <BarChart data={stats.signupsDaily} />
        </ChartCard>
        <ChartCard title="일별 평가 활동" hint="최근 30일 · 갱신 기준">
          <BarChart data={stats.activityDaily} color="var(--accent-text)" />
        </ChartCard>
        <ChartCard title="점수 분포" hint="0–10">
          <BarChart data={stats.scoreDist} />
        </ChartCard>
        <ChartCard title="카탈로그 종류" hint={`총 ${fmt(stats.totalItems)}`}>
          <BarChart data={stats.itemsByKind} color="var(--accent-text)" />
        </ChartCard>
      </div>

      {/* 유저 목록 — 행 클릭 시 상세 */}
      <SectionTitle>유저 ({fmt(stats.users.length)}) · 클릭하면 상세</SectionTitle>
      <div
        style={{
          background: 'var(--surface)',
          border: '1px solid var(--line)',
          borderRadius: 16,
          overflow: 'hidden',
        }}
      >
        {stats.users.length === 0 ? (
          <div style={{ padding: '24px 22px', color: 'var(--faint)', fontSize: 14 }}>
            아직 가입자가 없습니다.
          </div>
        ) : (
          stats.users.map((u, i) => (
            <a
              key={u.id}
              href={`${basePath}?user=${u.id}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: 12,
                padding: '14px 22px',
                borderTop: i === 0 ? 'none' : '1px solid var(--line)',
                color: 'inherit',
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
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 13, color: 'var(--muted)', whiteSpace: 'nowrap' }}>
                  평가 {fmt(u.ratingCount)}
                </span>
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
                <span style={{ fontSize: 13, color: 'var(--faint)', whiteSpace: 'nowrap' }}>
                  {new Date(u.created_at).toLocaleDateString('ko-KR', {
                    year: '2-digit',
                    month: '2-digit',
                    day: '2-digit',
                  })}
                </span>
                <span style={{ color: 'var(--faint)' }}>›</span>
              </div>
            </a>
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
  searchParams,
}: {
  params: Promise<{ gate: string }>;
  searchParams: Promise<{ user?: string }>;
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

  const { user: userId } = await searchParams;

  let stats: DashboardStats | null = null;
  let userDetail: UserDetail | null = null;
  let error: string | null = null;
  try {
    [stats, userDetail] = await Promise.all([
      getDashboardStats(),
      userId ? getUserDetail(userId) : Promise.resolve(null),
    ]);
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
  }

  return (
    <>
      <div className="bg-glow" />
      {stats ? (
        <Dashboard
          stats={stats}
          basePath={`/admin/${gate}`}
          userDetail={userDetail}
        />
      ) : (
        <ErrorState message={error ?? '알 수 없는 오류'} />
      )}
    </>
  );
}
