---
name: finish
description: Wrap up a verified task — completion summary, handoff, merge, close, parent cascade, report. Internal — called by /kick after the verification gate passes.
model: opus
user-invocable: false
allowed-tools:
  - Bash
  - Read
  - Write
  - Skill
  - TaskUpdate
  - TaskList
---

# Finish

Finalize a task whose verification gate has passed. Inputs from `/kick`: `$IDENTIFIER`, `$ISSUE_TITLE`, `TASK_BACKEND`, `PARENT_IDENTIFIER` (if any), and github project vars (`PROJECT_ID`/`PROJECT_NUM`/`OWNER`/`ISSUE_URL`).

## Step 1: Completion summary (parent tasks only)

If `PARENT_IDENTIFIER` exists, record sibling context:

**Use Skill tool:** `task-ops` with args: `add-completion-summary $IDENTIFIER "$FILES" "$DECISIONS" "$NOTES"`

- **FILES** — created/modified, from `git diff --name-only main`
- **DECISIONS** — key technical choices made (and why)
- **NOTES** — what the next sibling task needs: APIs created, patterns used, gotchas

## Step 2: Handoff (parent tasks with work remaining)

Skip for a single task or the last task in a parent. Otherwise write `docs/handoffs/handoff-$(date +%Y-%m-%d)-<slug>.md`:

```markdown
# Session Handoff: $ISSUE_TITLE
Date: <date> · Issue: $IDENTIFIER

## What was done
- Completed: $TASK_IDENTIFIER — $TASK_TITLE  [+ other tasks this session]

## Next steps (ordered)
1. [next task id + title]

## Suggested skills
- [skills the next session should invoke, e.g. pasiv:kick, pasiv:plan]
```

Apply the handoff discipline: **reference artifacts by path, don't duplicate them** (link the plan/diff/issue, don't paste them); **redact** any secrets/tokens/PII. Keep it to what the next session can't reconstruct from the repo.

## Step 3: Merge + close

**Use Skill tool:** `git-ops` with args: `merge-to-main`

**Use Skill tool:** `task-ops` with args: `close $IDENTIFIER "Completed in $(git rev-parse --short HEAD)"`

If `TASK_BACKEND` is "github":
**Use Skill tool:** `project-ops` with args: `move-to-done $PROJECT_ID $PROJECT_NUM $OWNER $ISSUE_URL`

## Step 4: Cascade to parent

If this task has a parent:
1. **Use Skill tool:** `task-ops` with args: `get-sub-issues $PARENT_IDENTIFIER`
2. If all sub-issues are closed:
   - **Use Skill tool:** `task-ops` with args: `check-off-criteria $PARENT_IDENTIFIER`
   - github backend: **Use Skill tool:** `project-ops` with args: `move-to-done ... $PARENT_URL`
   - **Use Skill tool:** `task-ops` with args: `close $PARENT_IDENTIFIER "All sub-issues completed"`

## Step 5: Report

```
## Done

Issue $IDENTIFIER merged to main.
Review: [TIER] · Verification: ✓ · Commit: [short SHA]

Next up: [next priority issue, or "No open issues"] — run /kick next
```

In the autonomous parent flow, return control to the router instead of reporting per task — the router reports once at the end. End your response with:

```
>>> FINISH COMPLETE <<<
```
