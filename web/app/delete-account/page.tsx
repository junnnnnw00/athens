'use client';

import React, { useState } from 'react';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '';

const containerStyle: React.CSSProperties = {
  width: '100%',
  maxWidth: 540,
  margin: '0 auto',
  padding: '120px 24px 96px',
  color: '#ffffff',
  fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
};

const cardStyle: React.CSSProperties = {
  backgroundColor: '#161618',
  borderRadius: 16,
  border: '1px solid #2e2e32',
  padding: '32px 24px',
  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
};

const titleStyle: React.CSSProperties = {
  fontSize: 24,
  fontWeight: 800,
  letterSpacing: '-0.5px',
  marginBottom: 8,
};

const subtitleStyle: React.CSSProperties = {
  fontSize: 14,
  color: '#a1a1aa',
  lineHeight: 1.6,
  marginBottom: 24,
};

const sectionTitleStyle: React.CSSProperties = {
  fontSize: 15,
  fontWeight: 600,
  color: '#f4f4f5',
  marginBottom: 10,
};

const listStyle: React.CSSProperties = {
  paddingLeft: 20,
  marginBottom: 24,
  color: '#a1a1aa',
  fontSize: 13.5,
  lineHeight: 1.7,
};

const inputStyle: React.CSSProperties = {
  width: '100%',
  backgroundColor: '#0c0c0d',
  border: '1px solid #2e2e32',
  borderRadius: 8,
  padding: '12px 16px',
  color: '#ffffff',
  fontSize: 15,
  outline: 'none',
  transition: 'border-color 0.2s',
  marginBottom: 16,
};

const buttonStyle: React.CSSProperties = {
  width: '100%',
  backgroundColor: '#f93902', // Orange accent color matching Athens logo
  color: '#000000',
  fontWeight: 700,
  border: 'none',
  borderRadius: 8,
  padding: '14px',
  fontSize: 15,
  cursor: 'pointer',
  transition: 'opacity 0.2s',
};

const successCardStyle: React.CSSProperties = {
  ...cardStyle,
  textAlign: 'center',
  borderColor: '#2e2e32',
};

export default function DeleteAccount() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) return;

    setLoading(true);
    setError('');

    try {
      const supabase = createClient(supabaseUrl, supabaseAnonKey);
      
      // 1. Verify user credentials by signing in
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password: password.trim(),
      });

      if (authError) {
        throw new Error('이메일 또는 비밀번호가 올바르지 않습니다.');
      }

      // 2. Store the verified deletion request
      const { error: insertError } = await supabase
        .from('deletion_requests')
        .insert([{ email: email.trim().toLowerCase() }]);

      if (insertError) throw insertError;

      // 3. Sign out to clear the transient session
      await supabase.auth.signOut();
      
      setSuccess(true);
    } catch (err: any) {
      console.error(err);
      setError(err.message || '요청 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main style={containerStyle}>
      {!success ? (
        <div style={cardStyle}>
          <h1 style={titleStyle}>계정 및 데이터 삭제 요청</h1>
          <p style={subtitleStyle}>
            본인 인증을 위해 가입하신 이메일과 비밀번호를 입력해 주세요.
          </p>

          <h2 style={sectionTitleStyle}>삭제되는 데이터 범위:</h2>
          <ul style={listStyle}>
            <li>로그인 계정 정보 (이메일 및 인증 정보)</li>
            <li>앱 내 모든 앨범/곡 평가 및 듀얼 대결 내역</li>
            <li>공개 프로필 정보 및 취향 통계 보고서</li>
            <li>연동된 Last.fm 계정 정보</li>
          </ul>

          <div
            style={{
              padding: '12px 16px',
              backgroundColor: 'rgba(239, 68, 68, 0.08)',
              border: '1px solid rgba(239, 68, 68, 0.2)',
              borderRadius: 8,
              fontSize: 13,
              color: '#f87171',
              lineHeight: 1.5,
              marginBottom: 24,
            }}
          >
            ⚠️ <strong>주의:</strong> 계정 및 데이터 삭제가 완료되면 복구할 수 없습니다.
          </div>

          <form onSubmit={handleSubmit}>
            <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 8, color: '#e4e4e7' }}>
              가입하신 이메일 주소
            </label>
            <input
              type="email"
              required
              placeholder="example@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={inputStyle}
              disabled={loading}
            />

            <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 8, color: '#e4e4e7' }}>
              비밀번호
            </label>
            <input
              type="password"
              required
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={inputStyle}
              disabled={loading}
            />

            {error && (
              <p style={{ color: '#f87171', fontSize: 13, marginTop: -8, marginBottom: 16 }}>
                {error}
              </p>
            )}

            <button
              type="submit"
              style={{
                ...buttonStyle,
                opacity: loading ? 0.6 : 1,
                cursor: loading ? 'not-allowed' : 'pointer',
              }}
              disabled={loading}
            >
              {loading ? '요청 전송 중...' : '계정 및 데이터 삭제 요청'}
            </button>
          </form>
        </div>
      ) : (
        <div style={successCardStyle}>
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: '50%',
              backgroundColor: 'rgba(34, 197, 94, 0.1)',
              border: '1px solid rgba(34, 197, 94, 0.3)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 20px',
            }}
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#22c55e"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <polyline points="20 6 9 17 4 12" />
            </svg>
          </div>
          <h1 style={titleStyle}>요청이 접수되었습니다</h1>
          <p style={{ ...subtitleStyle, marginBottom: 0, marginTop: 8 }}>
            입력하신 이메일(<strong>{email}</strong>)의 계정 및 관련 데이터 삭제 요청이 완료되었습니다.<br />
            보안 및 확인 절차를 거쳐 <strong>영업일 기준 2~3일 이내</strong>에 데이터가 안전하게 파기됩니다.
          </p>
        </div>
      )}
    </main>
  );
}
