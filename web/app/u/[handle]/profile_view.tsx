'use client';

import { useState } from 'react';

export interface TopItem {
  id: string;
  kind: string;
  title: string;
  primary_artist: string | null;
  image_url: string | null;
  score: number;
  comparisons: number;
  tags: { name: string; source: string }[];
  updated_at: string;
}

export interface TagPreference {
  name: string;
  avg_score: number;
  count: number;
}

export interface ProfileStats {
  total_rated: number;
  avg_score: number;
  total_comparisons: number;
  distribution?: Record<string, number>;
  tag_preferences?: TagPreference[];
}

const MOOD_KEYWORDS = new Set([
  'melancholic', 'melancholy', 'dreamy', 'energetic', 'calm', 'dark', 'uplifting',
  'romantic', 'aggressive', 'peaceful', 'sad', 'happy', 'intense',
  'relaxing', 'atmospheric', 'emotional', 'powerful', 'mellow', 'epic',
  'haunting', 'nostalgic', 'mysterious', 'cathartic'
]);

function isMoodTag(name: string): boolean {
  return MOOD_KEYWORDS.has(name.toLowerCase());
}

function capitalize(s: string): string {
  if (!s) return s;
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export interface PublicProfile {
  id: string;
  handle: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  created_at: string;
  top_items: TopItem[];
  stats: ProfileStats;
}

interface ProfileViewProps {
  profile: PublicProfile;
  initials: string;
}

function getScoreColor(score: number): string {
  const t = Math.min(Math.max(score / 10.0, 0.0), 1.0);
  const low = [229, 96, 77];
  const mid = [227, 179, 65];
  const high = [86, 208, 141];

  let r, g, b;
  if (t < 0.5) {
    const factor = t / 0.5;
    r = Math.round(low[0] + (mid[0] - low[0]) * factor);
    g = Math.round(low[1] + (mid[1] - low[1]) * factor);
    b = Math.round(low[2] + (mid[2] - low[2]) * factor);
  } else {
    const factor = (t - 0.5) / 0.5;
    r = Math.round(mid[0] + (high[0] - mid[0]) * factor);
    g = Math.round(mid[1] + (high[1] - mid[1]) * factor);
    b = Math.round(mid[2] + (high[2] - mid[2]) * factor);
  }
  return `rgb(${r}, ${g}, ${b})`;
}

function ScoreRing({ score, size = 44 }: { score: number; size?: number }) {
  const fraction = Math.min(Math.max(score / 10, 0), 1);
  const color = getScoreColor(score);
  const radius = 18;
  const strokeWidth = 3.5;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - fraction * circumference;

  return (
    <div style={{
      position: 'relative',
      width: size,
      height: size,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <svg width={size} height={size} viewBox="0 0 44 44" style={{ transform: 'rotate(-90deg)' }}>
        {/* Track circle */}
        <circle
          cx="22"
          cy="22"
          r={radius}
          fill="transparent"
          stroke="var(--line)"
          strokeWidth={strokeWidth}
        />
        {/* Progress circle */}
        <circle
          cx="22"
          cy="22"
          r={radius}
          fill="transparent"
          stroke={color}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          style={{ transition: 'stroke-dashoffset 0.5s ease' }}
        />
      </svg>
      <span style={{
        position: 'absolute',
        fontSize: size * 0.28,
        fontWeight: 800,
        color: color,
        fontVariantNumeric: 'tabular-nums',
      }}>
        {score.toFixed(1)}
      </span>
    </div>
  );
}

export default function ProfileView({ profile, initials }: ProfileViewProps) {
  const [viewMode, setViewMode] = useState<'list' | 'cover'>('list');
  const [sortBy, setSortBy] = useState<'score' | 'latest'>('score');
  const [activeTab, setActiveTab] = useState<'distribution' | 'genres' | 'moods'>('distribution');

  const tagPreferences = profile.stats?.tag_preferences ?? [];

  // Filter out tags with count < 2 if there are tags with count >= 2 to avoid single-item tags crowding out preferences.
  // Fall back to count >= 1 if no multiple-item tags exist.
  const hasMultipleGenre = tagPreferences.some(p => !isMoodTag(p.name) && p.count >= 2);
  const genrePreferences = tagPreferences
    .filter(p => !isMoodTag(p.name) && (hasMultipleGenre ? p.count >= 2 : p.count >= 1))
    .map(p => ({
      name: capitalize(p.name),
      avg_score: p.avg_score,
      count: p.count,
    }))
    .slice(0, 5);

  const hasMultipleMood = tagPreferences.some(p => isMoodTag(p.name) && p.count >= 2);
  const moodPreferences = tagPreferences
    .filter(p => isMoodTag(p.name) && (hasMultipleMood ? p.count >= 2 : p.count >= 1))
    .map(p => ({
      name: capitalize(p.name),
      avg_score: p.avg_score,
      count: p.count,
    }))
    .slice(0, 5);

  // Sort top items in memory
  const sortedItems = [...profile.top_items].sort((a, b) => {
    if (sortBy === 'score') {
      return b.score - a.score;
    } else {
      return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime();
    }
  });

  return (
    <main style={{
      position: 'relative',
      zIndex: 1,
      width: '100%',
      maxWidth: 600,
      margin: '0 auto',
      padding: '56px 20px 80px',
    }}>
      {/* Profile Header */}
      <header style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        textAlign: 'center',
        marginBottom: 40,
      }}>
        {/* Avatar Ring */}
        <div style={{
          position: 'relative',
          width: 104,
          height: 104,
          borderRadius: '50%',
          padding: 4,
          background: 'var(--line)',
          boxShadow: '0 8px 30px var(--shadow)',
          marginBottom: 20,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}>
          {profile.avatar_url ? (
            <img
              src={profile.avatar_url}
              alt={profile.display_name ?? profile.handle}
              width={96}
              height={96}
              style={{
                borderRadius: '50%',
                objectFit: 'cover',
                width: '100%',
                height: '100%',
              }}
            />
          ) : (
            <div style={{
              width: '100%',
              height: '100%',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, var(--accent) 0%, var(--accent-soft) 100%)',
              color: '#1E3A2C',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 32,
              fontWeight: 700,
              letterSpacing: '-0.05em',
            }}>
              {initials}
            </div>
          )}
        </div>

          <h1 style={{
            margin: 0,
            fontSize: 32,
            fontWeight: 800,
            letterSpacing: '-0.03em',
            color: 'var(--text)',
          }}>
            {profile.display_name ?? profile.handle}
          </h1>
          <p style={{
            margin: '4px 0 0',
            fontSize: 15,
            color: 'var(--muted)',
            fontWeight: 500,
          }}>
            @{profile.handle}
          </p>

          {profile.bio && (
            <p style={{
              marginTop: 16,
              fontSize: 15,
              lineHeight: 1.6,
              color: 'var(--muted)',
              maxWidth: 440,
            }}>
              {profile.bio}
            </p>
          )}

          {/* Stats Grid */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(2, 1fr)',
            gap: 12,
            width: '100%',
            marginTop: 32,
          }}>
            <div style={{
              background: 'var(--surface)',
              border: '1px solid var(--line)',
              borderRadius: 16,
              padding: '16px 8px',
            }}>
              <div style={{ fontSize: 20, fontWeight: 800, color: 'var(--text)' }}>
                {profile.stats?.total_rated ?? 0}개
              </div>
              <div style={{
                fontSize: 10,
                fontWeight: 700,
                color: 'var(--muted)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                marginTop: 4,
              }}>
                평가한 항목
              </div>
            </div>

            <div style={{
              background: 'var(--surface)',
              border: '1px solid var(--line)',
              borderRadius: 16,
              padding: '16px 8px',
            }}>
              <div style={{ fontSize: 20, fontWeight: 800, color: 'var(--text)' }}>
                {profile.stats?.total_comparisons ?? 0}개
              </div>
              <div style={{
                fontSize: 10,
                fontWeight: 700,
                color: 'var(--muted)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                marginTop: 4,
              }}>
                비교 횟수
              </div>
            </div>
          </div>
      </header>

      {/* Statistics Section with Toggle Tabs */}
      <section style={{
        background: 'var(--surface)',
        border: '1px solid var(--line)',
        borderRadius: 20,
        padding: '20px 24px',
        marginBottom: 32,
        boxShadow: '0 4px 20px var(--shadow)',
      }}>
        {/* Toggle Tabs Header */}
        <div style={{
          display: 'flex',
          borderBottom: '1px solid var(--line)',
          marginBottom: 20,
          gap: 16,
        }}>
          {[
            { id: 'distribution', label: '점수 분포' },
            { id: 'genres', label: '장르 선호도' },
            { id: 'moods', label: '분위기 선호도' }
          ].map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                style={{
                  background: 'none',
                  border: 'none',
                  borderBottom: isActive ? '2px solid var(--accent)' : '2px solid transparent',
                  color: isActive ? 'var(--text)' : 'var(--muted)',
                  padding: '8px 4px 12px',
                  fontSize: 14,
                  fontWeight: 700,
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  marginBottom: -1,
                }}
              >
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Tab Content */}
        {activeTab === 'distribution' && profile.stats?.distribution && (
          <div style={{
            display: 'flex',
            alignItems: 'flex-end',
            justifyContent: 'space-between',
            height: 100,
            paddingTop: 8,
            gap: 6,
          }}>
            {Array.from({ length: 10 }).map((_, idx) => {
              const count = profile.stats.distribution?.[idx.toString()] ?? 0;
              const maxCount = Math.max(...Object.values(profile.stats.distribution ?? {}).map(Number), 1);
              const heightPercent = (count / maxCount) * 100;
              const barColor = getScoreColor(idx + 0.5);

              return (
                <div
                  key={idx}
                  style={{
                    flex: 1,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: 6,
                    height: '100%',
                    justifyContent: 'flex-end',
                  }}
                >
                  <span style={{
                    fontSize: 9,
                    fontWeight: 700,
                    color: count > 0 ? 'var(--text)' : 'transparent',
                    fontVariantNumeric: 'tabular-nums',
                    marginBottom: -4,
                  }}>
                    {count}
                  </span>

                  <div style={{
                    width: '100%',
                    height: `${Math.max(heightPercent, 3)}%`,
                    background: count > 0 ? barColor : 'var(--line)',
                    opacity: count > 0 ? 0.85 : 0.4,
                    borderRadius: '4px 4px 0 0',
                    transition: 'all 0.3s ease',
                  }}
                  title={`${idx}-${idx + 1}점: ${count}개`}
                  />

                  <span style={{
                    fontSize: 10,
                    fontWeight: 600,
                    color: 'var(--muted)',
                  }}>
                    {idx}
                  </span>
                </div>
              );
            })}
          </div>
        )}

        {activeTab === 'genres' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {genrePreferences.length > 0 ? (
              genrePreferences.map((pref) => {
                const scoreString = pref.avg_score.toFixed(1);
                const progressWidth = `${(pref.avg_score / 10) * 100}%`;
                const barColor = getScoreColor(pref.avg_score);

                return (
                  <div key={pref.name} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{
                      width: 100,
                      fontSize: 14,
                      fontWeight: 600,
                      color: 'var(--text)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}>
                      {pref.name}
                    </div>
                    <div style={{
                      flex: 1,
                      height: 8,
                      background: 'var(--line)',
                      borderRadius: 4,
                      overflow: 'hidden',
                      position: 'relative',
                    }}>
                      <div style={{
                        position: 'absolute',
                        left: 0,
                        top: 0,
                        height: '100%',
                        width: progressWidth,
                        background: barColor,
                        borderRadius: 4,
                      }} />
                    </div>
                    <div style={{
                      width: 110,
                      fontSize: 12,
                      fontWeight: 500,
                      color: 'var(--muted)',
                      textAlign: 'right',
                    }}>
                      {scoreString}점 ({pref.count}개)
                    </div>
                  </div>
                );
              })
            ) : (
              <div style={{
                height: 100,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--muted)',
                fontSize: 14,
              }}>
                충분한 비교 데이터가 없습니다.
              </div>
            )}
          </div>
        )}

        {activeTab === 'moods' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {moodPreferences.length > 0 ? (
              moodPreferences.map((pref) => {
                const scoreString = pref.avg_score.toFixed(1);
                const progressWidth = `${(pref.avg_score / 10) * 100}%`;
                const barColor = getScoreColor(pref.avg_score);

                return (
                  <div key={pref.name} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{
                      width: 100,
                      fontSize: 14,
                      fontWeight: 600,
                      color: 'var(--text)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}>
                      {pref.name}
                    </div>
                    <div style={{
                      flex: 1,
                      height: 8,
                      background: 'var(--line)',
                      borderRadius: 4,
                      overflow: 'hidden',
                      position: 'relative',
                    }}>
                      <div style={{
                        position: 'absolute',
                        left: 0,
                        top: 0,
                        height: '100%',
                        width: progressWidth,
                        background: barColor,
                        borderRadius: 4,
                      }} />
                    </div>
                    <div style={{
                      width: 110,
                      fontSize: 12,
                      fontWeight: 500,
                      color: 'var(--muted)',
                      textAlign: 'right',
                    }}>
                      {scoreString}점 ({pref.count}개)
                    </div>
                  </div>
                );
              })
            ) : (
              <div style={{
                height: 100,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--muted)',
                fontSize: 14,
              }}>
                충분한 비교 데이터가 없습니다.
              </div>
            )}
          </div>
        )}
      </section>

      {/* Control Panel (Sort & View Mode Toggles) */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 24,
        gap: 12,
        flexWrap: 'wrap',
      }}>
        {/* Sort Toggles */}
        <div style={{
          display: 'flex',
          background: 'var(--surface)',
          border: '1px solid var(--line)',
          borderRadius: 12,
          padding: 3,
        }}>
          <button
            onClick={() => setSortBy('score')}
            style={{
              background: sortBy === 'score' ? 'var(--chip)' : 'transparent',
              color: sortBy === 'score' ? 'var(--text)' : 'var(--muted)',
              border: 'none',
              padding: '6px 12px',
              borderRadius: 9,
              fontSize: 13,
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            점수순
          </button>
          <button
            onClick={() => setSortBy('latest')}
            style={{
              background: sortBy === 'latest' ? 'var(--chip)' : 'transparent',
              color: sortBy === 'latest' ? 'var(--text)' : 'var(--muted)',
              border: 'none',
              padding: '6px 12px',
              borderRadius: 9,
              fontSize: 13,
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            최신순
          </button>
        </div>

        {/* View Mode Toggles */}
        <div style={{
          display: 'flex',
          background: 'var(--surface)',
          border: '1px solid var(--line)',
          borderRadius: 12,
          padding: 3,
        }}>
          <button
            onClick={() => setViewMode('list')}
            style={{
              background: viewMode === 'list' ? 'var(--chip)' : 'transparent',
              color: viewMode === 'list' ? 'var(--text)' : 'var(--muted)',
              border: 'none',
              padding: '6px 12px',
              borderRadius: 9,
              fontSize: 13,
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            리스트
          </button>
          <button
            onClick={() => setViewMode('cover')}
            style={{
              background: viewMode === 'cover' ? 'var(--chip)' : 'transparent',
              color: viewMode === 'cover' ? 'var(--text)' : 'var(--muted)',
              border: 'none',
              padding: '6px 12px',
              borderRadius: 9,
              fontSize: 13,
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            커버 뷰
          </button>
        </div>
      </div>

      {/* List/Cover Content */}
      {sortedItems.length > 0 && (
        <section>
          {viewMode === 'list' ? (
            /* List View Layout */
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {sortedItems.map((item, i) => {
                const originalRank = profile.top_items.findIndex(it => it.id === item.id);
                const rankColor = originalRank === 0
                  ? '#D4AF37' // Gold
                  : originalRank === 1
                  ? '#C0C0C0' // Silver
                  : originalRank === 2
                  ? '#CD7F32' // Bronze
                  : 'var(--faint)';

                return (
                  <div
                    key={item.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 16,
                      padding: '12px 16px',
                      background: 'var(--surface)',
                      border: '1px solid var(--line)',
                      borderRadius: 16,
                      boxShadow: '0 2px 8px var(--shadow)',
                      transition: 'all 0.2s ease',
                    }}
                  >
                    {/* Rank Badge */}
                    <div style={{
                      minWidth: 28,
                      height: 28,
                      borderRadius: '50%',
                      background: originalRank < 3 && originalRank >= 0 ? `${rankColor}15` : 'transparent',
                      color: rankColor,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 800,
                      fontSize: originalRank < 3 && originalRank >= 0 ? 14 : 15,
                    }}>
                      {originalRank >= 0 ? originalRank + 1 : '-'}
                    </div>

                    {/* Album Art Cover */}
                    {item.image_url ? (
                      <img
                        src={item.image_url}
                        alt={item.title}
                        width={56}
                        height={56}
                        style={{
                          borderRadius: 8,
                          objectFit: 'cover',
                          boxShadow: '0 4px 12px var(--shadow)',
                        }}
                      />
                    ) : (
                      <div style={{
                        width: 56,
                        height: 56,
                        borderRadius: 8,
                        background: 'var(--line)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 14,
                        fontWeight: 700,
                        color: 'var(--faint)',
                        boxShadow: '0 4px 12px var(--shadow)',
                      }}>
                        {item.title.substring(0, 1).toUpperCase()}
                      </div>
                    )}

                    {/* Meta info */}
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{
                        fontWeight: 700,
                        fontSize: 15,
                        color: 'var(--text)',
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}>
                        {item.title}
                      </div>
                      {item.primary_artist && (
                        <div style={{
                          color: 'var(--muted)',
                          fontSize: 13,
                          marginTop: 2,
                          fontWeight: 500,
                          whiteSpace: 'nowrap',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                        }}>
                          {item.primary_artist}
                        </div>
                      )}
                      {item.tags && item.tags.length > 0 && (
                        <div style={{
                          marginTop: 6,
                          display: 'flex',
                          flexWrap: 'wrap',
                          gap: 4,
                        }}>
                          {item.tags.slice(0, 2).map((tag) => (
                            <span
                              key={tag.name}
                              style={{
                                background: 'var(--chip)',
                                borderRadius: 6,
                                padding: '2px 8px',
                                fontSize: 10,
                                fontWeight: 600,
                                color: 'var(--muted)',
                                border: '1px solid var(--line)',
                              }}
                            >
                              {tag.name}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* SVG ScoreRing */}
                    <ScoreRing score={item.score} size={44} />
                  </div>
                );
              })}
            </div>
          ) : (
            /* Cover View Grid Layout */
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))',
              gap: 16,
            }}>
              {sortedItems.map((item) => {
                const originalRank = profile.top_items.findIndex(it => it.id === item.id);
                const rankColor = originalRank === 0
                  ? '#D4AF37' // Gold
                  : originalRank === 1
                  ? '#C0C0C0' // Silver
                  : originalRank === 2
                  ? '#CD7F32' // Bronze
                  : null;

                return (
                  <div
                    key={item.id}
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      background: 'var(--surface)',
                      border: '1px solid var(--line)',
                      borderRadius: 16,
                      boxShadow: '0 2px 8px var(--shadow)',
                      overflow: 'hidden',
                      position: 'relative',
                    }}
                  >
                    {/* Square Image container with absolute overlays */}
                    <div style={{ position: 'relative', width: '100%', aspectRatio: '1/1' }}>
                      {item.image_url ? (
                        <img
                          src={item.image_url}
                          alt={item.title}
                          style={{
                            width: '100%',
                            height: '100%',
                            objectFit: 'cover',
                          }}
                        />
                      ) : (
                        <div style={{
                          width: '100%',
                          height: '100%',
                          background: 'var(--line)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: 24,
                          fontWeight: 700,
                          color: 'var(--faint)',
                        }}>
                          {item.title.substring(0, 1).toUpperCase()}
                        </div>
                      )}

                      {/* Rank Overlay Badge (top-left) */}
                      {originalRank >= 0 && (
                        <div style={{
                          position: 'absolute',
                          top: 8,
                          left: 8,
                          width: 24,
                          height: 24,
                          borderRadius: '50%',
                          background: rankColor ? `${rankColor}` : 'rgba(0,0,0,0.6)',
                          color: rankColor ? '#171614' : '#ffffff',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 800,
                          fontSize: 12,
                          boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
                          border: rankColor ? 'none' : '1px solid rgba(255,255,255,0.2)',
                        }}>
                          {originalRank + 1}
                        </div>
                      )}

                      {/* ScoreRing Glassmorphism Overlay (bottom-right) */}
                      <div style={{
                        position: 'absolute',
                        bottom: 8,
                        right: 8,
                        background: 'rgba(0, 0, 0, 0.65)',
                        backdropFilter: 'blur(6px)',
                        borderRadius: '50%',
                        padding: 2,
                        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
                      }}>
                        <ScoreRing score={item.score} size={36} />
                      </div>
                    </div>

                    {/* Metadata Box */}
                    <div style={{ padding: '12px', flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                      <div style={{
                        fontWeight: 700,
                        fontSize: 14,
                        color: 'var(--text)',
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}>
                        {item.title}
                      </div>
                      <div style={{
                        color: 'var(--muted)',
                        fontSize: 12,
                        marginTop: 2,
                        fontWeight: 500,
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}>
                        {item.primary_artist}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      )}

      {/* Footer */}
      <footer style={{
        marginTop: 64,
        textAlign: 'center',
        fontSize: 13,
        fontWeight: 500,
      }}>
        <a
          href="/app"
          style={{
            color: 'var(--accent-text)',
            display: 'inline-flex',
            alignItems: 'center',
            gap: 4,
            transition: 'opacity 0.2s ease',
          }}
        >
          Athens에서 음악 평가 시작하기 →
        </a>
      </footer>
    </main>
  );
}
