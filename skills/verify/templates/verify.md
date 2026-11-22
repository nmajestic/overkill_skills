# Verify: <title>

- **Run:** NNNN-<slug>

## Round <n> — <commit hash> — <PASS | FAIL>

| Check | Command | Status | Excerpt |
|---|---|---|---|
| clean-tree | git status --porcelain | PASS | |
| tests | <…> | PASS | |
| lint | <…> | FAIL | 3 warnings: unused variable `x` |
| format | <…> | PASS | |
| type-check | <…> | SKIPPED | N/A in plan: <reason> |
| build | <…> | PASS | |
| audit | <…> | PASS | |
| ac-tests | — | PASS | |
| test-budget | — | PASS | |
| frozen-tests | — | PASS | |
| deps | — | PASS | |
| hygiene | — | PASS | |
| secrets | <gitleaks or pattern scan> | PASS | |

Sent to implement: <failing checks, or "nothing">
