#!/bin/bash
set -euo pipefail

# PASIV project initializer
# Usage: init.sh <backend> [--project-board] [--no-project-board]
# Backends: github, beans, local

BACKEND="${1:-github}"
PROJECT_BOARD="true"

for arg in "$@"; do
  case "$arg" in
    --no-project-board) PROJECT_BOARD="false" ;;
    --project-board) PROJECT_BOARD="true" ;;
  esac
done

echo "Initializing PASIV with backend: $BACKEND"

# --- Create directories ---
mkdir -p docs/designs
mkdir -p docs/plans
mkdir -p docs/handoffs/archive
mkdir -p docs/scans

for dir in docs/designs docs/plans docs/handoffs docs/handoffs/archive docs/scans; do
  [ -z "$(ls -A "$dir" 2>/dev/null)" ] && touch "$dir/.gitkeep"
done

echo "✓ Created project directories"

# --- Write .pasiv.yml ---
case "$BACKEND" in
  github)
    cat > .pasiv.yml << EOF
# PASIV Configuration
task_backend: github

github:
  project_board: $PROJECT_BOARD
EOF
    ;;
  beans)
    if ! command -v beans &>/dev/null; then
      echo "ERROR: beans CLI not found. Install it first:"
      echo "  npm install -g @beans-lang/cli"
      echo "Then run this script again."
      exit 1
    fi
    [ ! -d .beans ] && beans init
    cat > .pasiv.yml << EOF
# PASIV Configuration
task_backend: beans

beans:
  path: .beans
  prefix: beans-
EOF
    ;;
  local)
    mkdir -p docs/tasks
    [ -z "$(ls -A docs/tasks 2>/dev/null)" ] && touch docs/tasks/.gitkeep
    cat > .pasiv.yml << EOF
# PASIV Configuration
task_backend: local

local:
  path: docs/tasks
EOF
    ;;
  *)
    echo "ERROR: Unknown backend '$BACKEND'. Use: github, beans, or local"
    exit 1
    ;;
esac

echo "✓ Created .pasiv.yml ($BACKEND backend)"

# --- Append PASIV section to CLAUDE.md ---
if grep -q "## PASIV" CLAUDE.md 2>/dev/null; then
  echo "✓ CLAUDE.md already has PASIV section (skipped)"
else
  cat >> CLAUDE.md << 'PASIV_SECTION'

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

Configured in `.pasiv.yml`.

### Methodology

TDD enforced in `/kick`: RED → GREEN → REFACTOR → COMMIT. Opus writes tests (the spec), Sonnet writes code (constrained by the test). No production code without a failing test first.

Verification gate runs before every merge. Tests, build, lint, and type-check must pass with fresh evidence.

Review tiers scale with change size and security sensitivity. Five tiers from S (Sonnet, trivial) to SOC (Sonnet → Opus → Codex, security-critical).

Present your implementation plan before coding. After 3 failed fix attempts, stop and reassess architecture.

### Decision Flow

When a user request arrives, route it:

- Refining an idea? → /brainstorm
- Creating issues? → /issue, /parent, or /backlog
- Implementing an issue? → /kick 42 (or /kick next)
- Standalone review? → /s-review .. /soc-review
- Scanning a repo? → /repo-scan
- End of session? → /handoff
- None apply? → Proceed normally
PASIV_SECTION

  echo "✓ Appended PASIV section to CLAUDE.md"
fi

echo ""
echo "PASIV configured with $BACKEND backend."
echo "Run '/issue add ...' to create your first task."
