'use client';

import { useActionState } from 'react';
import { login } from './actions';

export default function LoginForm() {
  const [error, formAction, pending] = useActionState(login, null);

  return (
    <main
      style={{
        position: 'relative',
        zIndex: 1,
        width: '100%',
        maxWidth: 380,
        margin: '0 auto',
        padding: '120px 24px',
      }}
    >
      <span
        style={{
          display: 'block',
          fontSize: 12,
          fontWeight: 700,
          letterSpacing: '0.18em',
          textTransform: 'uppercase',
          color: 'var(--accent-text)',
          marginBottom: 14,
        }}
      >
        Admin
      </span>
      <h1
        style={{
          margin: 0,
          fontSize: 28,
          fontWeight: 800,
          letterSpacing: '-0.03em',
          color: 'var(--text)',
        }}
      >
        개발자 대시보드
      </h1>
      <p style={{ margin: '10px 0 28px', fontSize: 14.5, color: 'var(--muted)' }}>
        접근하려면 관리자 비밀번호를 입력하세요.
      </p>

      <form action={formAction} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <input
          type="password"
          name="password"
          autoFocus
          placeholder="비밀번호"
          style={{
            height: 48,
            padding: '0 16px',
            borderRadius: 12,
            background: 'var(--surface)',
            border: '1px solid var(--line)',
            color: 'var(--text)',
            fontSize: 15,
            outline: 'none',
          }}
        />
        <button
          type="submit"
          disabled={pending}
          style={{
            height: 48,
            borderRadius: 12,
            border: 'none',
            background: 'var(--accent)',
            color: '#0E1F16',
            fontWeight: 700,
            fontSize: 15,
            cursor: pending ? 'default' : 'pointer',
            opacity: pending ? 0.6 : 1,
          }}
        >
          {pending ? '확인 중…' : '로그인'}
        </button>
        {error && (
          <p style={{ margin: '4px 0 0', fontSize: 13.5, color: '#FF6B6B' }}>{error}</p>
        )}
      </form>
    </main>
  );
}
