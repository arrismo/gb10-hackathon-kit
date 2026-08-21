#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"
load_versions

require_drive_arg "$0" "${1:-}"
DRIVE="$1"
ensure_layout "$DRIVE"

require_cmd docker "Install Docker Desktop or Docker Engine and retry."
if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon is not running or is unreachable." >&2
  echo "Start Docker Desktop or the Docker daemon and verify with: docker info" >&2
  exit 1
fi

bytes_human() {
  awk -v bytes="$1" 'BEGIN {
    split("B KB MB GB TB", unit, " ");
    size = bytes + 0;
    i = 1;
    while (size >= 1024 && i < 5) { size /= 1024; i++ }
    printf "%.1f%s", size, unit[i]
  }'
}

image_size() {
  local image="$1" bytes
  bytes="$(docker image inspect "$image" --format '{{.Size}}' 2>/dev/null || true)"
  if [ -n "$bytes" ]; then bytes_human "$bytes"; else echo "unknown"; fi
}

pull_arm64() {
  local image="$1"
  echo "Pulling linux/arm64 image: $image"
  if ! output="$(docker pull --platform linux/arm64 "$image" 2>&1)"; then
    echo "$output" >&2
    if printf '%s' "$image" | grep -q '^nvcr.io/'; then
      echo "Error pulling from nvcr.io. You may need NVIDIA NGC credentials." >&2
      echo "Run: docker login nvcr.io" >&2
      echo "Do not paste API keys into project files." >&2
    fi
    exit 1
  fi
  echo "$output"
  echo "Image size: $(image_size "$image")"
}

pull_arm64 "$VLLM_IMAGE"
pull_arm64 "$NEMOCLAW_SANDBOX_IMAGE"
pull_arm64 "$NODE_TRIXIE_IMAGE"
pull_arm64 "$NODE_TRIXIE_SLIM_IMAGE"

VLLM_TAR="$DRIVE/docker/nvidia-vllm-dgx-spark.tar"
SANDBOX_TAR="$DRIVE/docker/nemoclaw-sandbox-base-arm64.tar"
NODE_TAR="$DRIVE/docker/node22-arm64-build-images.tar"

echo "Saving Docker archives..."
docker save -o "$VLLM_TAR" "$VLLM_IMAGE"
docker save -o "$SANDBOX_TAR" "$NEMOCLAW_SANDBOX_IMAGE"
docker save -o "$NODE_TAR" "$NODE_TRIXIE_IMAGE" "$NODE_TRIXIE_SLIM_IMAGE"

cat <<EOF
Container archives:
  $VLLM_TAR ($(human_size "$VLLM_TAR"))
  $SANDBOX_TAR ($(human_size "$SANDBOX_TAR"))
  $NODE_TAR ($(human_size "$NODE_TAR"))

No ARM64 containers were run by this script.
EOF
