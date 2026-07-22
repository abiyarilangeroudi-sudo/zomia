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
  --release \
  --base-href /webapp/ \
  --dart-define=API_BASE_URL=https://zomia.eu/api/v1 \
  --dart-define=APP_VERSION_NAME="$version_name" \
  --dart-define=APP_VERSION_BUILD="$version_build"

cd "$FRONTEND_DIR/build/web"

rm -f clear-local-cache.html .DS_Store
find . -name '._*' -delete

perl -0pi -e 's/\n?\/\/# sourceMappingURL=.*//g' \
  flutter_bootstrap.js flutter.js main.dart.js

if rg -n 'sourceMappingURL|flutter\.js\.map' . >/dev/null; then
  echo "Source map references remain in frontend/build/web." >&2
  exit 1
fi

echo "Built Zomia webapp $version_name ($version_build)."
