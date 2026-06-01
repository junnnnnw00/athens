'use client';

import { useEffect } from 'react';

export default function AuthCallback() {
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const search = window.location.search;
      const hash = window.location.hash;
      // Redirect to the Flutter web app inside /app/
      window.location.replace(`/app/${search}${hash}`);
    }
  }, []);

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      backgroundColor: '#0a0a0a',
      color: '#eaeaea',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      <div style={{ textAlign: 'center' }}>
        <h2 style={{ fontSize: '24px', fontWeight: 600, marginBottom: '8px' }}>로그인 중...</h2>
        <p style={{ color: '#888', fontSize: '15px' }}>인증을 완료하고 Athens 앱으로 이동하고 있습니다.</p>
      </div>
    </div>
  );
}
