---
name: plan
description: Specflow stage 2. Turns an approved spec into an approved implementation plan in .record/NNNN-slug/plan.md - codebase exploration, design decisions, interfaces, tasks grouped into parallel waves, AC coverage and the exact commands to verify with. Use after a spec is approved, or when implement reports the plan is wrong.
license: MIT
---

# plan

Turns the approved spec into a plan precise enough that `implement` never
makes a design decision.

Read `references/conventions.md` first.

## Inputs

- `.record/NNNN-<slug>/spec.md` with status `approved`. If it is missing or
  still `draft`, stop and send the user to `spec`.
- Revision mode only: the `BLOCKED` receipt from `implement` that explains why
  the current plan is wrong.

## Steps

1. **Explore the codebase in parallel.** Dispatch up to 8 read-only explorer
   subagents in one message. Default areas, split further on large repos:
   1. Entry points and control flow the change touches
   2. Data models, types and interfaces involved
   3. Existing features most similar to this one
   4. Shared helpers and repo conventions (naming, errors, logging, layout)
   5. Test setup: framework, locations, naming, fixtures
   6. Commands: test, lint, format check, type-check, build, dependency audit,
      and what CI runs
   Each explorer writes nothing and returns at most 12 lines:
   `KEY_FILES`, `CONTRACTS`, `REUSE`, `LANDMINES` (or `COMMANDS` for area 6).
   Smaller repos need fewer explorers.
2. **Missing tooling.** If the repo has no test framework, linter or formatter
   for the language being changed, add setup tasks for them to the plan. The
   user approves them with the plan.
3. **Decide the approach.** At every real design fork, stop and ask (see
   "Design forks"). Do not choose silently.
4. **Define interfaces.** Exact new or changed function signatures, types,
   data shapes, routes, config keys and error types. `write-tests` builds
   stubs from these, and parallel workers rely on them, so they must be exact.
5. **Break into tasks** (see "Tasks").
6. **Map coverage.** Every AC and every edge case marked "test" → the tasks
   that build it → the test file that will check it.
7. **Record commands.** Fill the Commands table with the exact commands
   `verify` will run. Mark a check `N/A` only when it truly does not exist for
   this stack, and give the reason.
8. **List risks.** What could break, migrations, breaking changes, new
   dependencies.
9. **Self-check** (see below).
10. **Ask for approval.** Every plan needs the user's approval. Show the plan
    and wait. Revise until approved.
11. **On approval:** set status `approved` and commit:
    `chore(record): approve plan [NNNN]`.

## Design forks

A fork is any choice where reasonable engineers would differ and the choice
affects behavior, structure, dependencies or how hard it is to change later.
For each fork, stop and show:

| Option | Complexity | Performance | Maintainability | Dependencies | Reversibility |
|---|---|---|---|---|---|

Add any other trade-off that matters for this fork. Mark which option you
would pick and why in one sentence. Wait for the user's choice, then record
the choice and the rejected options in the Approach section.

## Tasks

Each task has:

- **ID:** `T1`, `T2`, … (setup tasks first)
- **Title** and **commit message** (Conventional Commits, ending `[Tn]`)
- **Files:** every file it creates or modifies, marked `CREATE` or `MODIFY`.
  A task owns its files for the wave it runs in.
- **Depends on:** task IDs that must be merged first
- **Serves:** AC and edge case IDs
- **Change:** exactly what to do, with no decisions left open
- **Done check:** how the worker knows the task is finished

Sizing for parallel work: `implement` runs up to 8 tasks at once. Split work
into tasks small enough to fill up to 8 slots per wave, but never so small that
two tasks must edit the same file. Never add filler tasks.

**Waves:** group tasks so that within a wave every task's dependencies are in
earlier waves and no two tasks touch the same file. List the waves.

## Self-check

- Every AC and every "test" edge case is served by at least one task and
  mapped to a test file.
- Every task serves an AC, or is marked as required setup or refactor with a
  reason.
- No two tasks in the same wave share a file.
- Every dependency points to an earlier wave.
- Every new dependency is listed under Risks.
- No open decisions: a worker would never have to choose.

## Revision mode

When `implement` reports a task `BLOCKED plan-mismatch`:

1. Read the blocked task's receipt and only the files it names.
2. If the problem is in the spec, stop and send the user to `spec` (`BLOCKED
   spec-gap`).
3. Otherwise write a new revision: bump `Revision`, add a Changelog line, and
   mark every already-committed task the change affects as `REDO`.
4. Get the user's approval again, then commit
   `chore(record): revise plan rN [NNNN]`.

`implement` reverts and rebuilds the `REDO` tasks.

## Rules

- No code beyond signatures and data shapes.
- Follow the repo's existing conventions, even where you would prefer others.
- Never change the spec. If the spec is wrong or unclear, stop with
  `BLOCKED spec-gap` and send the user back to `spec`.
- In standalone mode, stop once the plan is approved and committed.

## Done when

Every AC is covered, nothing is undecided, the user approved it, and it is
committed.

## Pipeline receipt

`plan DONE <N> tasks <W> waves` or `plan BLOCKED <reason>`.
