#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

require_drive_arg "$0" "${1:-}"
DRIVE="$1"

run_stage() {
  local n="$1" label="$2" script="$3"
  echo "[$n/6] $label..."
  if ! "$SCRIPT_DIR/$script" "$DRIVE"; then
    echo "Error: stage failed: $label ($script)" >&2
    exit 1
  fi
  echo
}

run_stage 1 "Preparing drive" prepare-drive.sh
run_stage 2 "Downloading NemoClaw" download-nemoclaw.sh
run_stage 3 "Downloading OpenShell" download-openshell.sh
run_stage 4 "Downloading local model" download-model.sh
run_stage 5 "Caching ARM64 containers" cache-containers.sh
run_stage 6 "Verifying kit" verify-kit.sh

echo "✓ Offline kit ready"
