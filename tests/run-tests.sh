#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

run_expect_fail() {
  local name="$1"; shift
  if "$@" >/tmp/nemoclaw-test.out 2>&1; then
    echo "✗ $name (expected failure)"
    FAIL=$((FAIL+1))
  else
    echo "✓ $name"
    PASS=$((PASS+1))
  fi
}

run_expect_pass() {
  local name="$1"; shift
  if "$@" >/tmp/nemoclaw-test.out 2>&1; then
    echo "✓ $name"
    PASS=$((PASS+1))
  else
    echo "✗ $name"
    cat /tmp/nemoclaw-test.out
    FAIL=$((FAIL+1))
  fi
}

run_expect_fail "prepare-drive missing drive argument" "$ROOT/scripts/prepare-drive.sh"
run_expect_fail "prepare-drive nonexistent drive path" "$ROOT/scripts/prepare-drive.sh" "$TMP/nope"
mkdir -p "$TMP/drive"
run_expect_pass "successful directory creation" "$ROOT/scripts/prepare-drive.sh" "$TMP/drive"

for d in models docker installers/openshell repos docs; do
  if [ ! -d "$TMP/drive/$d" ]; then
    echo "✗ expected directory missing: $d"
    FAIL=$((FAIL+1))
  fi
done

run_expect_fail "verification with missing artifacts" "$ROOT/scripts/verify-kit.sh" "$TMP/drive"

run_expect_fail "download-model reports missing hf" env PATH=/usr/bin:/bin "$ROOT/scripts/download-model.sh" "$TMP/drive"

FAKE_BIN="$TMP/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
if [ "${1:-}" = "info" ]; then
  echo "failed to connect to the docker API" >&2
  exit 1
fi
exit 1
FAKE_DOCKER
chmod +x "$FAKE_BIN/docker"
run_expect_fail "cache-containers reports missing Docker daemon" env PATH="$FAKE_BIN:/usr/bin:/bin" "$ROOT/scripts/cache-containers.sh" "$TMP/drive"

# Checksum mismatch detection using common helper, without downloading anything.
printf 'bad data\n' > "$TMP/bad.tar.gz"
if bash -c "source '$ROOT/scripts/common.sh'; verify_sha256_value '$TMP/bad.tar.gz' '0000000000000000000000000000000000000000000000000000000000000000'"; then
  echo "✗ checksum mismatch detection"
  FAIL=$((FAIL+1))
else
  echo "✓ checksum mismatch detection"
  PASS=$((PASS+1))
fi

# Syntax checks for all scripts.
while IFS= read -r script; do
  run_expect_pass "bash syntax $(basename "$script")" bash -n "$script"
done < <(find "$ROOT/scripts" "$ROOT/tests" -type f -name '*.sh' | sort)

echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
