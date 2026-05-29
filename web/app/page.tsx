export default function Home() {
  return (
    <main style={{ maxWidth: 640, margin: '0 auto', padding: '80px 16px', fontFamily: 'system-ui, sans-serif', textAlign: 'center' }}>
      <h1 style={{ fontSize: 48, fontWeight: 800, marginBottom: 8 }}>Athens</h1>
      <p style={{ color: '#555', fontSize: 20, marginBottom: 32 }}>
        Rate your music. Discover your taste.
      </p>
      <p style={{ color: '#888' }}>
        View a profile at <code>/u/[handle]</code>
      </p>
    </main>
  );
}
