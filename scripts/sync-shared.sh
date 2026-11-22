#!/usr/bin/env bash
# Copy shared/conventions.md into every skill's references/ folder,
# so each skill still works when installed on its own.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/shared/conventions.md"

for skill in "$root"/skills/*/; do
  mkdir -p "$skill/references"
  cp "$src" "$skill/references/conventions.md"
  echo "synced $(basename "$skill")"
done
