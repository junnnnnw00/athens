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

export interface RecentUser {
  handle: string;
  display_name: string | null;
  created_at: string;
  is_public: boolean;
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
  recentUsers: RecentUser[];
  // 참여도
  totalRatings: number;
  totalComparisons: number;
  totalReviews: number;
  totalItems: number;
  avgRatingsPerUser: number;
  activeUsers7d: number;
  duels7d: number;
  ratings7d: number;
  generatedAt: string;
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
    totalComparisons,
    totalReviews,
    totalItems,
    duels7d,
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
    count(sb, 'comparisons'),
    count(sb, 'reviews'),
    count(sb, 'items'),
    count(sb, 'comparisons', (q) => q.gte('created_at', d7)),
    count(sb, 'ratings', (q) => q.gte('updated_at', d7)),
  ]);

  // Active users = distinct users who logged a duel in the last 7 days.
  // Small dataset (≤ a few users) → dedupe in JS is fine.
  const { data: recentComps, error: compErr } = await sb
    .from('comparisons')
    .select('user_id')
    .gte('created_at', d7);
  if (compErr) throw new Error(`active users 조회 실패: ${compErr.message}`);
  const activeUsers7d = new Set((recentComps ?? []).map((r) => r.user_id)).size;

  const { data: recentUsers, error: usersErr } = await sb
    .from('profiles')
    .select('handle, display_name, created_at, is_public')
    .order('created_at', { ascending: false })
    .limit(10);
  if (usersErr) throw new Error(`최근 가입자 조회 실패: ${usersErr.message}`);

  return {
    totalUsers,
    new24h,
    new7d,
    new30d,
    premiumUsers,
    publicProfiles,
    spotifyConnected,
    recentUsers: (recentUsers ?? []) as RecentUser[],
    totalRatings,
    totalComparisons,
    totalReviews,
    totalItems,
    avgRatingsPerUser: totalUsers ? totalRatings / totalUsers : 0,
    activeUsers7d,
    duels7d,
    ratings7d,
    generatedAt: new Date().toISOString(),
  };
}
