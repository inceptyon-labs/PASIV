# Model Optimization

Simple operations run on Haiku in forked contexts to save tokens.

## Model-to-Skill Mapping

| Skill | Model | Operations |
|-------|-------|------------|
| `git-ops` | Haiku | branch, commit, push, merge |
| `issue-ops` | Haiku | create, close, check-off (GitHub backend) |
| `task-ops` | Haiku | backend router for task CRUD |
| `beans-ops` | Haiku | Beans flat-file backend |
| `local-ops` | Haiku | Local markdown backend |
| `project-ops` | Haiku | setup, add issue, move status |
| `test-runner` | Haiku | run tests, parse results, report |
| `handoff-ops` | Haiku | read/archive handoff files |
| `tdd` | Sonnet | GREEN and REFACTOR phases (code writing) |
| `verification` | Haiku → Opus | simple fixes (Haiku), complex debugging (Opus) |

## Split-Model TDD

| Phase | Model | Rationale |
|-------|-------|-----------|
| RED (write test) | Opus (kick) | Tests are the spec — better model makes design decisions |
| GREEN (write code) | Sonnet (tdd) | Constrained by test, cheaper model handles volume |
| REFACTOR | Sonnet (tdd) | Tests guard against regressions |

Smart escalation: verification starts with Haiku for simple fixes, escalates to Opus only when needed for complex debugging.
