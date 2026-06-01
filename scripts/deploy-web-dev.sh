#!/usr/bin/env bash
# scripts/deploy-web-dev.sh — Athens dev web deploy
#
# Usage: ./scripts/deploy-web-dev.sh
#
# Pipeline:
#   1. flutter build web with config/app_config_dev.json
#   2. copy bundle → web/public/app/
#   3. vercel deploy (Preview deploy, no --prod)
#

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/app"
WEB="$ROOT/web"

echo "══════════════════════════════════════════"
echo "  Athens — Web Deploy (Development/Preview)"
echo "══════════════════════════════════════════"

# ── 1. Fresh Flutter web build ──────────────────────────────────────────────
echo ""
echo "▶  1/3  Building Flutter web bundle with dev config..."
cd "$APP"
flutter build web --base-href /app/ --dart-define-from-file=config/app_config_dev.json
echo "✅  Flutter build complete"

# ── 2. Copy bundle to Next.js public dir ────────────────────────────────────
echo ""
echo "▶  2/3  Copying bundle → web/public/app/"
rm -rf "$WEB/public/app"
mkdir -p "$WEB/public/app"
cp -R "$APP/build/web/." "$WEB/public/app/"
echo "✅  Bundle copied ($(date '+%H:%M:%S'))"

# ── 3. Vercel deploy and capture Preview URL ────────────────────────────────
echo ""
echo "▶  3/3  Deploying to Vercel (Preview)..."
cd "$WEB"

# Deploy as a preview build (without --prod)
DEPLOY_LOG=$(vercel deploy 2>&1)
echo "$DEPLOY_LOG"

CANONICAL=$(echo "$DEPLOY_LOG" | grep -o 'https://[^ ]*vercel.app' | head -1)

echo ""
echo "══════════════════════════════════════════"
echo "  🎉  Dev Deploy complete!"
echo "  📦  Preview URL: $CANONICAL"
echo "  ⏱   $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════"
echo ""
