#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"
load_versions

require_drive_arg "$0" "${1:-}"
DRIVE="$1"
ensure_layout "$DRIVE"
require_cmd git "Install Git and retry."
require_cmd curl "Install curl and retry."

INSTALLER="$DRIVE/installers/nemoclaw.sh"
REPO_DIR="$DRIVE/repos/NemoClaw"

echo "Downloading NemoClaw installer..."
download_file "$NEMOCLAW_INSTALLER_URL" "$INSTALLER"
chmod +x "$INSTALLER"

if [ -d "$REPO_DIR/.git" ]; then
  echo "Updating existing NemoClaw repository..."
  git -C "$REPO_DIR" fetch --tags origin
else
  echo "Cloning NemoClaw repository..."
  git clone "$NEMOCLAW_REPO_URL" "$REPO_DIR"
fi

git -C "$REPO_DIR" fetch origin "$NEMOCLAW_COMMIT" || true
git -C "$REPO_DIR" checkout --detach "$NEMOCLAW_COMMIT"
ACTUAL="$(git -C "$REPO_DIR" rev-parse HEAD)"
if [ "$ACTUAL" != "$NEMOCLAW_COMMIT" ]; then
  echo "Error: NemoClaw commit mismatch. Expected $NEMOCLAW_COMMIT got $ACTUAL" >&2
  exit 1
fi

printf '%s\n' "$ACTUAL" > "$DRIVE/docs/nemoclaw-commit.txt"
echo "NemoClaw ready at $REPO_DIR ($ACTUAL)"
