---
name: epic
description: Creates a GitHub epic and breaks it into subtasks. Use when user wants to create a large feature, epic, or multi-part task.
allowed-tools:
  - Bash
  - Read
---

# Create GitHub Epic

Create an epic and break into tasks: $ARGUMENTS

## Steps

1. **Setup project**:

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

2. **Create the epic**:

```bash
EPIC_URL=$(gh issue create \
  --title "[EPIC] Title" \
  --body "Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "epic,priority:PRIORITY")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$EPIC_URL"
```

3. **Break into 3-7 child issues** (size S or M each), adding each to project:

```bash
CHILD_URL=$(gh issue create \
  --title "Subtask title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1

---
**Epic:** #EPIC_NUMBER" \
  --label "enhancement,size:S,priority:medium,area:AREA")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$CHILD_URL"
```

4. **Return summary** with all issue URLs.
