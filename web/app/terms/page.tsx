export const metadata = {
  title: "Terms of Service — Athens",
  description: "Terms of Service for the Athens music rating application",
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

export default function TermsOfService() {
  return (
    <main
      style={{
        width: "100%",
        maxWidth: 680,
        margin: "0 auto",
        padding: "88px 24px 96px",
      }}
    >
      <h1 style={{ fontSize: 28, fontWeight: 700 }}>Terms of Service</h1>
      <p style={{ ...pStyle, marginTop: 8 }}>Last Updated: June 16, 2026</p>

      <p style={{ ...pStyle, marginTop: 24 }}>
        By using Athens (&ldquo;the Service&rdquo;), you agree to the following terms. Please read them carefully.
      </p>

      <section style={sectionStyle}>
        <h2 style={h2Style}>1. Acceptance of Terms</h2>
        <p style={pStyle}>
          Access to and use of the Service is conditioned on your acceptance of and compliance with these Terms.
          These Terms apply to all visitors, users, and others who access or use the Service.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>2. Description of Service</h2>
        <p style={pStyle}>
          Athens is a free, open-source music rating and discovery application. It allows users to
          rate tracks, albums, and artists through pairwise comparisons, build personal ranked lists,
          and share their music taste. The source code is available under the MIT License at{" "}
          <a href="https://github.com/junnnnnw00/athens" style={{ color: "inherit" }}>
            github.com/junnnnnw00/athens
          </a>
          .
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>3. User Accounts</h2>
        <ul>
          <li style={liStyle}>You must provide a valid email address to create an account.</li>
          <li style={liStyle}>You are responsible for maintaining the security of your account credentials.</li>
          <li style={liStyle}>You must not use the Service for any unlawful purpose.</li>
          <li style={liStyle}>One person or entity may not maintain more than one free account.</li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>4. User Content</h2>
        <p style={pStyle}>
          You retain ownership of all content you submit (ratings, reviews, profile information).
          By submitting content, you grant Athens a non-exclusive, worldwide license to store,
          display, and distribute your content solely for the purpose of operating the Service.
          You may delete your content at any time by deleting your account.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>5. Prohibited Uses</h2>
        <ul>
          <li style={liStyle}>Scraping, crawling, or automated data extraction</li>
          <li style={liStyle}>Attempting to interfere with or disrupt the Service</li>
          <li style={liStyle}>Creating fake accounts or manipulating ratings</li>
          <li style={liStyle}>Uploading malicious or illegal content</li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>6. Third-Party Services</h2>
        <p style={pStyle}>
          The Service integrates with third-party platforms including Supabase (authentication &amp;
          database), Last.fm, MusicBrainz, Spotify (catalog search only, server-side), and iTunes.
          Your use of those services is governed by their respective terms and privacy policies.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>7. Disclaimers</h2>
        <p style={pStyle}>
          The Service is provided &ldquo;as is&rdquo; without warranties of any kind, either express or implied.
          Athens does not warrant that the Service will be uninterrupted, error-free, or free of
          harmful components. Music metadata is sourced from third parties and may be incomplete or
          inaccurate.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>8. Limitation of Liability</h2>
        <p style={pStyle}>
          To the maximum extent permitted by applicable law, Athens shall not be liable for any
          indirect, incidental, special, consequential, or punitive damages arising out of or
          related to your use of the Service.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>9. Account Termination</h2>
        <p style={pStyle}>
          You may delete your account at any time from within the app (Settings → Delete Account),
          which permanently removes all associated data. We reserve the right to suspend or
          terminate accounts that violate these Terms.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>10. Changes to Terms</h2>
        <p style={pStyle}>
          We may update these Terms from time to time. Continued use of the Service after changes
          constitutes acceptance of the new Terms. We will update the &ldquo;Last Updated&rdquo; date above
          when changes are made.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>11. Contact</h2>
        <p style={pStyle}>
          Questions about these Terms:{" "}
          <a href="mailto:godjunwoo2006@gmail.com" style={{ color: "inherit" }}>
            godjunwoo2006@gmail.com
          </a>
        </p>
      </section>
    </main>
  );
}
