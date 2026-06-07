import { createClient } from '@supabase/supabase-js';
import { notFound } from 'next/navigation';
import ProfileView, { PublicProfile } from './profile_view';

export const dynamic = 'force-dynamic';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '';

async function getProfile(handle: string): Promise<PublicProfile | null> {
  if (!supabaseUrl || supabaseUrl === '') return null;

  const supabase = createClient(supabaseUrl, supabaseAnonKey);
  const { data, error } = await supabase
    .from('public_profiles')
    .select('*')
    .eq('handle', handle.toLowerCase())
    .maybeSingle();

  if (error || !data) return null;

  // Fallback: If lastfm_username is not returned in the view, fetch it from profiles table.
  let lastfm_username = (data as any).lastfm_username || null;
  if (!lastfm_username) {
    const { data: profileRow } = await supabase
      .from('profiles')
      .select('lastfm_username')
      .eq('id', data.id)
      .maybeSingle();
    if (profileRow) {
      lastfm_username = profileRow.lastfm_username;
    }
  }

  return {
    ...data,
    lastfm_username,
  } as PublicProfile;
}

function getInitials(name: string): string {
  const clean = name.trim().replace(/[^a-zA-Z0-9\sㄱ-ㅎㅏ-ㅣ가-힣]/g, '');
  if (!clean) return 'AT';
  const parts = clean.split(/\s+/);
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return clean.substring(0, Math.min(2, clean.length)).toUpperCase();
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ handle: string }>;
}) {
  const { handle } = await params;
  const profile = await getProfile(handle);
  if (!profile) return { title: 'Profile not found — Athens' };
  return {
    title: `${profile.display_name ?? profile.handle} — Athens`,
    description: profile.bio ?? `Music ratings by ${profile.handle} on Athens.`,
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

  const initials = getInitials(profile.display_name ?? profile.handle);

  return (
    <>
      <div className="bg-glow" />
      <ProfileView profile={profile} initials={initials} />
    </>
  );
}
