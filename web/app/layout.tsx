import type { Metadata } from "next";
import { Hanken_Grotesk, Geist_Mono } from "next/font/google";
import "./globals.css";

// Display + UI per DESIGN.md (clean grotesque, avoids generic Inter feel).
// Korean glyphs fall back to Pretendard (loaded via globals.css @import).
const hanken = Hanken_Grotesk({
  variable: "--font-hanken",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://athens.vercel.app"),
  title: "Athens — Rate your music",
  description: "Pairwise music rating. Discover your taste.",
  openGraph: {
    title: "Athens — Rate your music",
    description: "Pairwise music rating. Discover your taste.",
    url: "https://athens.vercel.app",
    siteName: "Athens",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className={`${hanken.variable} ${geistMono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
