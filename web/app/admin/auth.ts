import 'server-only';
import { cookies } from 'next/headers';
import { createHash } from 'crypto';

// Cookie holds sha256(password) — the plaintext password never touches the
// client. A request is authed only if it can reproduce that hash, which
// requires knowing ADMIN_DASHBOARD_PASSWORD.
export const ADMIN_COOKIE = 'athens_admin';
export const SESSION_MAX_AGE = 60 * 60 * 12; // 12h

export function adminPassword(): string {
  return process.env.ADMIN_DASHBOARD_PASSWORD ?? '';
}

export function sessionToken(): string {
  return createHash('sha256').update(adminPassword()).digest('hex');
}

export async function isAdminAuthed(): Promise<boolean> {
  if (!adminPassword()) return false; // misconfigured — fail closed
  const store = await cookies();
  return store.get(ADMIN_COOKIE)?.value === sessionToken();
}
