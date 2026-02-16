---
name: parent
description: Create a Feature (parent issue) with Task sub-issues. Use when user says "create parent issue", "break down feature", "create feature with subtasks", or wants to implement a multi-part feature with sub-issues.
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Skill
---

# Create Feature with Tasks

Create a Feature and break into Task sub-issues: $ARGUMENTS

**This skill creates Features** - tactical work items that span days/week, broken into Tasks.

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| **Epic** | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| **Feature** | Tactical | Single capability, spans days/week | "OAuth Login" |
| **Task** | Execution | Single work item, hours | "Create OAuth callback endpoint" |

**This skill creates: Feature → Tasks** (use `/backlog` for Epics containing multiple Features)

## Label Definitions

Create missing labels before use:

| Label | Color | Description |
|-------|-------|-------------|
| `pasiv` | `1a1a2e` | Created by PASIV automation |
| `priority:high` | `DC2626` | Critical priority |
| `priority:medium` | `F59E0B` | Medium priority |
| `priority:low` | `10B981` | Low priority |
| `size:S` | `DBEAFE` | Small task (1-4 hours) |
| `size:M` | `BFDBFE` | Medium task (4-8 hours) |
| `size:L` | `93C5FD` | Large task (8+ hours) |
| `area:frontend` | `EC4899` | Web/UI changes |
| `area:backend` | `8B5CF6` | API/server changes |
| `area:infra` | `6B7280` | DevOps/CI/CD |
| `area:db` | `3B82F6` | Database schema/queries |

## Steps

1. **Detect task backend**:

```bash
[ -f .pasiv.yml ] && cat .pasiv.yml || echo "missing"
```

Store TASK_BACKEND (default: "github").

2. **Ensure labels exist** (github backend):

If TASK_BACKEND is "github":
```bash
# Get existing labels
EXISTING=$(gh label list --json name -q '.[].name')

# Create any missing labels needed for this feature
if ! echo "$EXISTING" | grep -q "^pasiv$"; then
  gh label create "pasiv" --color "1a1a2e" --description "Created by PASIV automation" --force
fi
```

3. **Setup project** (github backend only):

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `setup`
- Returns: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

4. **Create the Feature** (type: Feature):

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

5. **Create 3-7 Tasks** (type: Task, size S or M each):

For each Task:
**Use Skill tool:** `task-ops` with args: `create "Task title" "Body" "pasiv,size:S,priority:medium,area:AREA" "Task" $FEATURE_IDENTIFIER`

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $TASK_URL`

6. **Return summary** with:
- Feature identifier (URL or ID)
- All Task identifiers
- Project URL (if github backend)
