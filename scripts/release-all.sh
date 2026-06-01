#!/usr/bin/env bash
# scripts/release-all.sh
# Usage: ./scripts/release-all.sh 1.3.0
# Runs checks, builds Android and macOS in release mode, deploys Web, creates/updates GH Release.

set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>  e.g.  $0 1.3.0"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
PUBSPEC="$APP_DIR/pubspec.yaml"

# ── 1. Check code quality ──────────────────────────────────────────────
echo "🔎  Running analyzer and tests..."
cd "$REPO_ROOT"
make analyze
make test

# ── 2. Bump version in pubspec.yaml ────────────────────────────────────
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
VERSION_CODE=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))
echo "🔖  Bumping version → $VERSION+$VERSION_CODE"
sed -i '' "s/^version: .*/version: $VERSION+$VERSION_CODE/" "$PUBSPEC"

# ── 3. Build Android release APK ───────────────────────────────────────
echo "🔨  Building Android release APK..."
cd "$APP_DIR"
flutter build apk --release --dart-define-from-file=config/app_config.json
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"

# ── 4. Build macOS release App ─────────────────────────────────────────
echo "🔨  Building macOS release App..."
flutter build macos --release --dart-define-from-file=config/app_config.json
ZIP_PATH="$REPO_ROOT/athens-macos.zip"
echo "📦  Zipping Athens.app → $ZIP_PATH"
cd "$APP_DIR/build/macos/Build/Products/Release"
rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" Athens.app

# ── 5. Deploy Web version ──────────────────────────────────────────────
echo "🔨  Deploying Web version to Vercel..."
cd "$REPO_ROOT"
make web-deploy

# ── 6. Commit + tag + push ─────────────────────────────────────────────
echo "💾  Committing and tagging version v$VERSION..."
git add "$PUBSPEC"
# Commit only if there are changes
if ! git diff --quiet "$PUBSPEC"; then
  git commit -m "chore(release): bump version to $VERSION"
fi

if ! git tag -l "v$VERSION" | grep -q "v$VERSION"; then
  git tag "v$VERSION"
  git push origin main --tags
else
  echo "⚠️  Tag v$VERSION already exists locally. Skipping tagging/pushing."
fi

# ── 7. Create/Update GitHub Release and upload assets ───────────────────
echo "🚀  Creating/Updating GitHub Release v$VERSION..."
if gh release view "v$VERSION" >/dev/null 2>&1; then
  echo "⚠️  Release v$VERSION already exists. Uploading assets with clobber..."
  gh release upload "v$VERSION" \
    "$APK_PATH#athens-$VERSION.apk" \
    "$ZIP_PATH#athens-macos.zip" \
    --clobber
else
  gh release create "v$VERSION" \
    "$APK_PATH#athens-$VERSION.apk" \
    "$ZIP_PATH#athens-macos.zip" \
    --title "Athens v$VERSION" \
    --generate-notes
fi

echo "🎉  Unified release v$VERSION completed successfully!"
