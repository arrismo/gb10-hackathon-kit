#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

require_drive_arg "$0" "${1:-}"
DRIVE="$1"

ensure_layout "$DRIVE"

FREE_KB="$(free_kb "$DRIVE")"
FREE_GB=$((FREE_KB / 1024 / 1024))

cat <<EOF
Drive prepared: $DRIVE

Created/verified directories:
  $DRIVE/models
  $DRIVE/docker
  $DRIVE/installers/openshell
  $DRIVE/repos
  $DRIVE/docs

Available capacity: ${FREE_GB} GB
EOF

if [ "$FREE_GB" -lt 100 ]; then
  echo "Warning: less than 100 GB is available. The kit is ~33 GB today but may grow." >&2
fi

echo "No formatting or erasing was performed."
