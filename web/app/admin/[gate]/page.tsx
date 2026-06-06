import { notFound } from 'next/navigation';
import { isAdminAuthed } from '../auth';
import { logout } from '../actions';
import {
  getDashboardStats,
  getUserList,
  getUserDetail,
  type DashboardStats,
  type UserDetail,
  type UserRow,
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
    { label: 'duel', value: fmt(user.duelCount) },
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
            {user.lastfmConnected ? ' · Last.fm' : ''}
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

function pct(part: number, whole: number): string {
  if (!whole) return '—';
  return `${fmt1((part / whole) * 100)}%`;
}

function MiniList({
  rows,
}: {
  rows: { left: string; sub?: string; right: string }[];
}) {
  return (
    <div style={{ border: '1px solid var(--line)', borderRadius: 12, overflow: 'hidden' }}>
      {rows.length === 0 ? (
        <div style={{ padding: '16px 18px', fontSize: 13.5, color: 'var(--faint)' }}>없음</div>
      ) : (
        rows.map((r, i) => (
          <div
            key={i}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 12,
              padding: '11px 16px',
              borderTop: i === 0 ? 'none' : '1px solid var(--line)',
            }}
          >
            <div style={{ minWidth: 0, flex: 1 }}>
              <div
                style={{
                  fontSize: 14,
                  fontWeight: 600,
                  color: 'var(--text)',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                {r.left}
              </div>
              {r.sub && <div style={{ fontSize: 12.5, color: 'var(--faint)' }}>{r.sub}</div>}
            </div>
            <span style={{ fontSize: 14, fontWeight: 800, color: 'var(--accent-text)', whiteSpace: 'nowrap' }}>
              {r.right}
            </span>
          </div>
        ))
      )}
    </div>
  );
}

function Dashboard({
  stats,
  users,
  basePath,
  userDetail,
}: {
  stats: DashboardStats;
  users: UserRow[];
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

      {/* 활성 사용자 — 한눈에 (최상단 강조) */}
      <SectionTitle>활성 사용자</SectionTitle>
      <div style={grid}>
        <StatCard label="DAU" value={fmt(stats.dau)} sub="오늘 듀얼한 유저" accent />
        <StatCard label="WAU" value={fmt(stats.wau)} sub="최근 7일" accent />
        <StatCard label="MAU" value={fmt(stats.mau)} sub="최근 30일" accent />
        <StatCard
          label="끈끈함 (DAU/MAU)"
          value={stats.mau ? pct(stats.dau, stats.mau) : '—'}
          sub="stickiness"
        />
        <StatCard
          label="7일 리텐션"
          value={pct(stats.retain7d, stats.eligibleRetain)}
          sub={`${fmt(stats.retain7d)}/${fmt(stats.eligibleRetain)} 복귀`}
        />
      </div>

      {/* 유저 / 성장 */}
      <SectionTitle>유저 · 성장</SectionTitle>
      <div style={grid}>
        <StatCard label="총 유저" value={fmt(stats.totalUsers)} accent />
        <StatCard label="신규 (24h)" value={`+${fmt(stats.new24h)}`} />
        <StatCard label="신규 (7일)" value={`+${fmt(stats.new7d)}`} />
        <StatCard label="신규 (30일)" value={`+${fmt(stats.new30d)}`} />
        <StatCard
          label="활성화율"
          value={pct(stats.activatedUsers, stats.totalUsers)}
          sub={`${fmt(stats.activatedUsers)}명 평가 시작`}
        />
        <StatCard
          label="빈 라이브러리"
          value={fmt(stats.emptyLibraryUsers)}
          sub="가입했지만 평가 0"
        />
        <StatCard label="공개 프로필" value={fmt(stats.publicProfiles)} sub={pct(stats.publicProfiles, stats.totalUsers)} />
        <StatCard label="Last.fm 연결" value={fmt(stats.lastfmConnected)} sub={pct(stats.lastfmConnected, stats.totalUsers)} />
        <StatCard
          label="삭제 요청 대기"
          value={fmt(stats.deletionPending)}
          sub={stats.deletionPending > 0 ? '⚠ 처리 필요' : '없음'}
          accent={stats.deletionPending > 0}
        />
      </div>

      {/* 참여도 */}
      <SectionTitle>참여도 · 콘텐츠</SectionTitle>
      <div style={grid}>
        <StatCard label="총 평가" value={fmt(stats.totalRatings)} accent />
        <StatCard label="총 듀얼" value={fmt(stats.totalDuels)} sub="comparisons 실측" />
        <StatCard
          label="유저당 평균 평가"
          value={fmt1(stats.activatedUsers ? stats.totalRatings / stats.activatedUsers : 0)}
          sub="활성 유저 기준"
        />
        <StatCard label="듀얼 (7일)" value={`+${fmt(stats.duels7d)}`} />
        <StatCard label="평가 갱신 (7일)" value={`+${fmt(stats.ratings7d)}`} />
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
        <ChartCard title="일별 듀얼" hint="최근 30일 · 실제 활동">
          <BarChart data={stats.duelsDaily} color="var(--accent-text)" />
        </ChartCard>
        <ChartCard title="점수 분포" hint="0–9 구간">
          <BarChart data={stats.scoreDist} />
        </ChartCard>
        <ChartCard title="카탈로그 종류" hint={`총 ${fmt(stats.totalItems)}`}>
          <BarChart data={stats.itemsByKind} color="var(--accent-text)" />
        </ChartCard>
      </div>

      {/* Top 아이템 + 최근 가입 */}
      <SectionTitle>가장 많이 평가된 곡 · 최근 가입</SectionTitle>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: 14,
        }}
      >
        <ChartCard title="글로벌 Top 아이템" hint="평가 수 기준">
          <MiniList
            rows={stats.topItems.map((it) => ({
              left: it.title,
              sub: `${it.artist || '—'} · ${it.kind} · 평균 ${fmt1(it.avgScore)}`,
              right: `${fmt(it.ratingCount)}회`,
            }))}
          />
        </ChartCard>
        <ChartCard title="최근 가입" hint="최신 10명">
          <MiniList
            rows={stats.recentSignups.map((s) => ({
              left: s.display_name || s.handle,
              sub: `@${s.handle}${s.is_public ? ' · 공개' : ''}`,
              right: new Date(s.created_at).toLocaleDateString('ko-KR', {
                month: '2-digit',
                day: '2-digit',
              }),
            }))}
          />
        </ChartCard>
      </div>

      {/* 유저 목록 — 행 클릭 시 상세 */}
      <SectionTitle>유저 ({fmt(users.length)}) · 클릭하면 상세</SectionTitle>
      <div
        style={{
          background: 'var(--surface)',
          border: '1px solid var(--line)',
          borderRadius: 16,
          overflow: 'hidden',
        }}
      >
        {users.length === 0 ? (
          <div style={{ padding: '24px 22px', color: 'var(--faint)', fontSize: 14 }}>
            아직 가입자가 없습니다.
          </div>
        ) : (
          users.map((u, i) => (
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
                {u.lastfmConnected && (
                  <span
                    style={{
                      fontSize: 11,
                      fontWeight: 700,
                      color: 'var(--muted)',
                      border: '1px solid var(--line)',
                      padding: '3px 8px',
                      borderRadius: 999,
                    }}
                  >
                    Last.fm
                  </span>
                )}
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
        집계: {new Date(stats.generatedAt).toLocaleString('ko-KR')} · DB 집계 + 60초 캐시
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
  let users: UserRow[] = [];
  let userDetail: UserDetail | null = null;
  let error: string | null = null;
  try {
    [stats, users, userDetail] = await Promise.all([
      getDashboardStats(),
      getUserList(),
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
          users={users}
          basePath={`/admin/${gate}`}
          userDetail={userDetail}
        />
      ) : (
        <ErrorState message={error ?? '알 수 없는 오류'} />
      )}
    </>
  );
}
