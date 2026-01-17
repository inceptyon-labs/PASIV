---
name: issue
description: Creates a GitHub issue with automatic sizing and labeling. Use when user wants to create an issue, task, or ticket.
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

3. **Create the issue**:

```bash
gh issue create \
  --title "Title" \
  --body "Description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---
**Size:** S/M/L" \
  --label "enhancement,size:SIZE,priority:PRIORITY,area:AREA"
```

4. If scope is L, ask if user wants an epic with subtasks instead.

5. Return the issue URL.
