# Model Optimization

Simple operations run on Haiku in forked contexts to save tokens.

## Model-to-Skill Mapping

| Skill | Model | Operations |
|-------|-------|------------|
| `kick` | Opus | orchestrator/router — setup + sequence the flow |
| `plan` | Opus | plan + native tasks (writing-plans rigor, ladder, gap check) |
| `execute` | Opus (coord) | writes RED in-context; dispatches a Sonnet implementer subagent for GREEN |
| `review` | Opus (coord) | per-pass reviewer-subagent / codex dispatch by profile |
| `finish` | Opus | completion summary, handoff, merge, close, cascade |
| `git-ops` | Haiku | branch, commit, push, merge |
| `issue-ops` | Haiku | create, close, check-off (GitHub backend) |
| `task-ops` | Haiku | backend router for task CRUD |
| `beans-ops` | Haiku | Beans flat-file backend |
| `local-ops` | Haiku | Local markdown backend |
| `project-ops` | Haiku | setup, add issue, move status |
| `test-runner` | Haiku | run tests, parse results, report |
| `handoff-ops` | Haiku | read/archive handoff files |
| `verification` | Haiku → Opus | simple fixes (Haiku), complex debugging (Opus) |

## Split-Model TDD

| Phase | Model | Rationale |
|-------|-------|-----------|
| RED (write test) | Opus (`execute` coordinator) | Tests are the spec — better model makes design decisions, in-context |
| GREEN (write code) | Sonnet (`execute`'s implementer subagent) | Constrained by test; cheaper model, isolated context |
| REFACTOR | Sonnet (implementer subagent) | Tests guard against regressions |

Smart escalation: verification starts with Haiku for simple fixes, escalates to Opus only when needed for complex debugging.

## Model Tiers (optional routing)

`plan` tags each implementation task with a `modelTier` in its `json:metadata`. By default the implementer runs on Sonnet. Add a `model_routing` section to `.pasiv.yml` to map tiers → models **per host**, and `execute` resolves the implementer model from the in-progress task's tier:

```yaml
model_routing:
  mechanical: { claude: haiku,  codex: <mini model> }   # 1–2 files, complete spec
  standard:   { claude: sonnet, codex: <full model> }   # multi-file, integration
  frontier:   { claude: opus,   codex: <full model> }   # design judgment
```

- Host detected via `$CLAUDECODE` / `$CODEX_*` (same signal `review` uses).
- **Absent → behavior unchanged** (Sonnet GREEN). Dormant by default.
- Codex model IDs are whatever your Codex host exposes.
- A BLOCKED implementer bumps one tier up and re-resolves — never silently down.

This lets a well-specified mechanical task run on **Haiku** (cheaper than the flat Sonnet) and keeps a plan portable across hosts. Reviews are **not** tier-routed — the review profile already names each pass's model.

## 1M Context Gotcha (subscription cost)

The 1M context window is a **session-level beta** (`claude-opus-4-8[1m]`), negotiated when the session connects — it cannot be passed per-message or stripped per-dispatch. A subagent dispatched from a 1M parent **inherits the 1M tier but not the `/extra-usage` entitlement** for its own model. So when `execute` (Opus) dispatches its Sonnet implementer subagent under a 1M session, that worker can fail with `Extra usage is required for 1M context` or meter outside your subscription. There is no per-subagent opt-out (filed and closed not-planned).

**Fix — run the workflow on standard 200k** so every worker stays on subscription. Set the disable flag at launch (it only affects that session, not your global default):

```bash
# Launch alias (recommended — PASIV runs across many repos)
alias kick='CLAUDE_CODE_DISABLE_1M_CONTEXT=1 claude'
```

```jsonc
// Or per-project: .claude/settings.local.json (personal, gitignored)
{ "env": { "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1" } }
```

This must be set at launch — a skill or hook cannot flip it mid-session.
