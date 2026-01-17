---
name: backlog
description: Parse a spec file and create GitHub epics and issues. Use when user wants to create backlog, parse spec, or bootstrap project.
allowed-tools:
  - Bash
  - Read
  - Glob
---

# Create Backlog from Spec

Parse spec and create issues: $ARGUMENTS (file path, default: spec.md)

## Step 0: Setup Project

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

## Step 1: Read Spec

Read the spec file (and plan.md if exists).

## Step 2: Analyze

Break down into:
- **Epics**: 3-7 major features/milestones
- **Issues**: 3-10 tasks per epic (size S or M)

Each issue needs:
- Clear title
- Description
- Acceptance criteria (checkboxes)
- Size estimate
- Area label

## Step 3: Create Epics

For each epic, create and add to project:
```bash
EPIC_URL=$(gh issue create \
  --title "[EPIC] Title" \
  --body "Description

## Goals
- Goal 1

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "epic,priority:PRIORITY")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$EPIC_URL"
```

## Step 4: Create Issues

For each task, create and add to project:
```bash
ISSUE_URL=$(gh issue create \
  --title "Title" \
  --body "Description

## Acceptance Criteria
- [ ] AC 1

---
**Epic:** #NUMBER" \
  --label "enhancement,size:SIZE,priority:PRIORITY,area:AREA")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL"
```

## Step 5: Suggested Implementation Order

After creating all issues, output a prioritized list based on:

1. **Layer order** (foundation first):
   - area:db (1st)
   - area:infra (2nd)
   - area:backend (3rd)
   - area:frontend (4th)

2. **Epic relationships**: Parent epics before their children

3. **Dependencies**: Issues with "Depends on #N" come after their dependency

Format:
```
## Suggested Implementation Order

1. #12 - Database schema (area:db)
2. #15 - Auth service setup (area:backend, depends on #12)
3. #18 - Login page (area:frontend, depends on #15)
...
```

## Step 6: Summary

Report:
- Total epics/issues created
- Project URL
- Suggested implementation order
- Any spec gaps or questions
- Links to all items
