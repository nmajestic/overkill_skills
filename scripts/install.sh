#!/usr/bin/env bash
# Install the Specflow skills as standalone skills (not as a plugin).
#
#   scripts/install.sh --tool claude              # ~/.claude/skills
#   scripts/install.sh --tool opencode            # ~/.config/opencode/skills
#   scripts/install.sh --tool claude --project .  # ./.claude/skills
#   scripts/install.sh --tool opencode --project ~/code/app
#   add --force to replace skills that are already installed
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tool=""
project=""
force=0

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --tool) tool="${2:-}"; shift 2 ;;
    --project) project="${2:-}"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

case "$tool" in
  claude)
    if [ -n "$project" ]; then dest="$project/.claude/skills"; else dest="$HOME/.claude/skills"; fi ;;
  opencode)
    if [ -n "$project" ]; then dest="$project/.opencode/skills"; else dest="$HOME/.config/opencode/skills"; fi ;;
  *) usage ;;
esac

mkdir -p "$dest"

# Refuse to overwrite anything unless --force is given.
if [ "$force" -eq 0 ]; then
  clashes=""
  for skill in "$root"/skills/*/; do
    name=$(basename "$skill")
    [ -e "$dest/$name" ] && clashes="$clashes $name"
  done
  if [ -n "$clashes" ]; then
    echo "Already installed in $dest:$clashes"
    echo "Re-run with --force to replace them."
    exit 1
  fi
fi

for skill in "$root"/skills/*/; do
  name=$(basename "$skill")
  rm -rf "${dest:?}/$name"
  cp -R "$skill" "$dest/$name"
  echo "installed $name -> $dest/$name"
done

echo "Done. Start a run with the run-pipeline skill."
