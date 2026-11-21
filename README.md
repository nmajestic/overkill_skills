# Overkill

A quality-first pipeline that every agent-written change goes through, from
rough idea to pull request. A one-line fix gets the same treatment as a new
feature: a spec, a plan, tests first, parallel implementation, automated
checks, eight independent reviewers, and a PR that only opens once everything
is fixed.

Yes, it's overkill. That's the point.

Works in **Claude Code** (as a plugin or standalone skills) and **OpenCode**
(as standalone skills), in any language.

## The pipeline

```
spec ─▶ you approve ─▶ plan ─▶ you approve ─▶ write-tests ─▶ implement
                                                                │
       PR open, CI green ◀── open-pr ◀── review ◀── verify ◀────┘
```

| # | Skill | What it does |
|---|---|---|
| 1 | `spec` | Turns an idea into a spec with Given/When/Then acceptance criteria. You approve it. |
| 2 | `plan` | Explores the codebase with up to 8 agents, asks you at every design fork with the trade-offs, and breaks the work into tasks grouped into parallel waves. You approve it. |
| 3 | `write-tests` | Writes a small, intentional set of failing tests straight from the acceptance criteria, and commits them before any code exists. |
| 4 | `implement` | Up to 8 workers build tasks in parallel, each in its own git worktree, one commit per task. |
| 5 | `verify` | Runs every check in parallel: tests, lint (warnings fail), format, type-check, build, audit and the pipeline's own rules. Never changes anything. |
| 6 | `review` | 8 reviewer personas with fresh context, then a verifier that removes duplicates and tries to disprove every finding. Every finding gets fixed. |
| 7 | `open-pr` | Rebases, pushes, opens a ready-for-review PR, and fixes CI failures. Never merges. |
| 8 | `run-pipeline` | Runs 1–7 in order, stops only where you decide, routes failures back, and resumes where it left off. |

## Principles

- **You decide twice.** You approve the spec and the plan, and every design
  fork. After that, Overkill only stops for things that need you: a test
  change, a reviewer questioning a decision you made, or a loop that won't
  settle.
- **Tests come from what you asked for,** not from the plan, so a wrong plan
  can't produce tests that agree with it. Tests are frozen once committed;
  changing one needs your approval.
- **Few, intentional tests.** One per acceptance criterion by default, each
  naming the bug it catches, within a hard budget.
- **Checking and judging are separate.** `verify` is pass/fail only; `review`
  is judgment only.
- **As parallel as possible, as lean as possible.** Up to 8 subagents at once
  in every stage. They report back in one-line receipts
  (`T3 DONE 4f2a9c1`, `lint FAIL 3 warnings`, `attacker CLEAR`), and full
  detail goes to files.
- **Everything is on the record.** Each run's spec, plan, tests, checks and
  review history is committed in `.record/`.

## Install

### Claude Code plugin

```
/plugin marketplace add nmajestic/overkill_skills
/plugin install overkill@nmajestic
```

Skills are namespaced: `/overkill:run-pipeline`, `/overkill:spec`, and so on.

### Standalone skills (Claude Code or OpenCode)

```bash
git clone https://github.com/nmajestic/overkill_skills
cd overkill_skills

scripts/install.sh --tool claude                    # ~/.claude/skills
scripts/install.sh --tool opencode                  # ~/.config/opencode/skills
scripts/install.sh --tool claude --project ~/code/app   # one project only
```

OpenCode also loads skills from `~/.claude/skills`, so one Claude install
covers both tools. Standalone skills use their plain names (`spec`, `plan`, …);
if another installed skill already has one of these names, prefer the plugin
or a project-only install.

Overkill needs `git` and, for `open-pr`, the GitHub CLI (`gh`) signed in.

## Usage

Start a run with an idea or an issue link:

```
/overkill:run-pipeline add a --json flag to the export command
```

In OpenCode, or with standalone skills, ask for it by name: "use the
run-pipeline skill to add a --json flag to the export command".

- `run-pipeline resume` — continue an interrupted run
- `run-pipeline status` — where the run is
- `run-pipeline cancel` — stop, clean up worktrees, keep the branch and record

Every stage also works on its own, for example running `review` on a branch
you wrote yourself.

## The record

```
.record/0007-checkout-flow/
  spec.md            acceptance criteria and edge cases
  plan.md            approach, decisions, interfaces, tasks, waves
  tests.md           each test and the bug it catches
  implementation.md  each task and fix, with its commit
  verify.md          every check, every round
  review.md          verdicts and findings, every round
  review/round-N/    each reviewer's raw findings
  pr.md              the pull request description
  status.md          where the run is
```

## The review panel

| Persona | Asks |
|---|---|
| Spec Auditor | Does it meet every acceptance criterion, and nothing beyond? |
| Bug Hunter | Where does it give the wrong answer? |
| Attacker | How would I abuse this? |
| Performance | What gets slow as input grows? |
| Reliability | What happens when things fail? |
| Maintainer | Will someone understand this in a year? |
| Test Skeptic | What wrong code would still pass these tests? |
| Consumer | What is it like to call or use this? |

A PR opens only after a full review where all eight come back clear.

## Repo layout

```
.claude-plugin/        plugin and marketplace manifests
skills/<name>/         SKILL.md, templates/, references/
shared/conventions.md  rules every skill shares (source of truth)
scripts/               sync-shared.sh, check.sh, install.sh
```

## Contributing

Edit `shared/conventions.md`, never the copies in `skills/*/references/`, then
run `scripts/sync-shared.sh`. Run `scripts/check.sh` before committing; CI
runs it on every push and pull request.

## License

MIT
