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

# --- Write beans hooks to .claude/settings.json (beans backend only) ---
if [ "$BACKEND" = "beans" ]; then
  mkdir -p .claude
  SETTINGS=".claude/settings.json"

  if [ -f "$SETTINGS" ]; then
    # Merge beans hooks into existing settings
    if command -v jq &>/dev/null; then
      BEANS_HOOKS='{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"beans prime"}]}],"PreCompact":[{"hooks":[{"type":"command","command":"beans prime"}]}]}}'
      jq --argjson bh "$BEANS_HOOKS" '.hooks = ($bh.hooks * (.hooks // {}))' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
    else
      echo "WARNING: jq not found. Add beans hooks to $SETTINGS manually:"
      echo '  "hooks": { "SessionStart": [{ "hooks": [{ "type": "command", "command": "beans prime" }] }], "PreCompact": [{ "hooks": [{ "type": "command", "command": "beans prime" }] }] }'
    fi
  else
    cat > "$SETTINGS" << 'BEANHOOKS'
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "beans prime" }] }
    ],
    "PreCompact": [
      { "hooks": [{ "type": "command", "command": "beans prime" }] }
    ]
  }
}
BEANHOOKS
  fi
  echo "✓ Added beans prime hooks to .claude/settings.json"
fi

# --- Append PASIV section to CLAUDE.md ---
if grep -q "## PASIV" CLAUDE.md 2>/dev/null; then
  echo "✓ CLAUDE.md already has PASIV section (skipped)"
else
  cat >> CLAUDE.md << 'PASIV_SECTION'

## PASIV

### Session Start

Read the latest handoff in docs/handoffs/ if one exists. Load only the files that handoff references. If no handoff exists, check open issues/tasks for context. Before starting work, state what you understand and what you plan to do.

### Rules

1. Check if a PASIV skill applies before working manually. Do not use `EnterPlanMode` during PASIV skills — each has its own planning.
2. Write state to disk, not conversation. Before session end or compaction, run `/handoff`.
3. When switching work types (planning → implementing → reviewing), write a handoff and suggest a new session.
4. Do not silently resolve open questions. Mark them OPEN or ASSUMED.
5. No production code without a failing test first. After 3 failed fix attempts, stop and reassess.
6. Verification gate before every merge. Tests, build, lint, type-check must pass with fresh evidence.

### Where Things Live

- `.pasiv.yml` — task backend config (github, beans, or local)
- `docs/handoffs/` — session handoffs (loaded at session start, archived after use)
- `docs/designs/` — design docs from `/brainstorm`
- `docs/plans/` — implementation plans
- `docs/scans/` — security scan reports from `/repo-scan`
PASIV_SECTION

  echo "✓ Appended PASIV section to CLAUDE.md"
fi

echo ""
echo "PASIV configured with $BACKEND backend."
echo "Run '/issue add ...' to create your first task."
