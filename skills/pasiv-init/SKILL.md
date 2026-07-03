---
name: pasiv-init
description: Interactive PASIV setup. Creates .pasiv.yml. Use for "pasiv init", "setup pasiv", "configure pasiv".
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Edit
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

If `.pasiv.yml` exists, Read it, display it, and ask (AskUserQuestion): "PASIV is already configured here. What do you want to do?"

- **Update (Recommended)** — ask only about settings missing from the current config; everything else untouched
- **Reconfigure** — full wizard; rewrites `.pasiv.yml` from scratch (custom keys like `model_routing` / `review.profiles` are lost — say so)
- **Cancel** — stop

**Update mode** (skip steps 2–7):

1. Compare the current file against the managed settings: `workflow.plan_approval`, `workflow.tdd`, `workflow.review`, `workflow.verification`, `workflow.ui_verify`, `workflow.auto_reflect`, `metrics.tokens`, `verify.command`, `models.coordinator`.
2. Ask the corresponding wizard question (steps 4–4.5 wording) for each **missing** key only — batch into as few AskUserQuestion calls as possible (max 4 questions per call). Nothing missing → report "config is current" and stop.
3. Patch `.pasiv.yml` with Edit: new `workflow.*` keys go inside the existing `workflow:` block; `metrics:` / `verify:` / `models:` are appended as new blocks. Do **not** run the init script.
4. Write declined booleans explicitly (`auto_reflect: false`) so they aren't re-asked next update; declined string opt-ins (`verify.command`, `models.coordinator`) stay absent and will be offered again next time.
5. Display the updated file and stop.

### 2. Choose Task Backend

**Use AskUserQuestion tool:**

**Question**: "Where do you want to track tasks?"
- Local Markdown (Recommended) — Zero dependencies, files in `docs/tasks/`
- Beans — Flat-file, version-controlled, agent-native (requires `beans` CLI)
- GitHub Issues — Team collaboration, CI integration, project boards

### 3. GitHub Project Board (if GitHub backend)

If GitHub was selected:

**Use AskUserQuestion tool:**

**Question**: "Enable GitHub Project board?"
- Yes (Recommended) — Auto-create project, track status
- No — Issues only, no project board

### 4. Workflow Options

**Use AskUserQuestion tool** — ONE call with all four questions:

1. "Require plan approval before implementation?" — Yes (Recommended): pause for approval before coding / No: auto-approve, start immediately. → PLAN_APPROVAL
2. "Use TDD (test-driven development)?" — Yes (Recommended): Opus writes tests, Sonnet implements / No: implement directly. → TDD
3. "Run code review after implementation?" — Yes (Recommended): profile-based review (quick/standard/deep) / No: skip review. → REVIEW
4. "Run verification gate before merge?" — Yes (Recommended): tests, build, lint, type-check must pass / No: merge without verification. → VERIFICATION

### 4.5. Verification Extras

**Use AskUserQuestion tool** — ONE call with all four questions:

1. "Visually verify UI changes before merge?" — Yes: for frontend/mobile tasks, drive the app and screenshot the change before the verification gate / No: rely on tests and review only. → UI_VERIFY (opt-in; some projects don't want the extra wall-clock per task)
2. "Add a project smoke command to the verification gate?" — No / Yes — type the command via Other (e.g. `npm run smoke`, `./scripts/e2e.sh`). → VERIFY_COMMAND (empty if No)
3. "Pin a coordinator model for frontier escalations and review passes?" — No (Recommended): default Opus / Yes — type the model via Other (any frontier model id your plan exposes). → COORDINATOR_MODEL (empty if No)
4. "Enable end-of-workflow extras?" — multiSelect: Token report — per-model token summary at finish, history in `docs/metrics/tokens.jsonl` / Auto-reflect — run `reflect` at finish when the task hit escalations, corrections, or review blockers. → TOKEN_REPORT / AUTO_REFLECT (both off if none selected)

### 5. Run Init Script

Find and run the PASIV init script. This creates directories, writes `.pasiv.yml`, and appends the full PASIV section to `CLAUDE.md`.

```bash
INIT_SCRIPT=$(find ~/.claude -name "init.sh" -path "*/pasiv/scripts/*" 2>/dev/null | head -1)
echo "$INIT_SCRIPT"
```

If `INIT_SCRIPT` is empty, stop and report: the PASIV plugin scripts directory wasn't found — reinstall the plugin.

Build the flags string from all choices:

- Backend: `github`, `beans`, or `local`
- If GitHub: add `--project-board` or `--no-project-board`
- If PLAN_APPROVAL is false: add `--no-plan-approval`
- If TDD is false: add `--no-tdd`
- If REVIEW is false: add `--no-review`
- If VERIFICATION is false: add `--no-verification`
- If UI_VERIFY is true: add `--ui-verify`
- If VERIFY_COMMAND is set: add `--verify-command="$VERIFY_COMMAND"`
- If COORDINATOR_MODEL is set: add `--coordinator-model="$COORDINATOR_MODEL"`
- If TOKEN_REPORT is true: add `--token-report`
- If AUTO_REFLECT is true: add `--auto-reflect`

Example: `bash "$INIT_SCRIPT" beans --no-plan-approval --ui-verify --verify-command="npm run smoke"`

### 6. Design System Setup (if frontend)

**Use AskUserQuestion tool:**

**Question**: "Does this project have a frontend?"
- Yes — Initialize design system for consistent UI
- No — Skip design system setup

If Yes:
- Check if `.interface-design/system.md` already exists
- If exists: display "Design system already configured."
- If missing and the `interface-design:init` skill is available: **Use Skill tool:** `interface-design:init`
- If missing and the skill is not installed: note "interface-design plugin not installed — skipping design system setup" and continue

### 7. Done

Display the output from the init script. Suggest adding `.pasiv.yml` to version control (it contains no secrets).
