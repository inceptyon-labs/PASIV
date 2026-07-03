---
name: backlog
description: Parse a spec/design doc and create issues from it. Use for "create issues from", "parse spec", "create backlog", or generating multiple issues from a requirements file.
model: opus
allowed-tools:
  - Bash
  - Read
  - Glob
  - Skill
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

Missing labels are created automatically by the backend on `create` (definitions: `docs/reference/labels.md`).

## Step 0: Detect Backend & Setup

**Detect task backend:**
```bash
[ -f .pasiv.yml ] && cat .pasiv.yml || echo "missing"
```

Store TASK_BACKEND (default: "local").

**If TASK_BACKEND is "github":**

Setup project:
- **Use Skill tool:** `project-ops` with args: `setup`
- Returns: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

**If TASK_BACKEND is "beans" or "local":** No project setup needed.

## Step 1: Read Spec

Read the spec file (and plan.md if exists).

## Step 1.5: Gap Pre-Flight (before decomposing)

Before mapping the spec to issues, scan for ambiguities that would decompose into vague tasks. For each real gap, surface it with a **recommended default** — don't decompose blind, don't stall:

> "The spec doesn't specify X. I'll assume Y unless you say otherwise."

Recommend an answer to every gap; the user confirms or redirects in one pass. If a gap is answerable by reading the codebase or the design doc, resolve it there — don't ask. Keep this **fast**: surface only the few gaps that would actually produce vague tasks, not a full interview (that's `/brainstorm`'s job).

Record the resolved decisions — they become each issue's context and the eventual plan's `User decisions (already made)` header, so `/kick` doesn't re-ask.

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

**Use Skill tool:** `task-ops` with args: `create "Epic: Title" "Body" "pasiv,priority:PRIORITY" "Epic"`

Body format:
```
Description

## Vision
High-level goal of this epic

## Features
- Feature 1
- Feature 2
- Feature 3

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $EPIC_URL`

Store EPIC_IDENTIFIER (issue number, bean ID, or local ID).

## Step 4: Create Features (type: Feature)

For each capability within an Epic:

**Use Skill tool:** `task-ops` with args: `create "Feature: Title" "Body" "pasiv,priority:PRIORITY,area:AREA" "Feature" $EPIC_IDENTIFIER`

Body format:
```
Description

## Goals
- Goal 1
- Goal 2

## Scope
**In Scope:** ...
**Out of Scope:** ...
```

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $FEATURE_URL`

Store FEATURE_IDENTIFIER.

## Step 5: Create Tasks (type: Task)

For each work item within a Feature:

**Use Skill tool:** `task-ops` with args: `create "Task title" "Body" "pasiv,size:SIZE,priority:PRIORITY,area:AREA" "Task" $FEATURE_IDENTIFIER`

Body format:
```
Description

## Acceptance Criteria
- [ ] AC 1
- [ ] AC 2

---
**Size:** S/M
```

If TASK_BACKEND is "github":
- **Use Skill tool:** `project-ops` with args: `add-issue $PROJECT_NUM $OWNER $TASK_URL`

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
- Any residual gaps (most resolved in the Step 1.5 pre-flight)
- Links to all items
