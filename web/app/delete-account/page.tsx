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
        throw new Error('Invalid email or password.');
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
      setError(err.message || 'An error occurred while processing your request. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main style={containerStyle}>
      {!success ? (
        <div style={cardStyle}>
          <h1 style={titleStyle}>Account & Data Deletion Request</h1>
          <p style={subtitleStyle}>
            Please enter your registered email and password to verify your identity.
          </p>

          <h2 style={sectionTitleStyle}>Scope of data to be deleted:</h2>
          <ul style={listStyle}>
            <li>Login credentials (email & authentication data)</li>
            <li>All ratings (tracks/albums/artists) and pairwise duel history</li>
            <li>Public profile details and taste statistics report</li>
            <li>Linked Last.fm account connection details</li>
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
            ⚠️ <strong>Warning:</strong> Once account and data deletion is complete, it cannot be restored.
          </div>

          <form onSubmit={handleSubmit}>
            <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 8, color: '#e4e4e7' }}>
              Registered Email Address
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
              Password
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
              {loading ? 'Submitting request...' : 'Request Account & Data Deletion'}
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
          <h1 style={titleStyle}>Request Submitted</h1>
          <p style={{ ...subtitleStyle, marginBottom: 0, marginTop: 8 }}>
            Your request to delete the account and associated data for <strong>{email}</strong> has been received.<br />
            After verification, all data will be permanently destroyed <strong>within 2–3 business days</strong>.
          </p>
        </div>
      )}
    </main>
  );
}
