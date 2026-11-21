# Plan: <title>

- **Run:** NNNN-<slug>
- **Spec:** spec.md (approved)
- **Revision:** 1
- **Status:** draft

## Context

- **Key files:** <path — why it matters>
- **Conventions to follow:** <naming, error handling, logging, layout>
- **Reuse:** <existing helpers to use instead of writing new ones>
- **Landmines:** <coupling, fragile code, surprises>

## Commands

| Check | Command | Notes |
|---|---|---|
| test | <e.g. cargo test> | |
| lint | <e.g. cargo clippy --all-targets -- -D warnings> | warnings are errors |
| format | <e.g. cargo fmt --check> | check only |
| type-check | <…> | N/A + reason if none exists |
| build | <…> | |
| audit | <e.g. cargo audit> | N/A + reason if none exists |
| ci | <workflow files CI runs> | |

## Approach

<The chosen design in a few sentences.>

### Decisions

| Fork | Chosen | Rejected | Why (user's decision) |
|---|---|---|---|

## Interfaces

```
<exact new or changed signatures, types, data shapes, routes, config keys>
```

## Tasks

### T1: <title>
- **Commit:** `<type>(<scope>): <summary> [T1]`
- **Files:** `CREATE path/a`, `MODIFY path/b`
- **Depends on:** —
- **Serves:** AC-1, E-2
- **Change:** <exactly what to do>
- **Done check:** <how to know it's finished>

## Waves

| Wave | Tasks |
|---|---|
| 1 | T1, T2, T3 |
| 2 | T4 |

## Coverage

| AC / edge case | Tasks | Test file |
|---|---|---|
| AC-1 | T1, T4 | <path> |

## Risks

- <What could break, migrations, breaking changes, new dependencies.>

## Changelog

- r1: initial plan
