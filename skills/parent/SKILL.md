---
name: parent
description: Creates a parent issue with sub-issues. Use when user wants to create a large feature or multi-part task.
allowed-tools:
  - Bash
  - Read
---

# Create Parent Issue with Sub-issues

Create a parent issue and break into sub-issues: $ARGUMENTS

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

2. **Create the parent issue**:

```bash
PARENT_URL=$(gh issue create \
  --title "Title" \
  --body "Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "priority:PRIORITY")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$PARENT_URL"
```

Extract parent issue number from URL.

3. **Create 3-7 sub-issues** (size S or M each):

```bash
SUB_URL=$(gh issue create \
  --title "Sub-issue title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1" \
  --label "enhancement,size:S,priority:medium,area:AREA" \
  --parent PARENT_NUMBER)

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$SUB_URL"
```

4. **Return summary** with:
- Parent issue URL
- All sub-issue URLs
- Project URL
