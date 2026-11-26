---
name: spec
description: Specflow stage 1. Turns a rough idea, bug report or issue into an approved, testable spec with Given/When/Then acceptance criteria in .record/NNNN-slug/spec.md. Use when starting any new change in a Specflow repo or when the user asks to spec an idea.
license: MIT
---

# spec

Turns a rough idea into a written spec that leaves nothing to guess and that
every later stage is checked against. It says **what** changes and **why**,
never **how** it is built.

Read `references/conventions.md` first. It defines the run folder, modes,
receipts, waiting rules, change types and git rules used below.

## Inputs

- The idea, bug report or request from the user.
- Optional: an issue from any tracker (GitHub, Linear, other). Read it if given
  and record its link.
- Optional (pipeline mode): a split outline from an earlier spec, when this run
  is part 2 or later of a split idea.

## Steps

1. **Preflight.** Confirm the working tree is clean and you are on the default
   branch, pulled to the latest commit. In pipeline mode `run-pipeline` has
   already done this.
2. **Restate.** In a few sentences: who this is for, the problem, and what
   changes for them.
3. **Classify.** Pick one change type: `feat`, `fix`, `refactor`, `chore` or
   `docs` (see conventions). Pick a slug and allocate the run number.
4. **Scan the repo.** Dispatch one subagent to look only for facts that would
   otherwise become questions (is this a CLI or a web app, what exists today,
   how the bug reproduces). It writes nothing and returns at most ten short
   lines of facts. No design work.
5. **Ask.** Up to 5 questions, asked together, only where the answer changes
   behavior. Give a suggested default for each so the user can reply
   "defaults". Skip this step if nothing is unclear.
6. **Write the spec** from `templates/spec.md` into
   `.record/NNNN-<slug>/spec.md` with status `draft`.
7. **Size check.** If the spec has more than about 10 acceptance criteria, or
   covers unrelated features, propose a split into ordered parts. Each part
   becomes its own run and its own pull request. Part 2 starts only after the
   user merges part 1. Record the parts in the spec's Split section and keep
   only part 1's criteria in this spec.
8. **Self-check** (see below). Fix anything that fails before showing it.
9. **Ask for approval.** Show the spec and wait (see "Waiting for you"). Revise
   until the user approves.
10. **On approval:** set status to `approved`, create the branch
    `<type>/<slug>` from the latest default branch, and commit the run folder:
    `chore(record): approve spec [NNNN]`.

## Acceptance criteria

- Number them `AC-1`, `AC-2`, … and write each one as Given / When / Then with
  concrete values:
  `AC-1: Given an empty cart, when the user checks out, then they see
  "Your cart is empty" and no order is created.`
- Each criterion describes one behavior the user or caller can observe.
- `fix`: include the exact reproduction steps, and one criterion stating the
  correct behavior for that reproduction. That criterion becomes the
  regression test.
- `refactor`, `chore`, `docs`: criteria state what must stay the same, e.g.
  `Given the existing test suite, when it runs, then every test passes
  unchanged.` Add specific ones for anything at risk.

## Edge cases

List empty input, invalid input, failures and limits. Mark every edge case
**test** or **no test**. Mark "test" only where a realistic bug would hide.
The user sees these marks when approving, and `write-tests` writes tests only
for edge cases marked "test".

## Self-check

- Every criterion is Given/When/Then with concrete values, and testable.
- No vague phrases ("handles errors gracefully", "fast", "user-friendly")
  without a concrete, checkable meaning.
- No file names, function names or library choices, unless the user set one as
  a constraint. Those belong to `plan`.
- Non-goals name at least one thing someone might assume is included.
- Open questions is empty.

## Rules

- Never move on while status is `draft`.
- Never design the implementation.
- In standalone mode, stop after the spec is approved and committed.

## Done when

The user has approved it, open questions is empty, status is `approved`, and
it is committed on the run branch.

## Pipeline receipt

`spec DONE <type>/<slug>` or `spec BLOCKED <reason>`.
