# PASIV

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| Epic | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| Feature | Tactical | Single capability, spans days/week | "OAuth Login" |
| Task | Execution | Single work item, hours | "Create OAuth callback endpoint" |

## Commands

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

## Workflow

| You have... | Start with | Flow |
|-------------|------------|------|
| Vague idea | `/brainstorm` | → design.md → `/backlog` → `/kick` |
| Clear requirements | `/backlog spec.md` | → issues → `/kick` |
| Single task | `/issue` | → `/kick 42` |
| Existing issue | `/kick 42` | → full implementation flow |
| End of session | `/handoff` | → context preserved for next session |
| New project | `/pasiv init` | → .pasiv.yml created |

## Task Backend

Run `/pasiv init` to configure, or create `.pasiv.yml` manually. Default: github.

- **github** — GitHub Issues + Project boards. Best for team collaboration.
- **beans** — Flat-file `.beans/` directory. Agent-native, version-controlled. Requires `beans` CLI.
- **local** — Markdown files in `docs/tasks/`. Zero external dependencies.

## Methodology

TDD enforced in `/kick`: RED → GREEN → REFACTOR → COMMIT. Opus writes tests (the spec), Sonnet writes code (constrained by the test). No production code without a failing test first.

Verification gate runs before every merge. Tests, build, lint, and type-check must pass with fresh evidence. No "should work" claims.

Review tiers scale with change size and security sensitivity. Five tiers from S (Sonnet, trivial) to SOC (Sonnet → Opus → Codex, security-critical). Each pass in multi-pass reviews sees cumulative changes.

Present your implementation plan before coding. After 3 failed fix attempts, stop and reassess architecture.

## Plugin Structure

```
hooks/
├── hooks.json                  # PreCompact hook
└── pre-compact.sh              # Reminds to write handoff

skills/
├── brainstorm/SKILL.md         # /brainstorm (ideation)
├── issue/SKILL.md              # /issue
├── parent/SKILL.md             # /parent
├── kick/SKILL.md               # /kick (full flow)
├── backlog/SKILL.md            # /backlog
├── handoff/SKILL.md            # /handoff (session context)
├── pasiv-init/SKILL.md         # /pasiv init (setup wizard)
│
├── s-review/SKILL.md           # Review tiers
├── o-review/SKILL.md
├── sc-review/SKILL.md
├── oc-review/SKILL.md
├── soc-review/SKILL.md
├── codex-review/SKILL.md
├── repo-scan/SKILL.md          # /repo-scan (security)
│
├── using-pasiv/SKILL.md        # Skill awareness (session start)
├── tdd/SKILL.md                # TDD methodology (internal)
├── verification/SKILL.md       # Verification gate (internal)
├── systematic-debugging/SKILL.md
│
├── git-ops/SKILL.md            # Helper (Haiku)
├── issue-ops/SKILL.md          # GitHub backend (Haiku)
├── task-ops/SKILL.md           # Backend router (Haiku)
├── beans-ops/SKILL.md          # Beans backend (Haiku)
├── local-ops/SKILL.md          # Local backend (Haiku)
├── handoff-ops/SKILL.md        # Handoff files (Haiku)
├── project-ops/SKILL.md        # GitHub projects (Haiku)
└── test-runner/SKILL.md        # Test execution (Haiku)

docs/
├── designs/                    # Design documents from /brainstorm
├── handoffs/                   # Session handoffs from /handoff
├── plans/                      # Implementation plans
├── scans/                      # Security scan reports
└── reference/                  # Detailed docs (loaded on demand)
```

## Reference

Detailed docs loaded on demand by skills — see `docs/reference/`:

| File | Content |
|------|---------|
| `review-tiers.md` | Tier table, recommendation matrix, security file patterns |
| `methodology.md` | TDD cycle, verification gate, systematic debugging |
| `design-system.md` | interface-design integration for UI work |
| `labels.md` | Label definitions and colors |
| `github-projects.md` | Project board setup and auto-prioritization |
| `model-optimization.md` | Which models run which skills |
| `examples.md` | Detailed command examples and workflows |
| `claude-md-template.md` | Template appended to project CLAUDE.md by `/pasiv init` |
