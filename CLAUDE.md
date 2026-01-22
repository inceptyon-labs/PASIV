# PASIV

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| **Epic** | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| **Feature** | Tactical | Single capability, spans days/week | "OAuth Login" |
| **Task** | Execution | Single work item, hours | "Create OAuth callback endpoint" |

## Slash Commands

| Command | Creates | What it does |
|---------|---------|-------------|
| `/brainstorm` | Design doc | Socratic dialogue to refine vague ideas |
| `/brainstorm spec.md` | Design doc | Stress-test and refine existing document |
| `/issue add dark mode toggle` | Task | Create a single work item |
| `/parent user notifications` | Feature → Tasks | Create a feature with task sub-issues |
| `/backlog` | Epic → Feature → Task | Create full hierarchy from spec.md |
| `/backlog design.md` | Epic → Feature → Task | Create full hierarchy from custom spec |
| `/start 42` | - | Plan → Implement → Review → Merge |
| `/start next` | - | Work on highest priority issue |
| `/sonnet-review` | - | Quick Sonnet-only review |
| `/3pass-review` | - | Sonnet → Opus → Codex review pipeline |
| `/codex-review` | - | Codex-only deep review |

## Workflow Patterns

**Choose your entry point based on what you have:**

| You have... | Start with | Flow |
|-------------|------------|------|
| Vague idea | `/brainstorm` | → design.md → `/backlog` → `/start` |
| Half-baked plan | `/brainstorm spec.md` | → refined design → `/backlog` → `/start` |
| Clear requirements | `/backlog spec.md` | → issues → `/start` |
| Single task | `/issue` | → `/start 42` |
| Existing issue | `/start 42` | (inline planning) |

## Examples

**Refine a vague idea:**
```
/brainstorm
```
1. Socratic dialogue (one question at a time)
2. Explore 2-3 approaches with trade-offs
3. Present design in digestible chunks
4. Save to `docs/designs/YYYY-MM-DD-feature.md`
5. Offer to create issues with `/backlog`

**Stress-test existing document:**
```
/brainstorm half-baked-plan.md
```

**Create a Task:**
```
/issue add CSV export to reports page
```

**Create a Feature with Tasks:**
```
/parent user notification system with email and push
```

**Create Epics from a spec:**
```
/backlog spec.md
```

**Full implementation flow:**
```
/start 42
```
1. Read issue #42
2. Create implementation plan
3. Select review depth (Light/Medium/Full)
4. Implement using TDD (test-first)
5. Run selected review pipeline
6. Verification gate (fresh evidence)
7. Merge to main & close issue

**Parent issue (autonomous):**
```
/start 41  # parent with sub-issues
```
1. Show all sub-issues with recommended review depths
2. Approve once, walk away
3. Autonomous implementation of all sub-issues
4. Stops only on error

## Review Pipeline

Select review depth during `/start` plan approval:

| Depth | Models | When to Use | Cost |
|-------|--------|-------------|------|
| **Light** | Sonnet | Simple bugs, config, `size:S` | $ |
| **Medium** | Codex | Moderate features, `size:M` | $$ |
| **Full** | Sonnet → Opus → Codex | Complex, security-sensitive, `size:L` | $$$ |

**Smart recommendations**: Based on issue size labels and security file detection (auth, crypto, payment, token, etc.)

**Full 3-pass flow**: Sonnet → FIX → Opus → FIX → Codex → FIX → Done

| Pass | Model | Focus |
|------|-------|-------|
| 1 | Sonnet | Bugs, security basics, missing tests |
| 2 | Opus | Architecture, edge cases, performance |
| 3 | Codex | Fresh eyes, what others missed |

## Development Methodology

### TDD Cycle (enforced in `/start`)

```
RED → GREEN → REFACTOR → COMMIT → repeat
```

1. **RED**: Write failing test
2. **Verify**: Test fails for the RIGHT reason (missing feature, not syntax error)
3. **GREEN**: Write minimal code to pass
4. **Verify**: Test passes, no regressions
5. **REFACTOR**: Clean up if needed
6. **COMMIT**: After each cycle

**Iron Law**: No production code without a failing test first.

### Verification Gate (before merge)

Fresh evidence required for all claims:

| Claim | Required |
|-------|----------|
| "Tests pass" | Run `npm test`, see output |
| "Build works" | Run `npm run build`, see exit 0 |
| "Lint clean" | Run `npm run lint`, see output |

No "should work" or "was passing earlier" - run it fresh.

### Systematic Debugging (when tests fail)

1. **Investigate** - Read full error, identify root cause
2. **Hypothesize** - Form specific theory ("X fails because Y")
3. **Test** - Make ONE minimal change
4. **Verify** - Run tests again

**Three Strikes Rule**: After 3 failed fix attempts, stop and reassess architecture.

## Labels

| Category | Labels |
|----------|--------|
| Priority | `priority:high`, `priority:medium`, `priority:low` |
| Size | `size:S` (1-4h), `size:M` (4-8h), `size:L` (8+h) |
| Area | `area:frontend`, `area:backend`, `area:infra`, `area:db` |

**Note:** Issue types (Epic, Feature, Task) are set via GitHub's native `--type` flag, not labels.

## GitHub Projects Integration

Issues are automatically added to a GitHub Project board.

**Auto-created project**: Named after your repository (created on first `/issue`, `/parent`, or `/backlog`)

**Auto-prioritization**: `/backlog` outputs suggested implementation order based on:
1. Layer dependencies: `area:db` → `area:infra` → `area:backend` → `area:frontend`
2. Parent/sub-issue relationships: Parents before children
3. Explicit dependencies: `Depends on #N` in issue body

**Required token scope**:
```bash
gh auth refresh -s project
```

## Model Optimization

Simple operations run on **Haiku** in forked contexts to save tokens:

| Skill | Model | Operations |
|-------|-------|------------|
| `git-ops` | Haiku | branch, commit, push, merge |
| `issue-ops` | Haiku | create, close, check-off |
| `project-ops` | Haiku | setup, add issue, move status |

## Plugin Structure

```
hooks/
├── hooks.json                  # SessionStart hook config
└── session-start.sh            # Injects skill awareness

skills/
├── brainstorm/SKILL.md         # /brainstorm (ideation)
├── issue/SKILL.md              # /issue
├── parent/SKILL.md             # /parent
├── start/SKILL.md              # /start (full flow)
├── sonnet-review/SKILL.md      # /sonnet-review (quick)
├── 3pass-review/SKILL.md       # /3pass-review
├── codex-review/SKILL.md       # /codex-review
├── backlog/SKILL.md            # /backlog
│
├── using-pasiv/SKILL.md        # Skill awareness (injected at session start)
├── tdd/SKILL.md                # TDD methodology (internal)
├── verification/SKILL.md       # Verification gate (internal)
├── systematic-debugging/SKILL.md # Debug methodology (internal)
│
├── git-ops/SKILL.md            # Helper (Haiku)
├── issue-ops/SKILL.md          # Helper (Haiku)
└── project-ops/SKILL.md        # Helper (Haiku)

.github/
├── scripts/
│   ├── install.sh
│   └── create-labels.sh
└── workflows/
    └── version-bump.yml

docs/
├── designs/                    # Design documents from /brainstorm
└── plans/                      # Implementation plans
```
