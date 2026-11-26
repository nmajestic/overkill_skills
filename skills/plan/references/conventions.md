# Specflow conventions

Shared rules for every Specflow skill. Each skill folder carries an identical
copy at `references/conventions.md` so it works when installed on its own.
The source of truth is `shared/conventions.md` in the Specflow repo.

## The pipeline

| # | Skill | Produces | Waits for you? |
|---|---|---|---|
| 1 | `spec` | `spec.md` | Yes, approval |
| 2 | `plan` | `plan.md` | Yes, approval and every design fork |
| 3 | `write-tests` | test files, `tests.md` | Only for test changes |
| 4 | `implement` | one commit per task, `implementation.md` | Only when `BLOCKED` |
| 5 | `verify` | `verify.md` | No |
| 6 | `review` | `review.md`, `review/` | Only for `ATTENTION` items |
| 7 | `open-pr` | pull request, `pr.md` | No |
| 8 | `run-pipeline` | runs 1–7 in order, `status.md` | — |

Every change goes through all seven stages. There is no shortcut path.

## The run folder

Each run lives in `.record/NNNN-<slug>/` and is committed with the code.

- `NNNN` is a four-digit number: one higher than the highest number found in
  `.record/` on the default branch or on any local branch
  (`git ls-tree --name-only <ref> .record/`). Start at `0001`.
- `<slug>` is a short kebab-case feature name, e.g. `checkout-flow`.

```
.record/0007-checkout-flow/
  spec.md            # spec
  plan.md            # plan
  tests.md           # write-tests
  implementation.md  # implement
  verify.md          # verify (one section per round)
  review.md          # review verdicts (one section per round)
  review/round-N/    # one findings file per persona per round
  pr.md              # open-pr
  status.md          # run-pipeline
```

Local machine state that must never be committed (the active-run marker,
worker notes, full logs) lives in `specflow/` inside the repo's git directory,
written below as `.git/specflow/`. Find the real path with
`git rev-parse --git-common-dir` (inside a worktree, `.git` is a file). Git
never tracks it, so nothing needs to be added to `.gitignore`.

## Modes

- **Pipeline mode:** the skill was started by `run-pipeline`. It hands its
  result back to `run-pipeline`, which decides what runs next.
- **Standalone mode:** you started the skill directly. It does its one job,
  reports, and stops. It never starts another stage.
- In either mode, if a file the skill needs is missing or not approved, stop
  and say which stage to run first.

## Receipts and status words

Subagents never return prose, logs or code. They write full detail to a file in
the run folder and return a receipt: one line per item.

```
<id> <STATUS>[ <detail>]
```

- `<detail>` is at most ten words. Leave it out when there is nothing to add.
- Examples: `T3 DONE 4f2a9c1` · `T5 BLOCKED plan-mismatch: total() returns Option`
  · `lint FAIL 3 warnings` · `attacker CLEAR` · `bug-hunter FINDINGS 2`

Receipt statuses:

| Word | Meaning |
|---|---|
| `PASS` | A check passed |
| `FAIL` | A check failed |
| `DONE` | A task finished and is committed |
| `BLOCKED` | Cannot continue without a decision from you or a plan change |
| `CLEAR` | A reviewer found nothing |
| `FINDINGS` | A reviewer found problems |
| `FLAKY` | A test both passed and failed on the same code (counts as a failure) |
| `CONFLICT` | A task's commit collided with another task's when merged |
| `SKIPPED` | Not applicable; only allowed when `plan.md` marks it N/A with a reason |
| `ATTENTION` | A review item that questions a decision you approved; you decide |
| `WAITING` | A stage stopped for your decision; the detail says why |

Run and stage states in `status.md`: `PENDING`, `RUNNING`, `WAITING`, `PASS`,
`FAIL`, `BLOCKED`, `DONE`, `CANCELLED`.

Standard `BLOCKED` reasons: `plan-mismatch`, `spec-gap`, `needs-test-change`,
`needs-file:<path>`, `missing-tool:<name>`, `merge-conflict`.

## Subagents

Use as many subagents as the work allows, **at most 8 running at once**.

- Claude Code: the `Agent` tool (called `Task` in older versions).
- OpenCode: the `task` tool.
- To run subagents in parallel, issue all their calls in a single message.
- More than 8 jobs: queue the rest and start each one as soon as a slot frees.
- Give each subagent only what its job needs: the file paths to read, the exact
  output file to write, and the exact receipt format to return. Tell it to
  return nothing except the receipt.
- The orchestrating agent reads receipts, not logs, diffs or code. It opens a
  detail file only when a receipt is not a pass and the next step needs it.

## Waiting for you

When a skill needs a decision (an approval, a design fork, a test change, an
`ATTENTION` item, a `BLOCKED` task, or a loop safeguard):

1. Set `status.md` to `WAITING` with a one-line reason (pipeline mode).
2. Show what needs deciding in chat, with options where there are options.
3. Stop. Continue only when you reply in chat.

There are no notifications; the run simply waits.

## Change types

`spec` sets one type per run. It decides the branch prefix and the commit type.

| Type | Use for | New tests |
|---|---|---|
| `feat` | New behavior | One per acceptance criterion |
| `fix` | A bug | A regression test that fails before the fix |
| `refactor` | Same behavior, better code | May be zero |
| `chore` | Dependencies, tooling, build | May be zero |
| `docs` | Documentation only | May be zero |

## Git

- Branch: `<type>/<slug>`, e.g. `feat/checkout-flow`, created from the latest
  default branch. Never commit to the default branch.
- Commits: Conventional Commits with the task ID when there is one:
  `feat(cart): add empty-cart check [T3]`, `fix(cart): handle null total [F2]`.
  Record-only commits use `chore(record): <what> [NNNN]`.
- Each implementation task is exactly one commit.
- Never merge a pull request. Never force-push a branch other people use.
  `--force-with-lease` is allowed only on the run's own branch after a rebase.
- One run at a time per repo. The active run is recorded in
  `.git/specflow/active` (run folder name and branch).

## Tools

- Find the repo's real commands (test, lint, format check, type-check, build,
  dependency audit) from its manifests, scripts, CI config and docs. Never
  guess when the repo says.
- Lint warnings are failures. Run linters in warnings-as-errors mode.
- A required tool that is not installed is `BLOCKED missing-tool:<name>`. Never
  skip the check instead.

## Safety

- Never read `.env` files, credential files, private keys or secret stores.
- Never write secrets, tokens or personal data into `.record/`.
- Never delete files outside the run's own scope. Never run `git clean`.
- Follow the repo's own instructions (`AGENTS.md`, `CLAUDE.md`,
  `CONTRIBUTING.md`) unless they conflict with an approved spec or plan; if they
  do, raise it with the user.
