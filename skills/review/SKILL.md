---
name: review
description: Overkill stage 6. Independent code review by 8 parallel reviewer personas with fresh context, followed by a verifier that removes duplicates, tries to disprove every finding and assigns severity. Every finding must be fixed before a pull request opens. Use after verify passes in an Overkill run.
license: MIT
---

# review

Judges whether the code does what the spec asked for and is good code. It is
the only stage that judges, and it runs only after `verify` passes. It never
changes code.

Read `references/conventions.md` and `references/personas.md` first.

## Inputs

Every reviewer reads:

- `spec.md`, `plan.md`, `tests.md`
- The code diff for this round (see "Rounds"), excluding `.record/`
- Any repo file it needs for context

Reviewers **never** read `implementation.md` (the implementer's explanations
would bias them) or any other reviewer's findings.

## Rounds

| Round type | Diff reviewed | Reviewers |
|---|---|---|
| **Full** | Default branch merge-base → HEAD | All 8, fresh context |
| **Fix** | Last reviewed commit → HEAD, plus the code those changes touch | All 8, fresh context |
| **Final** | Same as Full | All 8, fresh context |

Sequence:

1. Round 1 is **Full**. If it comes back clear, the review is approved.
2. After findings are fixed and `verify` passes again, the next round is
   **Fix**.
3. A **Fix** round with findings → fix, verify, another **Fix** round.
4. A **Fix** round that comes back clear → one **Final** round. Findings in the
   Final round go back to step 2.
5. **Approved** only when a Full or Final round has zero findings from all 8
   reviewers and the verifier.

`run-pipeline` asks for a **Final** round directly after a rebase onto the
default branch, since the change itself was already approved.

**Safeguard:** if 3 rounds in a row have findings, stop and wait for the user.
Nothing is dropped and no pull request opens; the user decides how to proceed.

## Steps (each round)

1. **Dispatch all 8 personas in one message.** Each gets its persona section
   from `references/personas.md`, the inputs above, the round's diff range, and
   its output path `.record/NNNN-<slug>/review/round-<n>/<persona>.md`. Each
   returns one line: `<persona> CLEAR` or `<persona> FINDINGS <n>`.
2. **If all 8 are `CLEAR`,** skip to step 4.
3. **Dispatch the verifier** (one subagent, fresh context). It reads the
   round's persona files and the code they point to, then:
   - **Merges duplicates** across personas.
   - **Tries to disprove each finding** by reading the code and, where
     possible, reasoning through or running the failure scenario. Drops any it
     disproves, with a one-line reason.
   - **Assigns severity:** `blocking` (an AC unmet, wrong behavior, security
     hole, data loss), `should-fix` (a real defect risk or a meaningful cost to
     performance, reliability or maintenance), `nit` (minor clarity or naming).
   - **Resolves conflicts** between personas (e.g. Performance wants a cache,
     Maintainer wants it simpler) using the spec's constraints and the plan's
     approved decisions. If those don't settle it, marks it `ATTENTION`.
   - **Fix rounds only:** confirms each finding from the previous round is
     fixed. One that isn't becomes a finding again.
   - Writes the round section of `review.md` from `templates/review.md` and
     returns `verifier FINDINGS <n> ATTENTION <m>` or `verifier CLEAR`.
4. **Record and commit:** `chore(record): review round <n> [NNNN]`.
5. **Hand back:**
   - `ATTENTION` items → wait for the user's decision on each. A decision to
     change something becomes a finding (or a plan or spec change).
   - Findings → every one, of every severity, goes to `implement` fix mode,
     then `verify`, then the next round.
   - Clear Full or Final round → `review PASS`.

## Finding rules

- Every finding has: file and line, what is wrong, **a concrete example of how
  it fails** ("an empty list makes `total()` panic"), and a suggested fix.
- No concrete failure example, no `blocking` severity. Vague advice ("consider
  improving…") is not a finding.
- Nothing a formatter or linter already enforces.
- Decisions the user approved in the spec or plan are not reopened as
  findings. Disagreement with one is raised as `ATTENTION`, never as blocking.
- Weak tests are findings for the Test Skeptic, but fixing them changes frozen
  tests, so they always go to the user for approval. An approved change is
  fixed like any finding; a declined one is closed and recorded as the user's
  decision.

## Done when

A Full or Final round is clear from all 8 personas and the verifier, every
`ATTENTION` item is decided, and `review.md` records the verdict `approved`.

## Pipeline receipt

`review PASS round <n>` · `review FINDINGS round <n>: <count>` ·
`review WAITING attention <m>` · `review WAITING safeguard`
