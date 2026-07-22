#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_release_path() {
  case "$1" in
    /var/www/zomia/releases/*) ;;
    *) fail "Unexpected release path: $1" ;;
  esac
}

require_webapp_link() {
  [[ "$1" == "/var/www/zomia/webapp" ]] || fail "Unexpected webapp link: $1"
}

atomic_switch() {
  local target="$1"
  local link="$2"
  local next_link="${link}.next.$$"

  sudo ln -s "$target" "$next_link"
  trap 'sudo rm -f "$next_link"' RETURN
  sudo mv -Tf "$next_link" "$link"
  trap - RETURN
}

command_name="${1:-}"
shift || true

case "$command_name" in
  prepare)
    [[ "$#" -eq 5 ]] || fail "prepare requires archive, release, link, version, and build"
    archive="$1"
    release="$2"
    link="$3"
    expected_version="$4"
    expected_build="$5"

    require_release_path "$release"
    require_webapp_link "$link"
    case "$archive" in
      /tmp/zomia_frontend_*.tar.gz) ;;
      *) fail "Unexpected archive path: $archive" ;;
    esac
    [[ -f "$archive" ]] || fail "Archive not found: $archive"
    [[ ! -e "$release" ]] || fail "Release already exists: $release"

    cleanup_failed_release() {
      sudo rm -rf "$release"
    }
    trap cleanup_failed_release ERR

    sudo mkdir -p "$release"
    sudo tar --no-same-owner -xzf "$archive" -C "$release"
    sudo chown -R root:root "$release"

    actual_version="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$release/version.json")"
    actual_build="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["build_number"])' "$release/version.json")"
    [[ "$actual_version" == "$expected_version" ]] || fail "Unexpected release version: $actual_version"
    [[ "$actual_build" == "$expected_build" ]] || fail "Unexpected release build: $actual_build"
    grep -q '<base href="/webapp/">' "$release/index.html" || fail "Production base href is missing"
    grep -q 'https://zomia.eu/api/v1' "$release/main.dart.js" || fail "Production API base is missing"
    [[ ! -e "$release/clear-local-cache.html" ]] || fail "Local cache helper reached production"
    if find "$release" \( -name '._*' -o -name '.DS_Store' \) -print -quit | grep -q .; then
      fail "macOS metadata reached production"
    fi
    if grep -R -q --include='*.js' 'sourceMappingURL=' "$release"; then
      fail "Source-map references reached production"
    fi

    previous="$(readlink -f "$link")"
    require_release_path "$previous"
    trap - ERR
    echo "PREVIOUS=$previous"
    echo "RELEASE=$release"
    ;;

  activate)
    [[ "$#" -eq 2 ]] || fail "activate requires release and link"
    release="$1"
    link="$2"
    require_release_path "$release"
    require_webapp_link "$link"
    [[ -d "$release" ]] || fail "Release not found: $release"
    atomic_switch "$release" "$link"
    [[ "$(readlink -f "$link")" == "$release" ]] || fail "Frontend symlink did not switch"
    echo "ACTIVE=$release"
    ;;

  rollback)
    [[ "$#" -eq 2 ]] || fail "rollback requires previous release and link"
    previous="$1"
    link="$2"
    require_release_path "$previous"
    require_webapp_link "$link"
    [[ -d "$previous" ]] || fail "Rollback release not found: $previous"
    atomic_switch "$previous" "$link"
    [[ "$(readlink -f "$link")" == "$previous" ]] || fail "Frontend rollback failed"
    echo "ROLLED_BACK=$previous"
    ;;

  *)
    fail "Expected prepare, activate, or rollback"
    ;;
esac
