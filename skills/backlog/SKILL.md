---
name: backlog
description: Parse a spec or document and create GitHub issues from it. Use when user says "create issues from", "parse spec", "create backlog", "create issues for implementing", or wants to generate multiple issues from a specification, design doc, or requirements file.
allowed-tools:
  - Bash
  - Read
  - Glob
---

# Create Backlog from Spec

Parse spec and create issues: $ARGUMENTS (file path, default: spec.md)

**This skill creates the full hierarchy**: Epics → Features → Tasks

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| **Epic** | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| **Feature** | Tactical | Single capability, spans days/week | "OAuth Login" |
| **Task** | Execution | Single work item, hours | "Create OAuth callback endpoint" |

**Mapping spec to hierarchy:**
- Major sections/milestones → **Epics**
- Capabilities within each section → **Features** (children of Epic)
- Individual work items → **Tasks** (children of Feature)

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

## Step 0: Setup Project & Labels

**Ensure labels exist:**
```bash
# Get existing labels
EXISTING=$(gh label list --json name -q '.[].name')

# Create any missing labels from the table above
# Example:
if ! echo "$EXISTING" | grep -q "^pasiv$"; then
  gh label create "pasiv" --color "1a1a2e" --description "Created by PASIV automation" --force
fi
```

**Setup project:**

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

## Step 2: Analyze & Map to Hierarchy

Break down the spec using the Issue Type Hierarchy:

| Spec Element | Issue Type | Count |
|--------------|------------|-------|
| Major sections/milestones | Epic | 2-5 |
| Capabilities per section | Feature | 2-5 per Epic |
| Work items per capability | Task | 2-7 per Feature |

Each issue needs:
- Clear title (prefixed with type for Epics/Features)
- Description
- Acceptance criteria (checkboxes) for Tasks
- Size estimate (Tasks only)
- Area label

## Step 3: Create Epics (type: Epic)

For each major section/milestone:
```bash
EPIC_URL=$(gh issue create \
  --title "Epic: Title" \
  --body "Description

## Vision
High-level goal of this epic

## Features
- Feature 1
- Feature 2
- Feature 3

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2" \
  --label "pasiv,priority:PRIORITY" \
  --type "Epic")

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$EPIC_URL"
```

Extract Epic issue number from URL.

## Step 4: Create Features (type: Feature)

For each capability within an Epic:
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
  --type "Feature" \
  --parent $EPIC_NUMBER)

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$FEATURE_URL"
```

Extract Feature issue number from URL.

## Step 5: Create Tasks (type: Task)

For each work item within a Feature:
```bash
TASK_URL=$(gh issue create \
  --title "Task title" \
  --body "Description

## Acceptance Criteria
- [ ] AC 1
- [ ] AC 2

---
**Size:** S/M" \
  --label "pasiv,size:SIZE,priority:PRIORITY,area:AREA" \
  --type "Task" \
  --parent $FEATURE_NUMBER)

gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$TASK_URL"
```

## Step 6: Suggested Implementation Order

After creating all issues, output a prioritized list based on:

1. **Layer order** (foundation first):
   - area:db (1st)
   - area:infra (2nd)
   - area:backend (3rd)
   - area:frontend (4th)

2. **Hierarchy**: Epics → Features → Tasks (but implement Tasks first within each Feature)

3. **Dependencies**: Issues with "Depends on #N" come after their dependency

Format:
```
## Suggested Implementation Order

### Epic: User Authentication (#10)

#### Feature: Email/Password Login (#11)
1. #14 - Create user table (area:db, size:S)
2. #15 - Create auth endpoint (area:backend, size:M)
3. #16 - Create login form (area:frontend, size:S)

#### Feature: OAuth Login (#12)
4. #17 - Add OAuth config (area:backend, size:S)
...
```

## Step 7: Summary

Report:
- Total Epics/Features/Tasks created
- Project URL
- Suggested implementation order
- Any spec gaps or questions
- Links to all items
