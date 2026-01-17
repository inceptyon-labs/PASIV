---
name: issue
description: Create a GitHub issue with size estimate and labels. Use when user says "create issue", "add issue", "new issue", "create ticket", "add task", or wants to track a single piece of work.
allowed-tools:
  - Bash
  - Read
---

# Create GitHub Issue

Create a GitHub issue from a short description: $ARGUMENTS

## Steps

1. **Assess scope**:
   - S (1-4h): Single file/component change
   - M (4-8h): Few files, moderate complexity
   - L (8+h): Suggest creating an epic instead

2. **Determine labels**:
   - Area: frontend, backend, infrastructure, database, documentation
   - Priority: high, medium, low (default: medium)

3. **Setup project**:

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

4. **Create the issue**:

```bash
ISSUE_URL=$(gh issue create \
  --title "Title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---
**Size:** S/M/L" \
  --label "enhancement,size:SIZE,priority:PRIORITY,area:AREA")
```

5. **Add to project**:

```bash
gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL"
```

6. If scope is L, ask if user wants an epic with subtasks instead.

7. Return the issue URL.
