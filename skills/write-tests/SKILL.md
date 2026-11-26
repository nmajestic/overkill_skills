---
name: write-tests
description: Specflow stage 3. Writes a small, intentional set of failing tests straight from an approved spec's acceptance criteria, before any implementation, and commits them as their own commit. Use after a plan is approved in a Specflow run.
license: MIT
---

# write-tests

Turns acceptance criteria into tests that fail now and will pass once the
feature does what the spec says. This checks the code against what the user
**asked for**, independently of how the plan chose to build it.

Read `references/conventions.md` first.

## Inputs

- `spec.md` (approved): acceptance criteria and edge cases marked "test".
- From `plan.md` (approved), **only**: the Context section's test conventions,
  the Interfaces section, the Coverage table's test file paths, and the test
  command. Never pass the plan's Approach, Tasks or Waves to test writers, so
  the tests cannot inherit the plan's mistakes.

## Few, intentional tests

- **One test per AC by default.** A second only if the AC holds two separate
  behaviors.
- **Edge cases only when the spec marks them "test".**
- **Every test names the bug it would catch,** in `tests.md`. If no realistic
  bug comes to mind, cut the test.
- **Behavior over internals.** Test through public interfaces: what a user or
  caller observes.
- **Never test** what the compiler, type system or framework already
  guarantees, trivial getters and setters, or anything the spec didn't ask for.
- **Budget:** number of new tests ≤ number of ACs + edge cases marked "test".
  Going over needs the user's approval.
- **Fake only what's outside the code's control** (network, clock, external
  services). Never fake the code under test.
- **Deterministic:** no real network, no sleeps, fixed seeds and times.

## By change type

- `feat`: as above.
- `fix`: a regression test that reproduces the spec's reproduction steps and
  fails on the current code for that exact reason.
- `refactor`, `chore`, `docs`: zero new tests is allowed when the criteria only
  say existing behavior is unchanged. Run the existing suite to record a
  passing baseline. Add a test only for a criterion that names a specific
  at-risk behavior the suite doesn't cover.

## Steps

1. **Stubs first (one subagent).** If the tests won't compile or import without
   the new code, create bare stubs from the plan's Interfaces: correct
   signatures and types, no logic (`todo!()`, `raise NotImplementedError`,
   `throw new Error("not implemented")`). Receipt: `stubs DONE <n> files` or
   `stubs SKIPPED`.
2. **Write tests in parallel.** Group criteria by the test file the plan's
   Coverage table assigns. Dispatch one subagent per test file, up to 8 at
   once, in one message. Each gets: its criteria and edge cases, the
   interfaces, the test conventions, and its one file path. It writes only
   that file and returns `<file> DONE <n> tests`.
3. **Run the tests (one subagent).** It runs the test command and reports one
   line per new test: `<test> FAIL <reason>` or `<test> PASS`, plus
   `existing PASS` or `existing FAIL <n>`.
4. **Check each failure is the right kind.** A failed assertion or an
   unimplemented stub is right. A syntax error, wrong import or missing fixture
   is wrong: fix the test and rerun.
5. **Flag tests that already pass.** Either the behavior exists already or the
   test is too weak. Strengthen or cut it; if the behavior really exists, stop
   and tell the user (`BLOCKED spec-gap`).
6. **Existing tests must still pass.** If stubs broke any, fix the stubs.
7. **Write `tests.md`** from `templates/tests.md`.
8. **Commit** tests and stubs together, before any implementation:
   `test(<scope>): add failing tests for <slug> [NNNN]`. Record the commit
   hash and the list of test files in `tests.md`. Those test files are now
   frozen. Stub files are not frozen: `implement` fills them in.

## Test changes after this stage

Tests are frozen once committed. Any later change to a frozen test file, by
any stage, needs the user's approval first. Ask with: the
test, the proposed change, and why. Log each approved change in `tests.md`.
`verify` fails any unapproved change.

No approval stop otherwise: show a short summary and continue.

## Done when

Every AC (and every "test" edge case) has a test, every new test fails for the
right reason, every existing test passes, the budget holds, and the tests are
committed.

## Pipeline receipt

`write-tests DONE <n> tests <hash>` or `write-tests BLOCKED <reason>`.
