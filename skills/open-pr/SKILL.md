---
name: open-pr
description: Specflow stage 7. Once verify passes and review is approved, rebases onto the default branch, pushes, opens a ready-for-review pull request with a factual description built from the run's record, then watches CI and hands failures back for fixing. Use at the end of a Specflow run.
license: MIT
---

# open-pr

Publishes finished work as a pull request a reviewer can understand without
opening the run folder, then sees it through CI. No approval step: if every
condition passes, it opens the PR.

Read `references/conventions.md` first.

## Conditions (all must hold, or stop)

- `verify.md`: the latest round is `PASS`.
- `review.md`: verdict `approved`, from a Full or Final round.
- No code has changed since either of those rounds:
  `git diff <reviewed commit> HEAD -- . ':!.record'` is empty.
- No `ATTENTION` item is undecided.
- `gh` is installed and signed in (`gh auth status`). Otherwise
  `BLOCKED missing-tool:gh`.

## Steps

1. **Check the conditions above.**
2. **Rebase.** Fetch the default branch and rebase the run branch onto it.
   - Nothing new on the default branch → continue.
   - Rebased cleanly but brought in new commits → hand back
     `open-pr FAIL rebased`. `verify` and a Final review round run again on
     the rebased code, then `open-pr` starts over.
   - Conflicts → `git rebase --abort` and hand back
     `open-pr BLOCKED merge-conflict` for `implement` to resolve.
3. **Write the description** from `templates/pr.md` into
   `.record/NNNN-<slug>/pr.md`, using spec, tests, verify, review and the
   implementation log's follow-ups. Commit:
   `chore(record): pull request description [NNNN]`.
4. **Push.** `git push -u origin <branch>`. If the branch was pushed before and
   has since been rebased, use `--force-with-lease` (the run's own branch
   only).
5. **Open the PR** as ready for review, never as a draft:
   `gh pr create --base <default> --title "<title>" --body-file <pr.md>`.
   - Title: `<type>(<scope>): <summary>` from the spec.
   - GitHub issue: include `Closes #<n>`. Other trackers: include the link.
6. **Record** the PR URL in `pr.md` (and `status.md` in pipeline mode).
7. **Watch CI.** One subagent runs `gh pr checks <number> --watch` and returns
   `ci PASS`, `ci SKIPPED no checks`, or `ci FAIL <job>, <job>`. On failure it
   saves `gh run view <run-id> --log-failed` to
   `.git/specflow/logs/NNNN/ci-r<round>-<job>.log` and returns the failing jobs
   with a short excerpt each.
8. **Hand back.**
   - CI passes → `open-pr DONE <url>`.
   - CI fails → `open-pr FAIL ci round <n>: <jobs>`. The failures go to
     `implement` fix mode, then `verify`, then a review Fix round followed by a
     Final round, then `open-pr` pushes and watches CI again.
   - **Safeguard:** after 3 CI rounds in a row that fail, stop and wait for
     the user.

## Rules

- Never merge the PR.
- Never force-push a branch other people use.
- The description sticks to facts. No selling.
- In standalone mode: open the PR, watch CI once, report the result, and stop.

## Done when

The PR is open, CI is green (or there is no CI), and the user has the link.

## Pipeline receipt

`open-pr DONE <url>` · `open-pr FAIL rebased` · `open-pr FAIL ci round <n>: <jobs>` ·
`open-pr BLOCKED <reason>`
