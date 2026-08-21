#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"
load_versions

require_drive_arg "$0" "${1:-}"
DRIVE="$1"
ensure_layout "$DRIVE"

require_cmd hf "Install the Hugging Face CLI, then run 'hf auth login' if the model requires access."

DESTINATION="$DRIVE/models/$MODEL_DIR_NAME"
mkdir -p "$DESTINATION"

if find "$DESTINATION" -type f -name 'config.json' -size +0c | grep -q . && find "$DESTINATION" -type f \( -name '*.safetensors' -o -name '*.bin' -o -name '*.gguf' \) -size +0c | grep -q .; then
  echo "Model directory appears complete; skipping download: $DESTINATION"
else
  echo "Downloading $MODEL_ID to $DESTINATION"
  echo "If authentication fails, run: hf auth login"
  hf download "$MODEL_ID" --local-dir "$DESTINATION"
fi

echo "Model size: $(human_size "$DESTINATION")"
echo "Hugging Face tokens were not stored by this script."
