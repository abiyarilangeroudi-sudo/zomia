#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
PUBSPEC="$FRONTEND_DIR/pubspec.yaml"

version_line="$(grep '^version:' "$PUBSPEC" | awk '{print $2}')"
version_name="${version_line%%+*}"
version_build="${version_line##*+}"

if [[ -z "$version_name" || -z "$version_build" || "$version_name" == "$version_build" ]]; then
  echo "Could not read frontend version from $PUBSPEC" >&2
  exit 1
fi

cd "$FRONTEND_DIR"

flutter build web \
  --base-href / \
  --pwa-strategy=none \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=APP_VERSION_NAME="$version_name" \
  --dart-define=APP_VERSION_BUILD="$version_build"

cp "$ROOT_DIR/scripts/assets/clear_local_web_cache.html" \
  "$FRONTEND_DIR/build/web/clear-local-cache.html"

echo "Built local Zomia webapp $version_name ($version_build) for http://127.0.0.1:8080/."
