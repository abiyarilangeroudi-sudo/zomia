#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="${ZOMIA_DEPLOY_HOST:-delopram@zomia.eu}"
REMOTE_RELEASE_ROOT="${ZOMIA_FRONTEND_RELEASE_ROOT:-/var/www/zomia/releases}"
REMOTE_WEBAPP_LINK="${ZOMIA_FRONTEND_LINK:-/var/www/zomia/webapp}"
MODE="${1:-deploy}"
CI_WAIT_SECONDS="${CI_WAIT_SECONDS:-600}"

tmp_root=""
source_dir=""
remote_archive=""
remote_helper=""
previous_target=""
release_path=""
activated=0
verified=0

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cleanup() {
  local status=$?
  trap - EXIT
  set +e

  if [[ "$status" -ne 0 && "$activated" -eq 1 && "$verified" -eq 0 && -n "$previous_target" ]]; then
    echo "Deployment failed after activation; rolling back to $previous_target" >&2
    ssh "$REMOTE_HOST" bash "$remote_helper" rollback "$previous_target" "$REMOTE_WEBAPP_LINK"
  fi

  [[ -z "$remote_archive" ]] || ssh "$REMOTE_HOST" rm -f "$remote_archive" >/dev/null 2>&1
  [[ -z "$remote_helper" ]] || ssh "$REMOTE_HOST" rm -f "$remote_helper" >/dev/null 2>&1
  if [[ -n "$source_dir" && -d "$source_dir" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$source_dir" >/dev/null 2>&1
  fi
  if [[ -n "$tmp_root" && -d "$tmp_root" ]]; then
    rm -rf "$tmp_root"
  fi

  exit "$status"
}
trap cleanup EXIT

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is missing: $1"
}

for command in git flutter rg tar scp ssh curl python3; do
  require_command "$command"
done

[[ "$MODE" == "deploy" || "$MODE" == "--check" ]] || fail "Use deploy or --check"
[[ "$(git -C "$ROOT_DIR" branch --show-current)" == "main" ]] || fail "Frontend production deploys must run from main"

commit="$(git -C "$ROOT_DIR" rev-parse HEAD)"
short_commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
remote_commit="$(git -C "$ROOT_DIR" ls-remote origin refs/heads/main | awk '{print $1}')"
[[ -n "$remote_commit" ]] || fail "Could not read origin/main"
[[ "$commit" == "$remote_commit" ]] || fail "HEAD is not pushed to origin/main"

version_line="$(git -C "$ROOT_DIR" show "$commit:frontend/pubspec.yaml" | awk '/^version:/ {print $2; exit}')"
version_name="${version_line%%+*}"
version_build="${version_line##*+}"
[[ -n "$version_name" && -n "$version_build" && "$version_name" != "$version_build" ]] || fail "Could not read frontend version"

subject="$(git -C "$ROOT_DIR" log -1 --format=%s "$commit")"
release_slug="$(printf '%s' "${RELEASE_SLUG:-$subject}" | tr '[:upper:] ' '[:lower:]_' | tr -cd 'a-z0-9_-' | cut -c1-36)"
[[ -n "$release_slug" ]] || release_slug="frontend"
release_id="${RELEASE_ID:-$(date +%Y%m%d%H%M%S)_${release_slug}_${short_commit}}"
release_path="$REMOTE_RELEASE_ROOT/$release_id"

echo "Commit: $commit"
echo "Version: $version_name ($version_build)"
echo "Release: $release_path"

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  echo "NOTE: the working tree is dirty; deployment still builds only committed $commit."
fi

if [[ "$MODE" == "--check" ]]; then
  echo "Frontend deployment preflight passed."
  exit 0
fi

production_version="$(curl -fsS https://zomia.eu/webapp/version.json)"
if [[ "${ALLOW_SAME_VERSION:-0}" != "1" && "$production_version" == *"\"version\":\"$version_name\""* && "$production_version" == *"\"build_number\":\"$version_build\""* ]]; then
  fail "Production already reports $version_name ($version_build); bump pubspec or set ALLOW_SAME_VERSION=1 for an intentional redeploy"
fi

if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
  deadline=$((SECONDS + CI_WAIT_SECONDS))
  while true; do
    ci_state="$(gh run list --commit "$commit" --limit 1 --json status,conclusion --jq '.[0] | "\(.status) \(.conclusion // \"\")"' 2>/dev/null || true)"
    if [[ "$ci_state" == "completed success" ]]; then
      echo "GitHub Actions: success"
      break
    fi
    [[ "$ci_state" != completed\ * ]] || fail "GitHub Actions did not pass: $ci_state"
    (( SECONDS < deadline )) || fail "Timed out waiting for GitHub Actions"
    echo "Waiting for GitHub Actions: ${ci_state:-not visible yet}"
    sleep 15
  done
else
  echo "NOTE: GitHub CLI is not authenticated; continuing with local checks and exact pushed commit."
fi

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/zomia-frontend-deploy.XXXXXX")"
source_dir="$tmp_root/source"
artifact="$tmp_root/zomia_frontend_${release_id}.tar.gz"
archive_name="$(basename "$artifact")"
remote_archive="/tmp/$archive_name"
remote_helper="/tmp/zomia_frontend_release_${short_commit}_$$.sh"

git -C "$ROOT_DIR" worktree add --detach "$source_dir" "$commit" >/dev/null

(
  cd "$source_dir/frontend"
  flutter analyze
  flutter test
)
"$source_dir/scripts/build_frontend_production.sh"

build_dir="$source_dir/frontend/build/web"
[[ -f "$build_dir/version.json" ]] || fail "Production build is missing version.json"
grep -q '<base href="/webapp/">' "$build_dir/index.html" || fail "Production base href is missing"
grep -q 'https://zomia.eu/api/v1' "$build_dir/main.dart.js" || fail "Production API base is missing"
[[ ! -e "$build_dir/clear-local-cache.html" ]] || fail "Local cache helper reached production build"
if find "$build_dir" \( -name '._*' -o -name '.DS_Store' \) -print -quit | grep -q .; then
  fail "macOS metadata reached production build"
fi
if rg -n 'sourceMappingURL=' "$build_dir" -g '*.js' >/dev/null; then
  fail "Source-map references reached production build"
fi
[[ -z "$(git -C "$source_dir" status --porcelain --untracked-files=no)" ]] || fail "Build modified tracked source files"

COPYFILE_DISABLE=1 tar --no-xattrs -czf "$artifact" -C "$build_dir" .
tar -tzf "$artifact" > "$tmp_root/archive-files.txt"
if rg '(^|/)\._|(^|/)\.DS_Store$' "$tmp_root/archive-files.txt" >/dev/null; then
  fail "macOS metadata reached deployment archive"
fi

scp "$artifact" "$REMOTE_HOST:$remote_archive"
scp "$source_dir/scripts/remote/frontend_release.sh" "$REMOTE_HOST:$remote_helper"

prepare_output="$(ssh "$REMOTE_HOST" bash "$remote_helper" prepare "$remote_archive" "$release_path" "$REMOTE_WEBAPP_LINK" "$version_name" "$version_build")"
echo "$prepare_output"
previous_target="$(printf '%s\n' "$prepare_output" | sed -n 's/^PREVIOUS=//p')"
[[ -n "$previous_target" ]] || fail "Remote prepare did not report a rollback target"

activated=1
ssh "$REMOTE_HOST" bash "$remote_helper" activate "$release_path" "$REMOTE_WEBAPP_LINK"

EXPECTED_VERSION="$version_name" \
EXPECTED_BUILD="$version_build" \
CACHE_BUSTER="production-smoke-$(date +%Y%m%d%H%M%S)" \
  "$source_dir/scripts/check_production_smoke.sh"

verified=1
ssh "$REMOTE_HOST" rm -f "$remote_archive" "$remote_helper"
remote_archive=""
remote_helper=""

echo "Frontend deployment completed."
echo "COMMIT=$commit"
echo "VERSION=$version_name ($version_build)"
echo "RELEASE=$release_path"
echo "ROLLBACK=$previous_target"
