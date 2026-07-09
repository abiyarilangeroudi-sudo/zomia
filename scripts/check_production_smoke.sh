#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/frontend/pubspec.yaml"

BASE_URL="${BASE_URL:-https://zomia.eu}"
CACHE_BUSTER="${CACHE_BUSTER:-production-smoke-$(date +%Y%m%d%H%M%S)}"

version_line="$(grep '^version:' "$PUBSPEC" | awk '{print $2}')"
default_version_name="${version_line%%+*}"
default_version_build="${version_line##*+}"

EXPECTED_VERSION="${EXPECTED_VERSION:-$default_version_name}"
EXPECTED_BUILD="${EXPECTED_BUILD:-$default_version_build}"

if [[ -z "$EXPECTED_VERSION" || -z "$EXPECTED_BUILD" || "$EXPECTED_VERSION" == "$EXPECTED_BUILD" ]]; then
  echo "Could not determine expected webapp version from $PUBSPEC" >&2
  exit 1
fi

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "OK: $*"
}

http_status() {
  curl -sS -o /dev/null -w '%{http_code}' "$1"
}

expect_status() {
  local url="$1"
  local expected="$2"
  local actual
  actual="$(http_status "$url")"
  [[ "$actual" == "$expected" ]] || fail "$url returned $actual, expected $expected"
  pass "$url returned $expected"
}

health_json="$(curl -fsS "$BASE_URL/health")"
[[ "$health_json" == *'"status":"ok"'* ]] || fail "$BASE_URL/health returned unexpected body: $health_json"
pass "$BASE_URL/health returned status ok"

version_json="$(curl -fsS "$BASE_URL/webapp/version.json")"
[[ "$version_json" == *"\"version\":\"$EXPECTED_VERSION\""* ]] || fail "version.json did not contain version $EXPECTED_VERSION: $version_json"
[[ "$version_json" == *"\"build_number\":\"$EXPECTED_BUILD\""* ]] || fail "version.json did not contain build $EXPECTED_BUILD: $version_json"
pass "$BASE_URL/webapp/version.json returned $EXPECTED_VERSION ($EXPECTED_BUILD)"

expect_status "$BASE_URL/webapp/?v=$CACHE_BUSTER" "200"
expect_status "$BASE_URL/webapp/main.dart.js" "200"
expect_status "$BASE_URL/webapp/flutter.js.map" "404"

auth_status="$(http_status "$BASE_URL/api/v1/auth/me")"
[[ "$auth_status" == "401" ]] || fail "$BASE_URL/api/v1/auth/me returned $auth_status, expected 401"
pass "$BASE_URL/api/v1/auth/me returned 401 without token"

echo "Production smoke passed for $BASE_URL webapp $EXPECTED_VERSION ($EXPECTED_BUILD)."
