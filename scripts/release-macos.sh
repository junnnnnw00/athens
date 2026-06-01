#!/usr/bin/env bash
# scripts/release-macos.sh
# Usage: ./scripts/release-macos.sh 1.3.0
# Bumps version (optional, if needed), builds release macOS app, zips it.

set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>  e.g.  $0 1.3.0"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
ZIP_PATH="$REPO_ROOT/athens-macos.zip"

echo "🔨  Building release macOS App…"
cd "$APP_DIR"
flutter build macos --release --dart-define-from-file=config/app_config.json

echo "📦  Zipping Athens.app → $ZIP_PATH"
cd "$APP_DIR/build/macos/Build/Products/Release"
rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" Athens.app

echo "✅  macOS Zip ready: $ZIP_PATH"
