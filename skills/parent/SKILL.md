---
name: parent
description: Create a Feature (parent issue) with Task sub-issues. Use for "create parent issue", "break down feature", or implementing a multi-part feature with subtasks.
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Skill
---

# Create Feature with Tasks

Create a Feature and break into Task sub-issues: $ARGUMENTS

**This skill creates Features** — tactical work items that span days/week, broken into Tasks. Use `/backlog` for Epics containing multiple Features. Missing labels are created automatically by the backend on `create` (definitions: `docs/reference/labels.md`).

## Steps

1. **Detect task backend**:

```bash
[ -f .pasiv.yml ] && cat .pasiv.yml || echo "missing"
```

Store TASK_BACKEND (default: "local").

2. **Setup project** (github backend only):

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `setup`
- Returns: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

3. **Create the Feature** (type: Feature):

Pick labels: PRIORITY = `high`/`medium`/`low` from user context (default `medium`); AREA = best match of `frontend`/`backend`/`infra`/`db`.

**Use Skill tool:** `task-ops` with args: `create "Feature: Title" "Body" "pasiv,priority:PRIORITY,area:AREA" "Feature"`

Body format:
```
Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ...
```

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $FEATURE_URL`

Store FEATURE_IDENTIFIER (issue number, bean ID, or local ID).

4. **Create 3-7 Tasks** (type: Task, size XS/S/M each — estimate per task):

For each Task:
**Use Skill tool:** `task-ops` with args: `create "Task title" "Body" "pasiv,size:SIZE,priority:PRIORITY,area:AREA" "Task" $FEATURE_IDENTIFIER`

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $TASK_URL`

5. **Return summary** with:
- Feature identifier (URL or ID)
- All Task identifiers
- Project URL (if github backend)
