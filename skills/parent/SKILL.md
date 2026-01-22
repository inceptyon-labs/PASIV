---
name: parent
description: Create a Feature (parent issue) with Task sub-issues. Use when user says "create parent issue", "break down feature", "create feature with subtasks", or wants to implement a multi-part feature with sub-issues.
model: sonnet
allowed-tools:
  - Bash
  - Read
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

1. **Ensure labels exist**:

```bash
# Get existing labels
EXISTING=$(gh label list --json name -q '.[].name')

# Create any missing labels needed for this feature
# Check each label you plan to use and create if missing
# Example:
if ! echo "$EXISTING" | grep -q "^pasiv$"; then
  gh label create "pasiv" --color "1a1a2e" --description "Created by PASIV automation" --force
fi
```

2. **Setup project**:

```bash
REPO_NAME=$(gh repo view --json name -q '.name')
OWNER=$(gh repo view --json owner -q '.owner.login')
```

Check for existing projects:
```bash
gh project list --owner "$OWNER" --format json
```

**Logic:**
- If a project named "$REPO_NAME" exists → use it
- If no projects exist → create one named "$REPO_NAME"
- If other projects exist (different names) → **ask user**: use existing (list them) or create new "$REPO_NAME"?

Create project if needed:
```bash
gh project create --owner "$OWNER" --title "$REPO_NAME" --format json | jq -r '.number'
```

3. **Create the Feature** (type: Feature):

```bash
FEATURE_URL=$(gh issue create \
  --title "Feature: Title" \
  --body "Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "pasiv,priority:PRIORITY,area:AREA" \
  --type "Feature")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$FEATURE_URL"
```

Extract Feature issue number from URL.

4. **Create 3-7 Tasks** (type: Task, size S or M each):

```bash
TASK_URL=$(gh issue create \
  --title "Task title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1" \
  --label "pasiv,size:S,priority:medium,area:AREA" \
  --type "Task" \
  --parent $FEATURE_NUMBER)

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$TASK_URL"
```

5. **Return summary** with:
- Feature issue URL
- All Task sub-issue URLs
- Project URL
