import 'server-only';
import { unstable_cache } from 'next/cache';
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
    global: {
      fetch: (input, init) =>
        fetch(input as RequestInfo, { ...init, cache: 'no-store' }),
    },
  });
}

export interface ChartPoint {
  label: string;
  value: number;
}

export interface TopItem {
  title: string;
  artist: string | null;
  kind: string;
  ratingCount: number;
  avgScore: number;
}

export interface RecentSignup {
  id: string;
  handle: string;
  display_name: string | null;
  created_at: string;
  is_public: boolean;
}

export interface UserRow {
  id: string;
  handle: string;
  display_name: string | null;
  created_at: string;
  is_public: boolean;
  lastfmConnected: boolean;
  ratingCount: number;
}

export interface DashboardStats {
  // users / growth
  totalUsers: number;
  new24h: number;
  new7d: number;
  new30d: number;
  publicProfiles: number;
  lastfmConnected: number;
  emptyLibraryUsers: number;
  deletionPending: number;
  // engagement
  totalRatings: number;
  totalDuels: number;
  totalReviews: number;
  totalItems: number;
  dau: number;
  wau: number;
  mau: number;
  duels7d: number;
  ratings7d: number;
  // activation / retention
  activatedUsers: number;
  retain7d: number;
  eligibleRetain: number;
  // charts
  signupsDaily: ChartPoint[];
  duelsDaily: ChartPoint[];
  scoreDist: ChartPoint[];
  itemsByKind: ChartPoint[];
  // feeds
  topItems: TopItem[];
  recentSignups: RecentSignup[];
  generatedAt: string;
}

// Cached aggregate snapshot. The heavy lifting is a single in-DB RPC; we cache
// the result for 60s so rapid dashboard refreshes don't re-run it every time.
export const getDashboardStats = unstable_cache(
  async (): Promise<DashboardStats> => {
    const sb = adminClient();
    const { data, error } = await sb.rpc('admin_dashboard');
    if (error) throw new Error(`대시보드 집계 실패: ${error.message}`);
    return data as DashboardStats;
  },
  ['admin-dashboard'],
  { revalidate: 60 },
);

export const getUserList = unstable_cache(
  async (): Promise<UserRow[]> => {
    const sb = adminClient();
    const { data, error } = await sb.rpc('admin_user_list');
    if (error) throw new Error(`유저 목록 실패: ${error.message}`);
    return (data ?? []) as UserRow[];
  },
  ['admin-user-list'],
  { revalidate: 60 },
);

// ── per-user detail (on click) ───────────────────────────────────────────────

export interface UserDetailTopItem {
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
  lastfmConnected: boolean;
  ratingCount: number;
  avgElo: number;
  avgScore: number;
  reviewCount: number;
  duelCount: number;
  topItems: UserDetailTopItem[];
}

export async function getUserDetail(userId: string): Promise<UserDetail | null> {
  const sb = adminClient();

  const { data: p, error: pErr } = await sb
    .from('profiles')
    .select('id, handle, display_name, bio, created_at, is_public, lastfm_username')
    .eq('id', userId)
    .maybeSingle();
  if (pErr) throw new Error(`유저 조회 실패: ${pErr.message}`);
  if (!p) return null;

  const { data: ratingRows, error: rErr } = await sb
    .from('ratings')
    .select('elo, score')
    .eq('user_id', userId);
  if (rErr) throw new Error(`유저 평가 조회 실패: ${rErr.message}`);
  const rr = ratingRows ?? [];
  const ratingCount = rr.length;
  const avgElo = ratingCount ? rr.reduce((a, r) => a + Number(r.elo), 0) / ratingCount : 0;
  const avgScore = ratingCount ? rr.reduce((a, r) => a + Number(r.score), 0) / ratingCount : 0;

  // Real duel count = comparisons rows for this user.
  const { count: duelCount } = await sb
    .from('comparisons')
    .select('id', { count: 'exact' })
    .limit(1)
    .eq('user_id', userId);

  const { count: reviewCount } = await sb
    .from('reviews')
    .select('id', { count: 'exact' })
    .limit(1)
    .eq('user_id', userId);

  const { data: topRaw, error: tErr } = await sb
    .from('ratings')
    .select('elo, score, items(title, primary_artist, kind)')
    .eq('user_id', userId)
    .order('elo', { ascending: false })
    .limit(12);
  if (tErr) throw new Error(`유저 랭킹 조회 실패: ${tErr.message}`);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const topItems: UserDetailTopItem[] = (topRaw ?? []).map((r: any) => ({
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
    lastfmConnected: !!(p.lastfm_username && p.lastfm_username.trim()),
    ratingCount,
    avgElo,
    avgScore,
    reviewCount: reviewCount ?? 0,
    duelCount: duelCount ?? 0,
    topItems,
  };
}
