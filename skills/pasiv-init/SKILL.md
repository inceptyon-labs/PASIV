---
name: pasiv-init
description: Interactive PASIV setup. Creates .pasiv.yml with user preferences. Use when user says "pasiv init", "setup pasiv", or "configure pasiv".
model: sonnet
allowed-tools:
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

### 3. GitHub Project Board (if GitHub backend)

If GitHub was selected:

**Use AskUserQuestion tool:**

**Question**: "Enable GitHub Project board?"
- Yes (Recommended) — Auto-create project, track status
- No — Issues only, no project board

### 4. Run Init Script

Find and run the PASIV init script. This creates directories, writes `.pasiv.yml`, and appends the full PASIV section to `CLAUDE.md`.

```bash
INIT_SCRIPT=$(find ~/.claude -name "init.sh" -path "*/pasiv/scripts/*" 2>/dev/null | head -1)
echo "$INIT_SCRIPT"
```

Then run it with the chosen backend and project board flag:

- If GitHub with project board: `bash "$INIT_SCRIPT" github --project-board`
- If GitHub without project board: `bash "$INIT_SCRIPT" github --no-project-board`
- If Beans: `bash "$INIT_SCRIPT" beans`
- If Local: `bash "$INIT_SCRIPT" local`

### 5. Design System Setup (if frontend)

**Use AskUserQuestion tool:**

**Question**: "Does this project have a frontend?"
- Yes — Initialize design system for consistent UI
- No — Skip design system setup

If Yes:
- Check if `.interface-design/system.md` already exists
- If missing: **Use Skill tool:** `interface-design:init`
- If exists: display "Design system already configured."

### 6. Done

Display the output from the init script. Suggest adding `.pasiv.yml` to version control (it contains no secrets).
