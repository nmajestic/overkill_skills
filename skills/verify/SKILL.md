---
name: verify
description: Overkill stage 5. Runs every automated check in parallel - full test suite, linter with warnings as errors, format check, type-check, build, dependency audit, and the pipeline's own rules - and reports pass or fail without changing anything. Use after implement in an Overkill run, or to check a branch.
license: MIT
---

# verify

Runs the automated checks and reports pass or fail. No judgment, no opinions,
and the same result every time on the same code.

**verify never changes anything.** No fixes, no auto-formatting, no edits. It
only writes its own report.

Read `references/conventions.md` first.

## Inputs

- `plan.md`: the Commands table.
- The repo's CI config, so local checks match what CI runs. If CI runs a check
  the Commands table lacks, run it too and note it.
- `tests.md`: the frozen test commit and files, the budget and approved test
  changes.
- `spec.md` and `plan.md` for the rule checks.

## Steps

1. **Clean tree.** Uncommitted changes are `clean-tree FAIL`.
2. **Dispatch one subagent per check, all in one message** (up to 8 at once,
   queue the rest). Each runs exactly one check, writes the full output to
   `.git/overkill/logs/NNNN/verify-r<round>-<check>.log`, and returns one receipt
   line with a short error excerpt (at most ten words) if it failed.

### Code checks

| Check | Rule |
|---|---|
| `tests` | Full suite. Rerun any failing test once: fails twice is `FAIL`, passes on rerun is `FLAKY` (still a failure). |
| `lint` | Warnings are errors (e.g. `clippy -D warnings`, `eslint --max-warnings 0`). |
| `format` | Check mode only (e.g. `cargo fmt --check`, `prettier --check`). |
| `type-check` | |
| `build` | |
| `audit` | Dependency vulnerability audit where the stack has one. |

### Rule checks

Run these together in one subagent; they are fast and read-only.

| Check | Fails when |
|---|---|
| `ac-tests` | An AC or "test" edge case in `tests.md` has no test, or its test doesn't pass (refactor, chore and docs runs with no new tests: the full suite passing satisfies this) |
| `test-budget` | New tests exceed the budget without a logged approval |
| `frozen-tests` | A frozen test file listed in `tests.md` changed after the frozen test commit, with no matching approved change |
| `deps` | A dependency was added that the plan doesn't list |
| `hygiene` | The code diff (excluding `.record/`) adds debug prints, commented-out code or new TODO/FIXME lines |
| `secrets` | The diff contains something that looks like a key, token or password (use `gitleaks` if installed, otherwise a pattern scan of the diff) |

3. **Statuses.** `SKIPPED` only when `plan.md` marks the check `N/A` with a
   reason. A tool that should exist but isn't installed is
   `BLOCKED missing-tool:<name>`, never skipped.
4. **Write the report.** Append a round section to
   `.record/NNNN-<slug>/verify.md` from `templates/verify.md`: every check,
   its command, its status and the excerpt. Commit:
   `chore(record): verify round <n> [NNNN]`.
5. **Hand back.** Every check passes → `verify PASS`. Otherwise →
   `verify FAIL`, listing only the failing checks with their log paths, for
   `implement` fix mode.

## Rules

- Report the real error output, never a guess at the cause.
- Never mark a check passed that didn't run.
- Same commands, same order, every round.
- In standalone mode, report and stop.

## Done when

Every check is `PASS` (or `SKIPPED` with the plan's reason).

## Pipeline receipt

`verify PASS round <n>` · `verify FAIL round <n>: <check>, <check>` ·
`verify BLOCKED missing-tool:<name>`
