@AGENTS.md

---

# Claude-specific additions

## Task Backend Setup

Run `/pasiv init` to configure, or create `.pasiv.yml` manually. Default: local (github/beans opt-in).

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
| `/reflect` | Persist durable facts, corrections, and reusable workflows from the session |
| `/pasiv init` | Interactive setup wizard for task backend and config |
| `/review [profile]` | Review the diff at a depth — quick/standard/fast/deep/codex |

Standalone utilities (`/repo-scan`, `/repo-ready`, `/app-store-ready`, `/de-vibe`, `/nano-banana`) live in the separate `pasiv-extras` plugin — install ad hoc via `/plugin install pasiv-extras@pasiv`.

## Workflow

| You have... | Start with | Flow |
|-------------|------------|------|
| Vague idea | `/brainstorm` | → design.md → `/backlog` → `/kick` |
| Clear requirements | `/backlog spec.md` | → issues → `/kick` |
| Single task | `/issue` | → `/kick 42` |
| Existing issue | `/kick 42` | → full implementation flow |
| End of session | `/handoff` | → context preserved for next session |
| New project | `/pasiv init` | → .pasiv.yml created |

## Methodology

TDD enforced in `/kick`: RED → GREEN → REFACTOR → COMMIT. The `execute` coordinator (Opus) writes RED tests in-context; a fresh Sonnet implementer subagent does GREEN (constrained by the test) in an isolated context — keeping the session in standard 200k. No production code without a failing test first.

Verification gate runs before every merge. Tests, build, lint, and type-check must pass with fresh evidence — plus an optional project smoke command (`verify.command`) and, for UI tasks, an optional drive-the-app check (`workflow.ui_verify`), both opt-in via `.pasiv.yml`. No "should work" claims.

Review runs as profiles (`quick`/`standard`/`fast`/`deep`, configurable in `.pasiv.yml`) scaled to change size and security sensitivity. Passes are cascading (each sees cumulative changes; `fast` runs its pair concurrently instead) and host-aware (Claude or Codex as the reviewer).

Present your implementation plan before coding. After 3 failed fix attempts, stop and reassess architecture.

## Plugin Structure

```
hooks/
├── hooks.json                  # PreCompact + UserPromptSubmit + PreToolUse + PostToolUse + Stop
├── pre-compact.sh              # Reminds to write handoff
├── kick-guard.sh               # Enforces step-skill invocation + arms kick state on /kick
├── post-skill.sh               # Advances kick state on every step-skill invocation
├── stop-guard.sh               # Bounces turn-end while a kick is mid-flight
└── plan-approval-guard.sh      # Denies plan approval until the plan was displayed

scripts/                        # Deterministic tooling (found via *pasiv*/scripts/ pattern)
├── init.sh                     # Project initializer
├── read-config.sh              # .pasiv.yml → KEY=VALUE (kick Step 0)
├── kick-state.sh               # Kick turn-discipline state machine (hooks + skills)
├── verify-checks.sh            # Detect + run all checks concurrently (verification)
└── token-report.sh             # Per-model token summary + history (finish)

skills/
├── brainstorm/SKILL.md         # /brainstorm (ideation)
├── issue/SKILL.md              # /issue
├── parent/SKILL.md             # /parent
├── backlog/SKILL.md            # /backlog
├── handoff/SKILL.md            # /handoff (session context)
├── reflect/SKILL.md            # /reflect (persist learnings)
├── pasiv-init/SKILL.md         # /pasiv init (setup wizard)
│
│   # /kick flow — thin router + on-demand step-skills
├── kick/SKILL.md               # orchestrator/router
├── plan/SKILL.md               # plan + native tasks
├── execute/SKILL.md            # RED in-context → Sonnet subagent GREEN
├── review/SKILL.md             # /review — profile-driven, host-aware
├── finish/SKILL.md             # merge / handoff / close
│
├── using-pasiv/SKILL.md        # Skill awareness (session start)
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

extras/skills/                  # pasiv-extras plugin (ad hoc, not core workflow)
├── repo-scan/ · repo-ready/ · app-store-ready/ · de-vibe/ · nano-banana/

docs/
├── designs/                    # Design documents from /brainstorm
├── handoffs/                   # Session handoffs from /handoff
├── scans/                      # Security scan reports
└── reference/                  # Detailed docs (loaded on demand)
```

## Reference

Detailed docs loaded on demand by skills — see `docs/reference/`:

| File | Content |
|------|---------|
| `review-profiles.md` | Profiles, recommendation rule, engine adapters, security patterns |
| `design-system.md` | interface-design integration for UI work |
| `labels.md` | Label definitions and colors |
| `github-projects.md` | Project board setup and auto-prioritization |
| `model-optimization.md` | Which models run which skills |
