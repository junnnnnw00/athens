import 'server-only';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// service_role client — bypasses RLS. MUST stay server-only; never import this
// module from a 'use client' component.
function adminClient(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url) throw new Error('NEXT_PUBLIC_SUPABASE_URL 미설정');
  if (!key) throw new Error('SUPABASE_SERVICE_ROLE_KEY 미설정');
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    // Next.js patches global fetch with its caching layer, which mangles
    // supabase-js HEAD count requests (empty error, no Content-Range). Force
    // every admin query to bypass the cache.
    global: {
      fetch: (input, init) =>
        fetch(input as RequestInfo, { ...init, cache: 'no-store' }),
    },
  });
}

// Loose typing on purpose: chaining .eq()/.gte() onto the projected builder
// blows past TS's instantiation depth limit, so the filter callback is untyped.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type CountQuery = (q: any) => any;

async function count(
  sb: SupabaseClient,
  table: string,
  build?: CountQuery,
): Promise<number> {
  // NB: `head: true` (HEAD request) returns an empty/non-2xx response under the
  // Next.js server runtime — postgrest surfaces it as an error with no message.
  // A normal GET limited to 1 row still returns the exact total count.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let q: any = sb.from(table).select('id', { count: 'exact' }).limit(1);
  if (build) q = build(q);
  const { count: c, error } = await q;
  if (error) throw new Error(`${table} count 실패: ${error.message}`);
  return c ?? 0;
}

// Like count(), but returns null instead of throwing when the column/table is
// missing (e.g. the 0010 premium/friends migration not yet applied to hosted).
async function tryCount(
  sb: SupabaseClient,
  table: string,
  build?: CountQuery,
): Promise<number | null> {
  try {
    return await count(sb, table, build);
  } catch {
    return null;
  }
}

export interface UserRow {
  id: string;
  handle: string;
  display_name: string | null;
  created_at: string;
  is_public: boolean;
  spotify_enabled: boolean;
  ratingCount: number;
}

export interface ChartPoint {
  label: string;
  value: number;
}

export interface DashboardStats {
  // 유저 / 성장
  totalUsers: number;
  new24h: number;
  new7d: number;
  new30d: number;
  premiumUsers: number | null; // null = is_premium 컬럼 미적용(0010)
  publicProfiles: number;
  spotifyConnected: number;
  users: UserRow[];
  // 참여도
  totalRatings: number;
  totalDuels: number; // ratings.comparisons 합 / 2 (comparisons 테이블은 미사용)
  totalReviews: number;
  totalItems: number;
  avgRatingsPerUser: number;
  avgDuelsPerRating: number;
  activeUsers7d: number;
  ratings7d: number;
  // 차트
  signupsDaily: ChartPoint[]; // 최근 30일 일별 가입
  activityDaily: ChartPoint[]; // 최근 30일 일별 평가 활동
  scoreDist: ChartPoint[]; // 점수 분포 0–10
  itemsByKind: ChartPoint[]; // 카탈로그 종류별
  generatedAt: string;
}

// 최근 `days`일을 0으로 채운 일별 시리즈. 라벨은 매월 1일/5일 간격만 표시(나머지 공백).
function dailySeries(isoDates: string[], days: number): ChartPoint[] {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const keys: string[] = [];
  const buckets = new Map<string, number>();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const k = d.toISOString().slice(0, 10);
    keys.push(k);
    buckets.set(k, 0);
  }
  for (const iso of isoDates) {
    const k = iso.slice(0, 10);
    if (buckets.has(k)) buckets.set(k, (buckets.get(k) ?? 0) + 1);
  }
  return keys.map((k, i) => ({
    // 5칸마다 + 마지막 칸에 day-of-month 라벨, 나머지는 공백
    label: i % 5 === 0 || i === keys.length - 1 ? k.slice(8, 10) : '',
    value: buckets.get(k) ?? 0,
  }));
}

function scoreDistribution(scores: number[]): ChartPoint[] {
  const b: ChartPoint[] = Array.from({ length: 10 }, (_, i) => ({
    label: String(i),
    value: 0,
  }));
  for (const s of scores) {
    let idx = Math.floor(s);
    if (idx < 0) idx = 0;
    if (idx > 9) idx = 9;
    b[idx].value++;
  }
  return b;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const sb = adminClient();
  const now = Date.now();
  const d1 = new Date(now - 864e5).toISOString();
  const d7 = new Date(now - 7 * 864e5).toISOString();
  const d30 = new Date(now - 30 * 864e5).toISOString();

  const [
    totalUsers,
    new24h,
    new7d,
    new30d,
    premiumUsers,
    publicProfiles,
    spotifyConnected,
    totalRatings,
    totalReviews,
    totalItems,
    ratings7d,
  ] = await Promise.all([
    count(sb, 'profiles'),
    count(sb, 'profiles', (q) => q.gte('created_at', d1)),
    count(sb, 'profiles', (q) => q.gte('created_at', d7)),
    count(sb, 'profiles', (q) => q.gte('created_at', d30)),
    tryCount(sb, 'profiles', (q) => q.eq('is_premium', true)),
    count(sb, 'profiles', (q) => q.eq('is_public', true)),
    count(sb, 'profiles', (q) => q.eq('spotify_enabled', true)),
    count(sb, 'ratings'),
    count(sb, 'reviews'),
    count(sb, 'items'),
    count(sb, 'ratings', (q) => q.gte('updated_at', d7)),
  ]);

  // Full data pulls for the user table + charts (small dataset → fetch & aggregate in JS).
  const { data: usersRaw, error: usersErr } = await sb
    .from('profiles')
    .select('id, handle, display_name, created_at, is_public, spotify_enabled')
    .order('created_at', { ascending: false });
  if (usersErr) throw new Error(`유저 목록 조회 실패: ${usersErr.message}`);

  // NB: the `comparisons` table is unused by the app — duels are recorded on
  // ratings.comparisons (per-item count). Total duels ≈ sum / 2 (each duel
  // bumps two items). Active = distinct users with a rating updated in 7d.
  const { data: ratingRows, error: rErr } = await sb
    .from('ratings')
    .select('user_id, score, updated_at, comparisons');
  if (rErr) throw new Error(`평가 조회 실패: ${rErr.message}`);

  const { data: itemRows, error: iErr } = await sb.from('items').select('kind');
  if (iErr) throw new Error(`아이템 조회 실패: ${iErr.message}`);

  const ratings = ratingRows ?? [];
  const ratingCountByUser = new Map<string, number>();
  for (const r of ratings) {
    ratingCountByUser.set(r.user_id, (ratingCountByUser.get(r.user_id) ?? 0) + 1);
  }

  // 듀얼 횟수: ratings.comparisons 합 / 2 (듀얼당 두 아이템이 +1).
  const comparisonsSum = ratings.reduce(
    (a, r) => a + Number(r.comparisons ?? 0),
    0,
  );
  const totalDuels = Math.round(comparisonsSum / 2);
  // 활성 유저(7일): 최근 7일 내 평가가 갱신된(=듀얼한) 유저 수.
  const activeUsers7d = new Set(
    ratings.filter((r) => (r.updated_at as string) >= d7).map((r) => r.user_id),
  ).size;
  const users: UserRow[] = (usersRaw ?? []).map((u) => ({
    id: u.id,
    handle: u.handle,
    display_name: u.display_name,
    created_at: u.created_at,
    is_public: u.is_public,
    spotify_enabled: u.spotify_enabled,
    ratingCount: ratingCountByUser.get(u.id) ?? 0,
  }));

  const signupsDaily = dailySeries(
    (usersRaw ?? []).map((u) => u.created_at as string),
    30,
  );
  const activityDaily = dailySeries(
    ratings.map((r) => r.updated_at as string),
    30,
  );
  const scoreDist = scoreDistribution(ratings.map((r) => Number(r.score)));

  const kindCounts = new Map<string, number>();
  for (const it of itemRows ?? []) {
    kindCounts.set(it.kind, (kindCounts.get(it.kind) ?? 0) + 1);
  }
  const itemsByKind: ChartPoint[] = (
    ['track', 'album', 'artist'] as const
  ).map((k) => ({ label: k, value: kindCounts.get(k) ?? 0 }));

  return {
    totalUsers,
    new24h,
    new7d,
    new30d,
    premiumUsers,
    publicProfiles,
    spotifyConnected,
    users,
    totalRatings,
    totalDuels,
    totalReviews,
    totalItems,
    avgRatingsPerUser: totalUsers ? totalRatings / totalUsers : 0,
    avgDuelsPerRating: totalRatings ? comparisonsSum / totalRatings : 0,
    activeUsers7d,
    ratings7d,
    signupsDaily,
    activityDaily,
    scoreDist,
    itemsByKind,
    generatedAt: new Date().toISOString(),
  };
}

export interface TopItem {
  title: string;
  artist: string | null;
  kind: string;
  score: number;
  elo: number;
}

export interface UserDetail {
  id: string;
  handle: string;
  display_name: string | null;
  bio: string | null;
  created_at: string;
  is_public: boolean;
  spotify_enabled: boolean;
  spotify_user_id: string | null;
  ratingCount: number;
  avgElo: number;
  avgScore: number;
  reviewCount: number;
  duelCount: number; // 이 유저 ratings.comparisons 합 / 2
  topItems: TopItem[];
}

export async function getUserDetail(userId: string): Promise<UserDetail | null> {
  const sb = adminClient();

  const { data: p, error: pErr } = await sb
    .from('profiles')
    .select(
      'id, handle, display_name, bio, created_at, is_public, spotify_enabled, spotify_user_id',
    )
    .eq('id', userId)
    .maybeSingle();
  if (pErr) throw new Error(`유저 조회 실패: ${pErr.message}`);
  if (!p) return null;

  const { data: ratingRows, error: rErr } = await sb
    .from('ratings')
    .select('elo, score, comparisons')
    .eq('user_id', userId);
  if (rErr) throw new Error(`유저 평가 조회 실패: ${rErr.message}`);
  const rr = ratingRows ?? [];
  const ratingCount = rr.length;
  const avgElo = ratingCount
    ? rr.reduce((a, r) => a + Number(r.elo), 0) / ratingCount
    : 0;
  const avgScore = ratingCount
    ? rr.reduce((a, r) => a + Number(r.score), 0) / ratingCount
    : 0;
  const duelCount = Math.round(
    rr.reduce((a, r) => a + Number(r.comparisons ?? 0), 0) / 2,
  );

  const reviewCount = await count(sb, 'reviews', (q) => q.eq('user_id', userId));

  const { data: topRaw, error: tErr } = await sb
    .from('ratings')
    .select('elo, score, items(title, primary_artist, kind)')
    .eq('user_id', userId)
    .order('elo', { ascending: false })
    .limit(12);
  if (tErr) throw new Error(`유저 랭킹 조회 실패: ${tErr.message}`);

  // items() join returns a related object; type loosely to avoid TS depth issues.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const topItems: TopItem[] = (topRaw ?? []).map((r: any) => ({
    title: r.items?.title ?? '(알 수 없음)',
    artist: r.items?.primary_artist ?? null,
    kind: r.items?.kind ?? '',
    score: Number(r.score),
    elo: Number(r.elo),
  }));

  return {
    id: p.id,
    handle: p.handle,
    display_name: p.display_name,
    bio: p.bio,
    created_at: p.created_at,
    is_public: p.is_public,
    spotify_enabled: p.spotify_enabled,
    spotify_user_id: p.spotify_user_id,
    ratingCount,
    avgElo,
    avgScore,
    reviewCount,
    duelCount,
    topItems,
  };
}
