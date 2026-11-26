# Working on the Specflow repo

- Skills live in `skills/<name>/SKILL.md`. The folder name and the `name` in
  the frontmatter must match and be lowercase kebab-case.
- Frontmatter uses only `name`, `description` and `license`, so the same files
  load in Claude Code and OpenCode.
- `shared/conventions.md` is the source of truth for rules every skill shares.
  Never edit `skills/*/references/conventions.md` directly. Edit the shared
  file, then run `scripts/sync-shared.sh`.
- Run `scripts/check.sh` before committing. CI runs the same script.
- Keep the plugin version in `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` identical.
