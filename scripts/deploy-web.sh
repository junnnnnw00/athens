#!/usr/bin/env bash
# scripts/deploy-web.sh — Athens web deploy
#
# Usage: ./scripts/deploy-web.sh
#
# Pipeline:
#   1. flutter build web  (fresh build, always)
#   2. copy bundle → web/public/app/
#   3. vercel deploy --prod  (upload + remote Next.js build)
#   4. re-pin athens.vercel.app + athens-sand.vercel.app to the new deployment
#
# This script is the single source of truth for web deployment.
# `make web-deploy` calls this script.

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/app"
WEB="$ROOT/web"
ALIASES=("athens.vercel.app" "athens-sand.vercel.app")

echo "══════════════════════════════════════════"
echo "  Athens — Web Deploy"
echo "══════════════════════════════════════════"

# ── 1. Fresh Flutter web build ──────────────────────────────────────────────
echo ""
echo "▶  1/3  Building Flutter web bundle..."
cd "$APP"
flutter build web --base-href /app/ --dart-define-from-file=config/app_config.json
echo "✅  Flutter build complete"

# ── 2. Copy bundle to Next.js public dir ────────────────────────────────────
echo ""
echo "▶  2/3  Copying bundle → web/public/app/"
rm -rf "$WEB/public/app"
mkdir -p "$WEB/public/app"
cp -R "$APP/build/web/." "$WEB/public/app/"
echo "✅  Bundle copied ($(date '+%H:%M:%S'))"

# ── 3. Vercel deploy and capture canonical URL ──────────────────────────────
echo ""
echo "▶  3/3  Deploying to Vercel (prod)..."
cd "$WEB"

# Capture deploy output; extract canonical prod URL from the line:
#   ▲ Production  https://athens-XXXX-junwoo-hong-s-projects.vercel.app
DEPLOY_LOG=$(vercel deploy --prod 2>&1)
echo "$DEPLOY_LOG"

CANONICAL=$(echo "$DEPLOY_LOG" | grep -E "^\s*(▲\s*)?Production\s+https://" | grep -o 'https://[^ ]*' | tail -1)

if [ -z "$CANONICAL" ]; then
  echo ""
  echo "⚠️  Could not auto-detect canonical URL from deploy output."
  echo "   Please run manually:  cd web && npx vercel alias ls"
  echo "   Then:  npx vercel alias set <canonical-url> athens.vercel.app"
  exit 1
fi

CANONICAL_HOST="${CANONICAL#https://}"

# ── 4. Re-pin aliases ────────────────────────────────────────────────────────
echo ""
echo "🔗  Pinning aliases → $CANONICAL_HOST"
for ALIAS in "${ALIASES[@]}"; do
  if vercel alias set "$CANONICAL_HOST" "$ALIAS" 2>/dev/null; then
    echo "   ✅  $ALIAS"
  else
    echo "   ⚠️  Failed to alias $ALIAS — set manually with:"
    echo "       cd web && npx vercel alias set $CANONICAL_HOST $ALIAS"
  fi
done

echo ""
echo "══════════════════════════════════════════"
echo "  🎉  Deploy complete!"
echo "  🌐  https://athens.vercel.app"
echo "  📦  $CANONICAL"
echo "  ⏱   $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════"
echo ""
echo "  브라우저에서 Cmd+Shift+R 로 hard-refresh 후 확인하세요."
echo ""
