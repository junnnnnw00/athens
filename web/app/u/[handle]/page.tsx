import { createClient } from '@supabase/supabase-js';
import { notFound } from 'next/navigation';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '';

interface TopItem {
  id: string;
  kind: string;
  title: string;
  primary_artist: string | null;
  image_url: string | null;
  score: number;
  comparisons: number;
  tags: { name: string; source: string }[];
}

interface ProfileStats {
  total_rated: number;
  avg_score: number;
  total_comparisons: number;
}

interface PublicProfile {
  id: string;
  handle: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  created_at: string;
  top_items: TopItem[];
  stats: ProfileStats;
}

async function getProfile(handle: string): Promise<PublicProfile | null> {
  if (!supabaseUrl || supabaseUrl === '') return null;

  const supabase = createClient(supabaseUrl, supabaseAnonKey);
  const { data, error } = await supabase
    .from('public_profiles')
    .select('*')
    .eq('handle', handle.toLowerCase())
    .maybeSingle();

  if (error || !data) return null;
  return data as PublicProfile;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ handle: string }>;
}) {
  const { handle } = await params;
  const profile = await getProfile(handle);
  if (!profile) return { title: 'Profile not found — Crate' };
  return {
    title: `${profile.display_name ?? profile.handle} — Crate`,
    description: profile.bio ?? `Music ratings by ${profile.handle} on Crate.`,
  };
}

export default async function ProfilePage({
  params,
}: {
  params: Promise<{ handle: string }>;
}) {
  const { handle } = await params;
  const profile = await getProfile(handle);

  if (!profile) notFound();

  return (
    <main style={{ maxWidth: 640, margin: '0 auto', padding: '24px 16px', fontFamily: 'system-ui, sans-serif' }}>
      <header style={{ marginBottom: 32 }}>
        {profile.avatar_url && (
          <img
            src={profile.avatar_url}
            alt={profile.display_name ?? profile.handle}
            width={80}
            height={80}
            style={{ borderRadius: '50%', marginBottom: 12 }}
          />
        )}
        <h1 style={{ margin: 0, fontSize: 28 }}>
          {profile.display_name ?? profile.handle}
        </h1>
        <p style={{ margin: '4px 0 0', color: '#666' }}>@{profile.handle}</p>
        {profile.bio && (
          <p style={{ marginTop: 8, color: '#444' }}>{profile.bio}</p>
        )}
        <div style={{ display: 'flex', gap: 24, marginTop: 12, color: '#555', fontSize: 14 }}>
          <span><strong>{profile.stats?.total_rated ?? 0}</strong> rated</span>
          <span><strong>{profile.stats?.avg_score?.toFixed(1) ?? '—'}</strong> avg score</span>
          <span><strong>{profile.stats?.total_comparisons ?? 0}</strong> duels</span>
        </div>
      </header>

      {profile.top_items && profile.top_items.length > 0 && (
        <section>
          <h2 style={{ fontSize: 20, marginBottom: 16 }}>Top Rated</h2>
          <ol style={{ padding: 0, listStyle: 'none', margin: 0 }}>
            {profile.top_items.map((item, i) => (
              <li
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  padding: '12px 0',
                  borderBottom: '1px solid #eee',
                }}
              >
                <span style={{ minWidth: 24, color: '#999', fontWeight: 700 }}>
                  {i + 1}
                </span>
                {item.image_url && (
                  <img
                    src={item.image_url}
                    alt={item.title}
                    width={48}
                    height={48}
                    style={{ borderRadius: 4, objectFit: 'cover' }}
                  />
                )}
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600 }}>{item.title}</div>
                  {item.primary_artist && (
                    <div style={{ color: '#666', fontSize: 14 }}>{item.primary_artist}</div>
                  )}
                  {item.tags && item.tags.length > 0 && (
                    <div style={{ marginTop: 4, display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                      {item.tags.slice(0, 3).map((tag) => (
                        <span
                          key={tag.name}
                          style={{
                            background: '#f0f0f0',
                            borderRadius: 4,
                            padding: '2px 6px',
                            fontSize: 11,
                            color: '#555',
                          }}
                        >
                          {tag.name}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
                <span
                  style={{
                    fontWeight: 700,
                    fontSize: 20,
                    color: '#6B4EFF',
                    minWidth: 36,
                    textAlign: 'right',
                  }}
                >
                  {item.score?.toFixed(1)}
                </span>
              </li>
            ))}
          </ol>
        </section>
      )}

      <footer style={{ marginTop: 48, textAlign: 'center', color: '#aaa', fontSize: 12 }}>
        <a href="/" style={{ color: '#6B4EFF', textDecoration: 'none' }}>
          Rate your music on Crate →
        </a>
      </footer>
    </main>
  );
}
