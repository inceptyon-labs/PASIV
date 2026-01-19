---
name: issue
description: Create a GitHub issue with size estimate and labels. Use when user says "create issue", "add issue", "new issue", "create ticket", "add task", or wants to track a single piece of work.
allowed-tools:
  - Bash
  - Read
  - Skill
---

# Create GitHub Issue

Create a GitHub issue from a short description: $ARGUMENTS

**Helper skills (run with Haiku in forked context for efficiency):**
- `issue-ops` - Issue creation
- `project-ops` - Project setup and adding issues

## Steps

1. **Assess scope**:
   - S (1-4h): Single file/component change
   - M (4-8h): Few files, moderate complexity
   - L (8+h): Suggest creating a parent issue instead

2. **Determine labels**:
   - Area: frontend, backend, infrastructure, database, documentation
   - Priority: high, medium, low (default: medium)

3. **Setup project**:

**Use Skill tool:** `project-ops` with args: `setup`

Returns: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

If project doesn't exist, it will be created.

4. **Create the issue**:

**Use Skill tool:** `issue-ops` with args: `create "Title" "Body with acceptance criteria" "labels"`

Body format:
```
Description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---
**Size:** S/M/L
```

Labels: `pasiv,enhancement,size:SIZE,priority:PRIORITY,area:AREA`

**Note:** Always include `pasiv` label to distinguish from user-opened issues.

5. **Add to project**:

**Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $ISSUE_URL`

6. If scope is L, ask if user wants a parent issue with sub-issues instead.

7. Return the issue URL.

---

## STOP

**This skill only creates issues. Do NOT continue to implement the issue.**

If the user wants to implement the issue, they must explicitly use `/start NUMBER`.
