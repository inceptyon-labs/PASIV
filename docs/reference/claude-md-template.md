
## PASIV

This project uses PASIV for task management and development workflow. Before taking action on any development task, check if a PASIV skill applies. If one applies, use it instead of working manually.

Do not use `EnterPlanMode` when executing PASIV skills. Each skill has its own planning built in. Use `EnterPlanMode` only for ad-hoc work that does not fit any PASIV skill (rare).

### Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| Epic | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| Feature | Tactical | Single capability, spans days/week | "OAuth Login" |
| Task | Execution | Single work item, hours | "Create OAuth callback endpoint" |

### Commands

| Command | What it does |
|---------|-------------|
| `/brainstorm` | Refine ideas into design docs via Socratic dialogue |
| `/brainstorm spec.md` | Stress-test and refine an existing document |
| `/issue add ...` | Create a single Task |
| `/parent ...` | Create a Feature with Task sub-issues |
| `/backlog` | Create Epic → Feature → Task hierarchy from spec |
| `/kick 42` | Plan → TDD → Review → Verify → Merge |
| `/kick next` | Work on highest priority open issue |
| `/handoff` | Write structured session handoff for context preservation |
| `/pasiv init` | Interactive setup wizard for task backend and config |
| `/s-review` .. `/soc-review` | Code review at tiers S, O, SC, OC, or SOC |
| `/codex-review` | Standalone Codex review |
| `/repo-scan` | Security scan a repo for vulnerabilities and secrets |

### Workflow

| You have... | Start with | Flow |
|-------------|------------|------|
| Vague idea | `/brainstorm` | → design.md → `/backlog` → `/kick` |
| Clear requirements | `/backlog spec.md` | → issues → `/kick` |
| Single task | `/issue` | → `/kick 42` |
| Existing issue | `/kick 42` | → full implementation flow |
| End of session | `/handoff` | → context preserved for next session |

### Task Backend

Configured in `.pasiv.yml` — current backend: **BACKEND_PLACEHOLDER**.

### Methodology

TDD enforced in `/kick`: RED → GREEN → REFACTOR → COMMIT. Opus writes tests (the spec), Sonnet writes code (constrained by the test). No production code without a failing test first.

Verification gate runs before every merge. Tests, build, lint, and type-check must pass with fresh evidence.

Review tiers scale with change size and security sensitivity. Five tiers from S (Sonnet, trivial) to SOC (Sonnet → Opus → Codex, security-critical).

Present your implementation plan before coding. After 3 failed fix attempts, stop and reassess architecture.

### Decision Flow

When a user request arrives, route it:

- Refining an idea? → `/brainstorm`
- Creating issues? → `/issue`, `/parent`, or `/backlog`
- Implementing an issue? → `/kick 42` (or `/kick next`)
- Standalone review? → `/s-review` .. `/soc-review`
- Scanning a repo? → `/repo-scan`
- End of session? → `/handoff`
- None apply? → Proceed normally
