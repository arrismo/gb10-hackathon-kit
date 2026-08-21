#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"
load_versions

require_drive_arg "$0" "${1:-}"
DRIVE="$1"
FAIL=0

ok() { printf '[✓] %s\n' "$1"; }
bad() { printf '[✗] %s\n' "$1"; FAIL=1; }
info() { printf '    %s\n' "$1"; }

check_nonempty_file() {
  local label="$1" file="$2"
  if [ -s "$file" ]; then ok "$label"; info "Size: $(human_size "$file")"; else bad "$label missing or empty: $file"; fi
}

check_tar() {
  local label="$1" file="$2"
  check_nonempty_file "$label" "$file"
  if [ -s "$file" ]; then
    if tar -tf "$file" >/dev/null 2>&1; then info "Tar archive is readable"; else bad "$label is not a readable tar archive"; fi
  fi
}

cat <<EOF
NemoClaw Offline Kit Verification

Drive: $DRIVE
EOF

MODEL_DIR="$DRIVE/models/$MODEL_DIR_NAME"
if [ -d "$MODEL_DIR" ] && find "$MODEL_DIR" -type f -size +0c | grep -q .; then
  ok "$MODEL_DIR_NAME model found"
  info "Size: $(human_size "$MODEL_DIR")"
else
  bad "$MODEL_DIR_NAME model missing or empty: $MODEL_DIR"
fi

check_tar "NVIDIA vLLM image archive" "$DRIVE/docker/nvidia-vllm-dgx-spark.tar"
check_tar "NemoClaw sandbox archive" "$DRIVE/docker/nemoclaw-sandbox-base-arm64.tar"
check_tar "Node 22 ARM64 build image archive" "$DRIVE/docker/node22-arm64-build-images.tar"

check_nonempty_file "NemoClaw installer" "$DRIVE/installers/nemoclaw.sh"
if [ -d "$DRIVE/repos/NemoClaw/.git" ]; then
  ok "NemoClaw repository"
  if ACTUAL="$(git -C "$DRIVE/repos/NemoClaw" rev-parse HEAD 2>/dev/null)" && [ "$ACTUAL" = "$NEMOCLAW_COMMIT" ]; then
    ok "NemoClaw commit matches configured version"
  else
    bad "NemoClaw commit does not match configured version"
    info "Expected: $NEMOCLAW_COMMIT"
    info "Actual: ${ACTUAL:-unknown}"
  fi
else
  bad "NemoClaw repository missing: $DRIVE/repos/NemoClaw"
fi

OPEN_ARCHIVE="$DRIVE/installers/openshell/$OPENSHELL_ARM64_ASSET"
check_nonempty_file "OpenShell ARM64 archive" "$OPEN_ARCHIVE"
check_nonempty_file "OpenShell installer" "$DRIVE/installers/openshell/install.sh"
check_nonempty_file "OpenShell checksum file" "$DRIVE/installers/openshell/$OPENSHELL_CHECKSUMS_ASSET"
OPEN_CHECKSUMS="$DRIVE/installers/openshell/$OPENSHELL_CHECKSUMS_ASSET"
if [ -s "$OPEN_ARCHIVE" ] && verify_sha256_value "$OPEN_ARCHIVE" "$OPENSHELL_SHA256"; then
  ok "OpenShell pinned SHA256 verified"
else
  bad "OpenShell pinned SHA256 verification failed"
fi
if [ -s "$OPEN_ARCHIVE" ] && [ -s "$OPEN_CHECKSUMS" ]; then
  ACTUAL_OPEN_SHA="$(sha256_file "$OPEN_ARCHIVE")"
  OFFICIAL_OPEN_SHA="$(awk -v f="$OPENSHELL_ARM64_ASSET" '$2==f || $2=="*"f {print $1; exit}' "$OPEN_CHECKSUMS")"
  if [ -n "$OFFICIAL_OPEN_SHA" ] && [ "$ACTUAL_OPEN_SHA" = "$OFFICIAL_OPEN_SHA" ]; then
    ok "OpenShell official checksum file verified"
  else
    bad "OpenShell official checksum file verification failed"
  fi
fi

FREE_KB="$(free_kb "$DRIVE")"
FREE_GB=$((FREE_KB / 1024 / 1024))
ok "Available drive capacity checked"
info "Free: ${FREE_GB} GB"
info "Total kit size: $(human_size "$DRIVE")"

if [ "$FAIL" -eq 0 ]; then
  printf '\nREADY\n'
  exit 0
else
  printf '\nNOT READY\n' >&2
  exit 1
fi
