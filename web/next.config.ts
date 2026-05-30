import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    // The Flutter web app is shipped as static assets in `public/app/`.
    // It uses hash-based routing (`/app/#/home`), so only the entry path
    // needs mapping to the bundle's index.html; assets resolve directly.
    return [
      { source: "/app", destination: "/app/index.html" },
      { source: "/app/", destination: "/app/index.html" },
    ];
  },
};

export default nextConfig;
