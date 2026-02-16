---
name: issue
description: Create a GitHub issue with size estimate and labels. Use when user says "create issue", "add issue", "new issue", "create ticket", "add task", or wants to track a single piece of work.
model: haiku
allowed-tools:
  - Bash
  - Read
  - Skill
---

# Create GitHub Issue (Task)

Create a GitHub issue from a short description: $ARGUMENTS

**This skill creates Tasks** - single work items that take hours to complete.

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| **Epic** | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| **Feature** | Tactical | Single capability, spans days/week | "OAuth Login" |
| **Task** | Execution | Single work item, hours | "Create OAuth callback endpoint" |

**This skill creates: Task** (use `/parent` for Features, `/backlog` for Epics)

**Helper skills (run with Haiku in forked context for efficiency):**
- `task-ops` - Task operations router (routes to correct backend)
- `project-ops` - Project setup and adding issues (github backend only)

## Steps

1. **Detect task backend**:

```bash
[ -f .pasiv.yml ] && cat .pasiv.yml || echo "missing"
```

Store TASK_BACKEND (default: "github").

2. **Verify scope is Task-level**:
   - S (1-4h): Single file/component change → **Task**
   - M (4-8h): Few files, moderate complexity → **Task**
   - L (8+h): Multiple components → Suggest `/parent` for a **Feature** instead

3. **Determine labels**:
   - Area: frontend, backend, infra, db
   - Priority: high, medium, low (default: medium)

4. **Setup project (github backend only)**:

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `setup`
- Returns: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

5. **Create the Task**:

**Use Skill tool:** `task-ops` with args: `create "Title" "Body" "labels" "Task"`

Body format:
```
Description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---
**Size:** S/M
```

Labels: `pasiv,size:SIZE,priority:PRIORITY,area:AREA`

**Note:** Always include `pasiv` label to distinguish from user-opened issues.

6. **Add to project (github backend only)**:

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $ISSUE_URL`

7. If scope is L, ask if user wants a Feature (parent issue with sub-tasks) instead.

8. Return the issue/task URL or ID.

---

## STOP

**This skill only creates issues. Do NOT continue to implement the issue.**

If the user wants to implement the issue, they must explicitly use `/start NUMBER`.
