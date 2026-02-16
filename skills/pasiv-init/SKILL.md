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

Check if the project has a `CLAUDE.md`:
```bash
[ -f CLAUDE.md ] && echo "exists" || echo "missing"
```

If it exists, check if it already has a PASIV section:
```bash
grep -q "## PASIV" CLAUDE.md && echo "has-pasiv" || echo "no-pasiv"
```

If no PASIV section exists, do the following. If it already has one, skip this step.

1. Find the PASIV plugin's template file:
```bash
TEMPLATE=$(find ~/.claude -name "claude-md-template.md" -path "*/docs/reference/*" 2>/dev/null | head -1)
echo "$TEMPLATE"
```

2. Read that template file using the Read tool.

3. In the template content, replace the text `BACKEND_PLACEHOLDER` with the chosen backend name from Step 2 (github, beans, or local).

4. If `CLAUDE.md` exists in the project, append the modified template to it. If no `CLAUDE.md` exists, write a new one with the modified template as its content.

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
