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

For each epic:
```bash
gh issue create \
  --title "[EPIC] Title" \
  --body "Description

## Goals
- Goal 1

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "epic,priority:PRIORITY"
```

## Step 4: Create Issues

For each task:
```bash
gh issue create \
  --title "Title" \
  --body "Description

## Acceptance Criteria
- [ ] AC 1

---
**Epic:** #NUMBER" \
  --label "enhancement,size:SIZE,priority:PRIORITY,area:AREA"
```

## Step 5: Summary

Report:
- Total epics/issues created
- Any spec gaps or questions
- Links to all items
