import type { Metadata } from "next";
import { Hanken_Grotesk, Geist_Mono } from "next/font/google";
import KofiWidget from "./components/KofiWidget";
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
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://athens.vercel.app"),
  title: {
    default: "Athens — Athens Music Rating & App",
    template: "%s | Athens — Athens Music Rating & App",
  },
  description: "Pairwise music rating app. Discover your taste in Athens Music. 복잡한 별점 리뷰 없이 두 곡 중 더 끌리는 음악을 선택하여 나만의 Athens Music Rating 순위를 매겨보세요.",
  keywords: ["Athens", "Athens App", "Athens Music", "Music Rating", "음악 레이팅", "음악 추천", "Elo Rating", "음악 월드컵"],
  openGraph: {
    title: "Athens — Athens Music Rating & App",
    description: "Pairwise music rating app. Discover your taste in Athens Music. 복잡한 별점 리뷰 없이 두 곡 중 더 끌리는 음악을 선택하여 나만의 Athens Music Rating 순위를 매겨보세요.",
    url: "https://athens.vercel.app",
    siteName: "Athens Music Rating & App",
    type: "website",
  },
  verification: {
    google: process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION,
    other: {
      "naver-site-verification": process.env.NEXT_PUBLIC_NAVER_SITE_VERIFICATION || "",
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className={`${hanken.variable} ${geistMono.variable}`}>
      <body>
        {children}
        <KofiWidget />
      </body>
    </html>
  );
}
