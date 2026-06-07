export const metadata = {
  title: "Privacy Policy — Athens",
  description: "Guidelines on personal data collection and usage in the Athens application",
};

const sectionStyle: React.CSSProperties = {
  marginTop: 32,
};

const h2Style: React.CSSProperties = {
  fontSize: 18,
  fontWeight: 600,
  marginBottom: 8,
};

const pStyle: React.CSSProperties = {
  fontSize: 15,
  lineHeight: 1.7,
  opacity: 0.85,
};

const liStyle: React.CSSProperties = {
  fontSize: 15,
  lineHeight: 1.7,
  opacity: 0.85,
  marginBottom: 4,
};

export default function PrivacyPolicy() {
  return (
    <main
      style={{
        width: "100%",
        maxWidth: 680,
        margin: "0 auto",
        padding: "88px 24px 96px",
      }}
    >
      <h1 style={{ fontSize: 28, fontWeight: 700 }}>Privacy Policy</h1>
      <p style={{ ...pStyle, marginTop: 8 }}>Last Updated: June 3, 2026</p>

      <p style={{ ...pStyle, marginTop: 24 }}>
        Athens (&ldquo;the Service&rdquo;) values your privacy and complies with relevant data protection regulations. This policy outlines what data we collect and how we use it.
      </p>

      <section style={sectionStyle}>
        <h2 style={h2Style}>1. Collected Information</h2>
        <ul>
          <li style={liStyle}>
            <strong>Account Credentials:</strong> Email address for authentication (handled securely via Supabase Auth).
          </li>
          <li style={liStyle}>
            <strong>Rating Data:</strong> User-created music ratings, pairwise duel history, and analyzed genre/mood preferences.
          </li>
          <li style={liStyle}>
            <strong>Last.fm Sync Data (Optional):</strong> Last.fm username and recent listening history, accessed only if you choose to link your account.
          </li>
          <li style={liStyle}>
            <strong>Profile Info (Optional):</strong> Handle and display name used to generate your public profile.
          </li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>2. How We Use Information</h2>
        <ul>
          <li style={liStyle}>Providing services and user authentication</li>
          <li style={liStyle}>Generating personal music rankings and taste insights</li>
          <li style={liStyle}>Synchronizing your data across devices</li>
          <li style={liStyle}>Displaying your public profile if chosen</li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>3. Third-Party Services</h2>
        <p style={pStyle}>
          The Service utilizes the following external services: Supabase (authentication & database), Last.fm & MusicBrainz (music metadata proxies). Each service operates under its own privacy guidelines. We do NOT sell user data to third parties for advertising purposes.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>4. Data Retention & Deletion</h2>
        <p style={pStyle}>
          Your data is stored for as long as your account is active. If you wish to delete your account and all associated records permanently, you can do so in-app or via our
          {" "}
          <a href="/delete-account" style={{ color: "inherit", textDecoration: "underline" }}>
            Account Deletion Page
          </a>
          . You may also contact us via email to request immediate deletion.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>5. Security</h2>
        <p style={pStyle}>
          All communications are encrypted (HTTPS), and authentication tokens are kept in secure local device storage. Server API keys reside solely in cloud edge functions and are never bundled in the app.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>6. Contact</h2>
        <p style={pStyle}>
          Privacy inquiries:{" "}
          <a href="mailto:godjunwoo2006@gmail.com" style={{ color: "inherit" }}>
            godjunwoo2006@gmail.com
          </a>
        </p>
      </section>
    </main>
  );
}
