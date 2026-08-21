#!/usr/bin/env bash
set -euo pipefail

script_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }
repo_root() { cd "$(script_dir)/.." && pwd; }
versions_file() { printf '%s/config/versions.env\n' "$(repo_root)"; }

load_versions() {
  # shellcheck disable=SC1090
  source "$(versions_file)"
}

usage_drive() {
  local script_name="$1"
  cat >&2 <<EOF
Usage: $script_name /path/to/external-drive

The drive path is required. This script will never format or erase a drive.
Examples:
  $script_name /Volumes/HACKATHON
  $script_name /media/\$USER/HACKATHON
EOF
}

require_drive_arg() {
  local script_name="$1"
  if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
    usage_drive "$script_name"
    exit 2
  fi
  if [ ! -d "$2" ]; then
    echo "Error: drive path does not exist or is not a directory: $2" >&2
    usage_drive "$script_name"
    exit 2
  fi
}

ensure_layout() {
  local drive="$1"
  mkdir -p \
    "$drive/models" \
    "$drive/docker" \
    "$drive/installers/openshell" \
    "$drive/repos" \
    "$drive/docs"
}

human_size() {
  local path="$1" size=""
  if [ ! -e "$path" ]; then
    echo "missing"
    return 0
  fi
  # macOS external volumes may contain protected system directories such as
  # .Spotlight-V100. Use the first usable du line even if du exits non-zero.
  size="$(du -sh "$path" 2>/dev/null | awk 'NR==1 {print $1}')" || true
  if [ -n "$size" ]; then
    echo "$size"
  else
    echo "unknown"
  fi
}

free_kb() {
  local path="$1"
  df -Pk "$path" | awk 'NR==2 {print $4}'
}

sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "Error: neither sha256sum nor shasum is available" >&2
    exit 1
  fi
}

verify_sha256_value() {
  local file="$1" expected="$2"
  local actual
  actual="$(sha256_file "$file")"
  [ "$actual" = "$expected" ]
}

require_cmd() {
  local cmd="$1" hint="${2:-Please install it and retry.}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' was not found. $hint" >&2
    exit 1
  fi
}

download_file() {
  local url="$1" dest="$2"
  require_cmd curl "Install curl and retry."
  mkdir -p "$(dirname "$dest")"
  curl -fL --retry 3 --max-redirs 5 -o "$dest" "$url"
}
