---
name: run-pipeline
description: Runs the whole Overkill pipeline on an idea - spec, plan, write-tests, implement, verify, review, open-pr - stopping only where the user must decide, routing every failure back to the right stage, and resuming where it left off. Use when the user asks Overkill to build, fix or change something end to end, or to resume, check or cancel a run.
license: MIT
---

# run-pipeline

Runs all seven Overkill stages in order on one change, stops wherever the user
has to decide, and sends every failure back to the stage that can fix it.
Every stage runs in pipeline mode and hands its receipt back here.

Read `references/conventions.md` first. Load each stage skill by name when it
is its turn (Claude Code plugin: `overkill:<stage>`; standalone or OpenCode:
`<stage>`).

## Commands

- **Start:** `run-pipeline <idea or issue link>`
- **Resume:** `run-pipeline resume`, or `run-pipeline` with no idea while a run
  is active
- **Status:** `run-pipeline status` — show `status.md` in a few lines
- **Cancel:** `run-pipeline cancel`

## Start

1. **Preflight.** Stop with a clear reason if any fails:
   - Inside a git repo with a remote, on the default branch, clean tree,
     pulled to the latest commit.
   - No active run: if `.git/overkill/active` exists, offer to resume or cancel
     that run instead. One run at a time.
   - `gh` installed and signed in (needed later by `open-pr`); otherwise
     `BLOCKED missing-tool:gh` now rather than at the end.
2. **Run `spec`.** It allocates the run folder and creates the branch on
   approval.
3. **Mark active:** write the run folder name and branch to
   `.git/overkill/active`, and create `status.md` from `templates/status.md`.
4. **Continue through the flow.**

## Flow

```
spec → (you approve) → plan → (you approve) → write-tests → implement
     → verify → review → open-pr → CI → done
```

After every stage, record its receipt in `status.md`, commit the record
(`chore(record): status [NNNN]`) and move on according to the routing table.

## Routing

| Receipt | Next |
|---|---|
| `plan BLOCKED spec-gap` | `spec` (revise), then `plan` again; you re-approve both |
| `implement BLOCKED plan-mismatch` / `needs-file` | `plan` revision mode, you re-approve, then `implement` redo mode |
| `implement BLOCKED spec-gap` | `spec`, then `plan`, then continue |
| `implement BLOCKED needs-test-change` | Wait for your decision, then `implement` |
| any `BLOCKED missing-tool:<name>` | Wait for you to install it, then retry the same stage |
| `verify FAIL` | `implement` fix mode with the failing checks → `verify` |
| `review FINDINGS` | `implement` fix mode with every finding → `verify` → next `review` round |
| `review WAITING attention` | Wait for your decisions, then route any resulting fixes as findings |
| `review WAITING safeguard` | Wait for you (3 rounds in a row had findings) |
| `open-pr FAIL rebased` | `verify` → `review` Final round → `open-pr` |
| `open-pr BLOCKED merge-conflict` | `implement` rebase mode → `verify` → `review` Final round → `open-pr` |
| `open-pr FAIL ci round <n>` | `implement` fix mode with the CI failures → `verify` → `review` Fix round, then Final round → `open-pr` |
| CI fails 3 rounds in a row | Wait for you |
| `open-pr DONE` | Finish |

## Rules

- Never skip a stage, and never move past a failed check or an unapproved
  spec or plan.
- `write-tests` and `review` subagents always start with fresh context so they
  stay independent of earlier work.
- The orchestrator reads receipts and `status.md`, not code, diffs or logs.
- When waiting, set `status.md` to `WAITING` with the reason, show the user
  what needs deciding, and stop until they reply in chat.
- Update and commit `status.md` after every step, so an interrupted run can be
  resumed exactly where it stopped.

## Resume

1. Read `.git/overkill/active`, switch to the run's branch, read `status.md`.
2. Continue from the current stage. `implement` discards half-finished
   worktree tasks and starts them over.
3. If the run was `WAITING`, show the open question again.

## Cancel

1. Remove the run's worktrees and their temporary `overkill-wt/NNNN/*`
   branches, then `git worktree prune`.
2. Set `status.md` to `CANCELLED` and commit it on the run branch.
3. Delete `.git/overkill/active` and switch back to the default branch.
4. Keep the run branch and its `.record/` files.

## Split ideas

If the spec split the idea into parts, each part is its own run:

1. Run part 1 through to an open, green PR.
2. Set `WAITING`: "Merge part 1 (PR link), then tell me to continue."
3. On "continue", confirm it merged (`gh pr view <n> --json state`). If not
   merged, keep waiting.
4. Start the next part as a new run, with `spec` seeded from the part's
   outline.

## Finish

Set `status.md` to `DONE`, commit it, push it to the PR branch, delete
`.git/overkill/active`, and give the user the PR link and a one-paragraph
summary: what changed, how many tasks and fixes, review rounds, and CI result.
