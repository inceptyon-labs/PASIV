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

## Step 4.5: Session wrap-up (opt-ins, single-task flow only — the parent flow's router does these once at the end)

**If `TOKEN_REPORT` is true:** run the token report:

```bash
TR_SCRIPT=$(find ~/.claude -name "token-report.sh" -path "*pasiv*/scripts/*" 2>/dev/null | head -1)
[ -n "$TR_SCRIPT" ] && bash "$TR_SCRIPT" "$IDENTIFIER"
```

The script's stdout table MUST be pasted verbatim into the Step 5 report — the user reads it in the CLI; the history file is the byproduct, not the deliverable. If the script isn't found, say so in the report instead of skipping silently.

**If `AUTO_REFLECT` is true:** check whether any reflection signal fired during this task — escalation ladder used, three-strikes hit, user corrected the agent mid-run, review found blockers, plan was reworked after approval. Any signal → **Skill:** `reflect`. No signals → skip silently, don't mention it.

## Step 5: Report

```
## Done

Issue $IDENTIFIER merged to main.
Review: [REVIEW_PROFILE] · Verification: ✓ · Commit: [short SHA]

Token usage (session xxxxxxxx):                    [TOKEN_REPORT only — the
  <model>: N calls · in X · out Y · cache-read Z    script's table, verbatim]
  → docs/metrics/tokens.jsonl

Next up: [next priority issue, or "No open issues"] — run /kick next
```

In the autonomous parent flow, return control to the router instead of reporting per task — the router reports once at the end. End your response with:

```
>>> FINISH COMPLETE <<<
```
