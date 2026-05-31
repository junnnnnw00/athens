#!/usr/bin/env bash
# release-android.sh
# Usage: ./release-android.sh 1.2.0
# Bumps version, builds signed APK, creates a GitHub Release, uploads APK.
# Requires: gh CLI (brew install gh), flutter, java 17 in PATH

set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>  e.g.  $0 1.2.0"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$REPO_ROOT/app"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
PUBSPEC="$APP_DIR/pubspec.yaml"

# --- 1. Bump version in pubspec.yaml ---
# Compute an integer versionCode from "MAJOR*10000 + MINOR*100 + PATCH"
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
VERSION_CODE=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))

echo "🔖  Bumping version → $VERSION+$VERSION_CODE"
sed -i '' "s/^version: .*/version: $VERSION+$VERSION_CODE/" "$PUBSPEC"

# --- 2. Build signed release APK ---
echo "🔨  Building release APK…"
cd "$APP_DIR"
flutter build apk --release --dart-define-from-file=config/app_config.json

echo "✅  APK: $APK_PATH"

# --- 3. Commit + tag ---
cd "$REPO_ROOT"
git add "$PUBSPEC"
git commit -m "chore(release): bump version to $VERSION"
git tag "v$VERSION"
git push origin main --tags

# --- 4. Create GitHub Release and upload APK ---
echo "🚀  Creating GitHub Release v${VERSION}..."
gh release create "v${VERSION}" \
  "${APK_PATH}#athens-${VERSION}.apk" \
  --title "Athens v${VERSION}" \
  --generate-notes

echo "🎉  Done! APK published at: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v${VERSION}"
