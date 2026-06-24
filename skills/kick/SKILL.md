---
name: kick
description: Full implementation flow - plan → TDD → review → merge a GitHub issue. Use for "kick 42", "kick next", "work on issue", "implement issue". Inception "kick".
model: opus
allowed-tools:
  - Bash
  - Read
  - Write
  - Skill
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# Kick — Orchestrator

Thin router. Set up context, then sequence the step-skills: **plan → execute → review → verify → finish**. The heavy work lives in those skills and in the subagents `execute` dispatches, so this context stays lean — the whole session runs in standard 200k.

> **Launch tip:** run the PASIV session with `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` (alias or `.claude/settings.local.json`) so the Sonnet implementer subagents stay on your subscription instead of metered 1M. See `docs/reference/model-optimization.md`.

Each step-skill shares this session's context (`IDENTIFIER`, `WORKFLOW_*`, `REVIEW_PROFILE`, `PARENT_IDENTIFIER`, …) — set those here, then invoke the skills in order, waiting for each one's `>>> … COMPLETE <<<` marker before the next.

---

## Step 0: Detect backend + workflow config + issue

Read `.pasiv.yml` (`[ -f .pasiv.yml ] && cat .pasiv.yml || echo missing`):
- `TASK_BACKEND` = github | beans | local (default local). `IDENTIFIER` is the issue number / bean ID / local ID.
- Workflow flags from `workflow:` (all default **true**): `WORKFLOW_PLAN_APPROVAL`, `WORKFLOW_TDD`, `WORKFLOW_REVIEW`, `WORKFLOW_VERIFICATION`.

Get the issue. If the argument is `next` → **Skill:** `task-ops` `get-next` → `IDENTIFIER`. Then **Skill:** `task-ops` `get $IDENTIFIER` → store `IDENTIFIER`, `ISSUE_TITLE`, `ISSUE_BODY`, `ISSUE_LABELS` (github backend: also `ISSUE_URL`, used by the project-board moves in Steps 1.5 and `finish`).

## Step 0.1: Load handoff

`ls -1t docs/handoffs/handoff-*.md 2>/dev/null | head -1`. If one exists: read it, incorporate decisions/files/open-questions, follow its "Files to Load" manifest, skip its "What NOT to Re-Read", then archive it (`mv … docs/handoffs/archive/`) and state "Loaded handoff from {date}: {summary}". Else: "No active handoff found."

## Step 0.5: Sub-issues?

**Skill:** `task-ops` `get-sub-issues $IDENTIFIER`. If sub-issues exist → jump to **Parent Issue Flow**. Otherwise continue.

## Step 0.75: Baseline test run

**Skill:** `test-runner`. Pass → continue. Fail → AskUserQuestion (Fix tests first [Recommended] / Proceed anyway / Cancel); on fix, use `systematic-debugging`, re-run, commit `fix: repair baseline test failures`. No tests found → note it, continue (TDD will create them).

## Step 1–1.9: Position the work

- **1** Display "Working on $IDENTIFIER: $ISSUE_TITLE".
- **1.5** github backend: **Skill:** `project-ops` `setup` → `PROJECT_NUM`/`PROJECT_ID`, then `move-to-in-progress …`. Cascade: **Skill:** `task-ops` `get-parent $IDENTIFIER` → store `PARENT_IDENTIFIER`; move parent to In Progress (github).
- **1.75** If `PARENT_IDENTIFIER`: **Skill:** `task-ops` `get-sibling-context $PARENT_IDENTIFIER` — use the returned files/decisions/notes when planning.
- **1.9** If `ISSUE_LABELS` has `area:frontend`/`area:mobile` and `.interface-design/system.md` exists: read it → `DESIGN_SYSTEM`; reference tokens during plan + execute. Else note "No design system found".

---

## Single-Task Flow

Invoke the step-skills in order. Each reads the session context above.

1. **Skill:** `plan` — produces the plan, sets `REVIEW_PROFILE`, creates native tasks. Wait for `>>> PLAN COMPLETE <<<`.
2. **Skill:** `execute` — you (Opus) write RED; a fresh Sonnet subagent does GREEN per task; format/lint; full suite. Wait for `>>> EXECUTE COMPLETE <<<`.
3. **Skill:** `review` — runs `REVIEW_PROFILE` (skips itself if `WORKFLOW_REVIEW` false or profile `none`). Wait for `>>> REVIEW COMPLETE <<<`.
4. **Verification gate:** if `WORKFLOW_VERIFICATION` true → mark the verification task `in_progress`, **Skill:** `verification` (Haiku→Opus escalation), mark `completed`. Else skip.
5. **Skill:** `finish` — completion summary, handoff, merge, close, parent cascade, report. Wait for `>>> FINISH COMPLETE <<<`.

Done.

---

## Parent Issue Flow (Autonomous)

"Approve once, walk away." Reviews happen at the **Task level only** — Epics/Features are containers.

### Flatten to tasks

Recursively collect every leaf Task under this issue (a sub-issue with no sub-issues of its own is a Task; otherwise recurse).

### Recommend a profile per task

Per task, from size + security signal (`auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private|key`):

| Size | Default | If security |
|------|---------|-------------|
| XS | S | O [security] |
| S | O | SC [security] |
| M | SC | OC [security] |
| L | OC | SOC [security] |
| XL | SOC | SOC [security] |

### Present + baseline (once) + approve

Display the hierarchy with each Task's profile and the per-Task workflow. Run the baseline **once** for the whole Epic/Feature (`test-runner`; on failure ask as in Step 0.75).

- **`WORKFLOW_PLAN_APPROVAL` true** → AskUserQuestion: "Approve with these profiles?" → Yes (autonomous) / Customize profiles / Cancel. Store `REVIEW_PROFILES` map.
- **false** → auto-approve with recommended profiles (all `none` if `WORKFLOW_REVIEW` also false). Store `REVIEW_PROFILES`.

Move the Epic/Feature to In Progress.

### Process each task (priority order)

Order: `area:db` → `area:infra` → `area:backend` → `area:frontend`; within an area `priority:high → medium → low`. Within an Epic, process Features by the area-priority of their first Task, all Tasks in a Feature before the next.

For each Task: set `IDENTIFIER`/`PARENT_IDENTIFIER` and `REVIEW_PROFILE = REVIEW_PROFILES[task]`, then run the **same step-skills** — but **skip baseline** (already run) and **skip plan's approval gate** (pre-approved):

1. **Skill:** `task-ops` `get $IDENTIFIER`; github: `project-ops` `move-to-in-progress …`; `task-ops` `get-sibling-context $PARENT_IDENTIFIER`; load design system if UI.
2. **Skill:** `plan` — note `PLAN_PREAPPROVED=true` so it uses the given `REVIEW_PROFILE` and does **not** re-ask. Display the plan briefly.
3. **Skill:** `execute`.
4. **Skill:** `review` (uses `REVIEW_PROFILE`; skip if false/`none`).
5. **Verification gate** (as in single-task flow).
6. **Skill:** `finish` — writes the inter-task handoff and cascades parent closure; returns control here (no per-task "next up" report).

**On error in any step:** STOP, ask "Debug together / Skip this Task / Stop".

### After all tasks

Parents auto-close via `finish`'s cascade. Find the next issue (`gh issue list --label priority:high --state open --limit 1`, fallback any open) and report the Epic/Feature summary with each Task ✓ and its profile, then "Run `/kick next` to continue."
