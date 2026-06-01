'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import {
  ADMIN_COOKIE,
  SESSION_MAX_AGE,
  adminPassword,
  sessionToken,
} from './auth';

// Where to send the browser after login/logout — the hidden secret URL, never
// bare /admin (which 404s). Falls back to /admin if the secret is unset.
function dashboardPath(): string {
  const secret = process.env.ADMIN_PATH_SECRET ?? '';
  return secret ? `/admin/${secret}` : '/admin';
}

export async function login(
  _prev: string | null,
  formData: FormData,
): Promise<string | null> {
  const pw = String(formData.get('password') ?? '');
  const expected = adminPassword();

  if (!expected) {
    return '서버에 ADMIN_DASHBOARD_PASSWORD 환경변수가 설정되지 않았습니다.';
  }
  if (pw !== expected) {
    return '비밀번호가 올바르지 않습니다.';
  }

  const store = await cookies();
  store.set(ADMIN_COOKIE, sessionToken(), {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/admin',
    maxAge: SESSION_MAX_AGE,
  });

  redirect(dashboardPath());
}

export async function logout() {
  const store = await cookies();
  store.delete(ADMIN_COOKIE);
  redirect(dashboardPath());
}
