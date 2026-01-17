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

1. **Create the epic**:

```bash
gh issue create \
  --title "[EPIC] Title" \
  --body "Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ..." \
  --label "epic,priority:PRIORITY"
```

2. **Break into 3-7 child issues** (size S or M each):

```bash
gh issue create \
  --title "Subtask title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1

---
**Epic:** #EPIC_NUMBER" \
  --label "enhancement,size:S,priority:medium,area:AREA"
```

3. **Return summary** with all issue URLs.
