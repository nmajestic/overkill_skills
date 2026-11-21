---
name: implement
description: Overkill stage 4. Carries out an approved plan with up to 8 parallel worker subagents in separate git worktrees, one commit per task, until the frozen failing tests pass. Also applies fixes sent back by verify, review or CI. Use after write-tests in an Overkill run.
license: MIT
---

# implement

Carries out the plan's tasks until the failing tests pass, without making any
design decisions. The orchestrator schedules workers and reads their receipts.
It never reads implementation code or diffs.

Read `references/conventions.md` first.

## Modes

- **Build:** run the plan's tasks wave by wave.
- **Fix:** apply a list of failures or findings sent back by `verify`,
  `review` or CI. Fix only what was reported.
- **Redo:** after an approved plan revision, revert and rebuild the tasks the
  plan marks `REDO`.
- **Rebase:** `open-pr` hit conflicts rebasing onto the default branch.
  Resolve them (see "Rebase mode").

## Inputs

- `plan.md` (approved), `tests.md` with the frozen test files, `spec.md` for
  reference.
- Fix mode: the failing items or findings (IDs and the files they point to).

## Preflight

1. Confirm you are on the run branch, never the default branch.
2. Remove leftover worktrees from an interrupted run (see "Worktrees") and
   discard their unfinished work. Those tasks start over.
3. Tasks already marked `DONE` in `implementation.md` stay done.

## Build mode

For each wave in the plan, in order:

1. **Dispatch workers.** One worker subagent per task, up to 8 at once, all in
   one message. Queue the rest and start each as a slot frees.
2. **Each worker:**
   - Works only in its own worktree, created from the run branch's current
     HEAD.
   - Gets: its task from the plan, the Interfaces section, the Context
     section's conventions, the relevant ACs, and the commands.
   - Edits only the files its task owns. Needing another file is
     `BLOCKED needs-file:<path>`.
   - Never edits a frozen test file listed in `tests.md`. Needing to is
     `BLOCKED needs-test-change`.
   - Makes the change, then compiles or type-checks and runs the tests related
     to its task. Its ACs' tests must pass only if every task serving that AC
     is now complete; otherwise it must compile and not break existing tests.
   - Debugs as long as needed, with no attempt limit, but never repeats an
     attempt: each one must try something different. It keeps a short attempt
     log in `.git/overkill/notes/NNNN/<task>.md`.
   - If the plan itself is wrong (an interface doesn't fit, a dependency the
     plan missed), stops with `BLOCKED plan-mismatch: <why>` rather than
     improvising.
   - Commits once, with the plan's commit message, and returns exactly one
     line: `T4 DONE 9e1b7f2` or `T6 BLOCKED <reason>: <detail>`.
3. **Merge the wave.** Cherry-pick the `DONE` commits onto the run branch in
   task-ID order. On a conflict, abort that cherry-pick, record
   `T<n> CONFLICT`, and redo that task from the new HEAD.
4. **Quick check.** One subagent builds or type-checks the merged branch and
   returns `build PASS` or `build FAIL <n> errors`. A failure becomes a fix
   task (see Fix mode) before the next wave starts.
5. **Clean up** the wave's worktrees and update `implementation.md`.

After the last wave, one subagent runs the full test suite. Any failing new
test is traced through the plan's Coverage table to its tasks and fixed with
fix tasks. Repeat until every test passes.

## Fix mode

1. Group the reported items by the files they touch, so no two fix tasks share
   a file. Give each fix task the next free ID: `F1`, `F2`, … (IDs never repeat
   within a run).
2. Dispatch fix workers exactly like build workers, up to 8 at once. Each gets
   only its items, the files involved, and the conventions.
3. Commit type matches the change, ending with the fix ID:
   `fix(cart): handle empty list [F3]`, `refactor(cart): extract total [F4]`.
4. Merge, quick check, and run the full suite as in build mode.

Fix only what was reported. If a finding can't be fixed without a plan or test
change, it is `BLOCKED` like any task.

## Redo mode

For each task marked `REDO` in the revised plan, in reverse task order,
`git revert` its commit (`revert: <original summary> [Tn]`), then rebuild the
task from the revised plan through build mode. Never rewrite history.

## Rebase mode

One worker, since a rebase can't be split:

1. Rebase the run branch onto the latest default branch.
2. Resolve each conflict so the default branch's changes and the run's planned
   behavior both survive. Never drop either side to make a conflict go away.
3. A conflict inside a frozen test file needs the user's
   approval, like any test change.
4. If the default branch changed something the plan relies on so much that the
   plan no longer fits, abort the rebase and return `BLOCKED plan-mismatch`.
5. Return `rebase DONE <new HEAD>`. `verify` and a Final review round follow.

## Blocked tasks

When any worker returns `BLOCKED`, let the rest of the wave finish, merge what
is `DONE`, then:

| Reason | What happens |
|---|---|
| `plan-mismatch` | Hand back to `plan` (revision mode). The user approves the revision. |
| `spec-gap` | Hand back to `spec`. |
| `needs-test-change` | Ask the user (see write-tests). Continue only on approval. |
| `needs-file:<path>` | Hand back to `plan` to reassign file ownership. |
| `missing-tool:<name>` | Wait for the user to install it. |

## Worktrees

- Location: a sibling folder outside the repo,
  `../<repo>.overkill-wt/NNNN/<task>`, on a branch named
  `overkill-wt/NNNN/<task>`. Fall back to the system temp folder if the
  sibling folder can't be created.
- Remove with `git worktree remove --force <path>` and delete the temporary
  branch after its commit is merged or discarded. Run `git worktree prune`
  afterwards.

## Code rules (every worker)

- No scope creep: no unplanned refactors, features or "while I'm here"
  fixes. Note ideas as follow-ups in the notes file; the orchestrator copies
  them to `implementation.md`.
- No new dependencies beyond the plan.
- Small mechanical deviations inside owned files (an import, a private helper
  name) are fine and must be listed in the receipt detail or notes.
- Follow the conventions the plan recorded.
- Comments explain why, not what. No debug prints, commented-out code or
  stray TODOs.
- Update docs only where the plan says, or where user-visible behavior
  changed.

## Output

`.record/NNNN-<slug>/implementation.md` from `templates/implementation.md`:
every task and fix, its status, commit, and deviations, plus follow-ups.

## Done when

Every task and fix is `DONE` and merged, every new test passes, no existing
test fails, and the log is complete and committed with
`chore(record): implementation log [NNNN]`.

## Pipeline receipt

`implement DONE <n> commits` or `implement BLOCKED <task> <reason>`.
