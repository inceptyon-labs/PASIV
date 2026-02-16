---
name: pasiv-init
description: Interactive PASIV setup. Creates .pasiv.yml with user preferences. Use when user says "pasiv init", "setup pasiv", or "configure pasiv".
model: sonnet
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
  - Skill
user-invocable: true
---

# PASIV Init

Interactive setup wizard for configuring PASIV in the current project.

## Steps

### 1. Check for Existing Config

```bash
[ -f .pasiv.yml ] && echo "exists" || echo "missing"
```

If `.pasiv.yml` exists:
- Read and display current config
- Ask: "Reconfigure PASIV?" (Yes / No)
- If No: stop

### 2. Choose Task Backend

**Use AskUserQuestion tool:**

**Question**: "Where do you want to track tasks?"
- GitHub Issues (Recommended) — Team collaboration, CI integration, project boards
- Beans — Flat-file, version-controlled, agent-native (requires `beans` CLI)
- Local Markdown — Zero dependencies, files in `docs/tasks/`

### 3. Scaffold Project Directories

Create all directories that PASIV skills expect. Idempotent — skips existing dirs.

```bash
mkdir -p docs/designs      # /brainstorm saves design docs here
mkdir -p docs/plans        # Implementation plans
mkdir -p docs/handoffs/archive  # /handoff saves session context here
mkdir -p docs/scans        # /repo-scan saves reports here
```

Add `.gitkeep` files so empty dirs are tracked:
```bash
for dir in docs/designs docs/plans docs/handoffs docs/handoffs/archive docs/scans; do
  [ -z "$(ls -A $dir 2>/dev/null)" ] && touch "$dir/.gitkeep"
done
```

### 4. Backend-Specific Setup

#### If GitHub selected:

**Use AskUserQuestion tool:**

**Question**: "Enable GitHub Project board?"
- Yes (Recommended) — Auto-create project, track status
- No — Issues only, no project board

Write `.pasiv.yml`:
```yaml
# PASIV Configuration
task_backend: github

github:
  project_board: true  # or false
```

#### If Beans selected:

Check if `beans` CLI is installed:
```bash
which beans 2>/dev/null && echo "installed" || echo "missing"
```

If missing: display install instructions and stop.
```
Beans CLI not found. Install it first:
  npm install -g @beans-lang/cli
Then run /pasiv init again.
```

If installed, check for existing `.beans/` directory:
```bash
[ -d .beans ] && echo "exists" || echo "missing"
```

If `.beans/` missing, run:
```bash
beans init
```

Write `.pasiv.yml`:
```yaml
# PASIV Configuration
task_backend: beans

beans:
  path: .beans
  prefix: beans-
```

#### If Local Markdown selected:

```bash
mkdir -p docs/tasks
```

Write `.pasiv.yml`:
```yaml
# PASIV Configuration
task_backend: local

local:
  path: docs/tasks
```

### 5. Add PASIV Rules to Project CLAUDE.md

Check if CLAUDE.md already has a PASIV section:
```bash
grep -q "## PASIV" CLAUDE.md 2>/dev/null && echo "has-pasiv" || echo "no-pasiv"
```

If "has-pasiv", skip to Step 6.

If "no-pasiv", run the EXACT bash command below using the Bash tool. Copy-paste it verbatim. Do NOT use the Write tool. Do NOT compose your own version of the content. The heredoc contains the complete PASIV section that must be written exactly as-is:

```bash
cat >> CLAUDE.md << 'PASIV_EOF'

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
| `/backlog` | Create Epic > Feature > Task hierarchy from spec |
| `/kick 42` | Plan > TDD > Review > Verify > Merge |
| `/kick next` | Work on highest priority open issue |
| `/handoff` | Write structured session handoff for context preservation |
| `/pasiv init` | Interactive setup wizard for task backend and config |
| `/s-review` .. `/soc-review` | Code review at tiers S, O, SC, OC, or SOC |
| `/codex-review` | Standalone Codex review |
| `/repo-scan` | Security scan a repo for vulnerabilities and secrets |

### Workflow

| You have... | Start with | Flow |
|-------------|------------|------|
| Vague idea | `/brainstorm` | > design.md > `/backlog` > `/kick` |
| Clear requirements | `/backlog spec.md` | > issues > `/kick` |
| Single task | `/issue` | > `/kick 42` |
| Existing issue | `/kick 42` | > full implementation flow |
| End of session | `/handoff` | > context preserved for next session |

### Task Backend

Configured in `.pasiv.yml`.

### Methodology

TDD enforced in `/kick`: RED > GREEN > REFACTOR > COMMIT. Opus writes tests (the spec), Sonnet writes code (constrained by the test). No production code without a failing test first.

Verification gate runs before every merge. Tests, build, lint, and type-check must pass with fresh evidence.

Review tiers scale with change size and security sensitivity. Five tiers from S (Sonnet, trivial) to SOC (Sonnet > Opus > Codex, security-critical).

Present your implementation plan before coding. After 3 failed fix attempts, stop and reassess architecture.

### Decision Flow

When a user request arrives, route it:

- Refining an idea? > /brainstorm
- Creating issues? > /issue, /parent, or /backlog
- Implementing an issue? > /kick 42 (or /kick next)
- Standalone review? > /s-review .. /soc-review
- Scanning a repo? > /repo-scan
- End of session? > /handoff
- None apply? > Proceed normally
PASIV_EOF
```

### 6. Design System Setup (if frontend)

**Use AskUserQuestion tool:**

**Question**: "Does this project have a frontend?"
- Yes — Initialize design system for consistent UI
- No — Skip design system setup

If Yes:
- Check if `.interface-design/system.md` already exists
- If missing: **Use Skill tool:** `interface-design:init`
- If exists: display "Design system already configured."

### 7. Finish

Display:
```
PASIV configured with {backend} backend.

Config saved to .pasiv.yml
Run `/issue add ...` to create your first task.
```

Suggest adding `.pasiv.yml` to version control (it contains no secrets).
