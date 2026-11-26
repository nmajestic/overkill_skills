#!/usr/bin/env bash
# Validate the Specflow repo. Run before committing; CI runs it too.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
err() { echo "FAIL $*"; fail=1; }

# 1. Manifests are valid JSON and their versions match.
for f in plugin marketplace; do
  python3 -m json.tool "$root/.claude-plugin/$f.json" > /dev/null \
    || err ".claude-plugin/$f.json is not valid JSON"
done
plugin_name=$(python3 -c "import json;print(json.load(open('$root/.claude-plugin/plugin.json'))['name'])")
plugin_version=$(python3 -c "import json;print(json.load(open('$root/.claude-plugin/plugin.json'))['version'])")
market_version=$(python3 -c "import json;m=json.load(open('$root/.claude-plugin/marketplace.json'));matches=[p for p in m['plugins'] if p['name']=='$plugin_name'];print(matches[0]['version'] if matches else '')")
[ "$plugin_version" = "$market_version" ] \
  || err "version mismatch or missing plugin '$plugin_name': plugin.json $plugin_version, marketplace.json ${market_version:-<missing>}"

# 2. Every skill has valid frontmatter whose name matches its folder.
for dir in "$root"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  [ -f "$file" ] || { err "$name: missing SKILL.md"; continue; }
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "$name: folder name is not lowercase kebab-case"
  [ "$(head -n1 "$file")" = "---" ] || err "$name: SKILL.md must start with frontmatter"
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")
  fm_name=$(printf '%s\n' "$fm" | sed -n 's/^name: *//p')
  [ "$fm_name" = "$name" ] || err "$name: frontmatter name '$fm_name' does not match folder"
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description: *//p')
  [ -n "$desc" ] || err "$name: missing description"
  [ "${#desc}" -le 1024 ] || err "$name: description longer than 1024 characters"
  extra=$(printf '%s\n' "$fm" | grep -vE '^(name|description|license):' | grep -vE '^\s*$' || true)
  [ -z "$extra" ] || err "$name: frontmatter keys other than name, description, license"

  # 3. Shared conventions copy is in sync.
  cmp -s "$root/shared/conventions.md" "$dir/references/conventions.md" \
    || err "$name: references/conventions.md is out of sync (run scripts/sync-shared.sh)"

  # 4. Every file a skill points to exists.
  for ref in $(grep -oE '(templates|references)/[a-z0-9_.-]+\.md' "$file" | sort -u); do
    [ -f "$dir/$ref" ] || err "$name: SKILL.md mentions $ref, which does not exist"
  done
done

# 5. The pipeline has exactly the expected skills.
expected="implement open-pr plan review run-pipeline spec verify write-tests"
actual=$(ls "$root/skills" | sort | tr '\n' ' ' | sed 's/ $//')
[ "$actual" = "$expected" ] || err "skills folder has '$actual', expected '$expected'"

# 6. Shell scripts parse.
for s in "$root"/scripts/*.sh; do
  bash -n "$s" || err "$(basename "$s") has a syntax error"
done

if [ "$fail" -eq 0 ]; then echo "PASS all checks"; fi
exit "$fail"
