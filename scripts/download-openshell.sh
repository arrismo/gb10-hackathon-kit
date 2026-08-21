#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"
load_versions

require_drive_arg "$0" "${1:-}"
DRIVE="$1"
ensure_layout "$DRIVE"

OPEN_DIR="$DRIVE/installers/openshell"
INSTALLER="$OPEN_DIR/install.sh"
ARCHIVE="$OPEN_DIR/$OPENSHELL_ARM64_ASSET"
CHECKSUMS="$OPEN_DIR/$OPENSHELL_CHECKSUMS_ASSET"
BASE_URL="https://github.com/$OPENSHELL_REPO/releases/download/$OPENSHELL_VERSION"

echo "Downloading OpenShell installer and pinned ARM64 release assets..."
download_file "$OPENSHELL_INSTALLER_URL" "$INSTALLER"
chmod +x "$INSTALLER"
download_file "$BASE_URL/$OPENSHELL_ARM64_ASSET" "$ARCHIVE"
download_file "$BASE_URL/$OPENSHELL_CHECKSUMS_ASSET" "$CHECKSUMS"

ACTUAL="$(sha256_file "$ARCHIVE")"
if [ "$ACTUAL" != "$OPENSHELL_SHA256" ]; then
  echo "Error: OpenShell pinned checksum mismatch." >&2
  echo "Expected: $OPENSHELL_SHA256" >&2
  echo "Actual:   $ACTUAL" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$OPEN_DIR" && grep -E "[ *]$OPENSHELL_ARM64_ASSET$" "$OPENSHELL_CHECKSUMS_ASSET" | sha256sum -c -)
elif command -v shasum >/dev/null 2>&1; then
  EXPECTED_OFFICIAL="$(awk -v f="$OPENSHELL_ARM64_ASSET" '$2==f || $2=="*"f {print $1; exit}' "$CHECKSUMS")"
  if [ -z "$EXPECTED_OFFICIAL" ] || [ "$EXPECTED_OFFICIAL" != "$ACTUAL" ]; then
    echo "Error: OpenShell official checksum file does not match archive." >&2
    exit 1
  fi
else
  echo "Error: neither sha256sum nor shasum is available" >&2
  exit 1
fi

echo "OpenShell archive verified: $ARCHIVE ($(human_size "$ARCHIVE"))"
