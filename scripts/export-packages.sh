#!/usr/bin/env bash
# Export explicitly installed pacman packages to packages/pkglist.txt.
set -euo pipefail
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT="$REPO_DIR/packages/pkglist.txt"

if ! command -v pacman >/dev/null 2>&1; then
  echo "error: pacman not found; this script is for Arch Linux." >&2
  exit 1
fi

{
  echo "# Explicitly installed Arch packages (pacman -Qqe)"
  echo "# Generated: $(date -Iseconds)"
  echo "# Reinstall with: sudo pacman -S --needed - < packages/pkglist.txt"
  echo
  pacman -Qqe
} > "$OUT"

echo "Wrote $(grep -vc '^#' "$OUT" || true) packages to $OUT"
