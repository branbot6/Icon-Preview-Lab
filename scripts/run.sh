#!/bin/zsh
set -euo pipefail

NATIVE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="IconPreviewLabNative"
LOG_FILE="$(mktemp)"

cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Capture build output once so we can inspect the real failure reason.
if swift run --package-path "$NATIVE_DIR" "$TARGET" 2>&1 | tee "$LOG_FILE"; then
  exit 0
fi

echo "Detected build failure. Checking for stale Swift module cache..."
if grep -qi "module cache path" "$LOG_FILE"; then
  echo "Stale module cache found. Cleaning .build and retrying..."
  rm -rf "$NATIVE_DIR/.build"
  swift run --package-path "$NATIVE_DIR" "$TARGET"
  exit 0
fi

echo "Run failed for a reason other than stale module cache."
exit 1
