---
name: start
description: Full implementation flow - plan, implement, review, merge. Use when user says "start issue", "work on issue", "implement issue", "start #42", or wants to fully implement and merge a GitHub issue.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Start Working on Issue

Full flow for: $ARGUMENTS (issue number or "next")

## Step 1: Get Issue

```bash
gh issue view NUMBER --json title,body,labels,url
```

If "next", find highest priority:
```bash
gh issue list --label "priority:high" --state open --limit 1
```

## Step 1.5: Move to In Progress

Get project and field info, then update status:

```bash
REPO_NAME=$(gh repo view --json name -q '.name')
OWNER=$(gh repo view --json owner -q '.owner.login')
ISSUE_URL=$(gh issue view NUMBER --json url -q '.url')

# Get project number
PROJECT_NUM=$(gh project list --owner "$OWNER" --format json \
  | jq -r --arg name "$REPO_NAME" '.projects[]? | select(.title == $name) | .number' \
  | head -1)

# Get project item ID for this issue
ITEM_ID=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r --arg url "$ISSUE_URL" '.items[] | select(.content.url == $url) | .id')

# Get Status field ID and "In Progress" option ID
STATUS_FIELD=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name == "Status")')
FIELD_ID=$(echo "$STATUS_FIELD" | jq -r '.id')
IN_PROGRESS_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "In Progress") | .id')

# Update status to In Progress
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_NUM" \
  --field-id "$FIELD_ID" --single-select-option-id "$IN_PROGRESS_ID"
```

## Step 2: Create Plan

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Approach**: Step-by-step
- **Risks**: Potential issues

Ask: **"Does this plan look good?"**

Wait for approval before continuing.

## Step 3: Implement

```bash
git checkout -b feature/issue-NUMBER
```

Make the changes, then commit:

```bash
git add -A && git commit -m "feat: description (#NUMBER)"
```

## Step 4: 3-Model Review

Run the full review pipeline on the branch:

### Pass 1: Sonnet (fast)
Quick scan for obvious bugs, security basics, dead code.

### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability.

### Pass 3: Codex (independent)
Use `mcp__codex__codex`:
```
mcp__codex__codex(
  prompt: "Independent code review - catch what others missed. Review for subtle bugs, security edge cases, test gaps. Categorize as ERROR/WARNING/SUGGESTION.",
  sandbox: "read-only"
)
```

## Step 5: Fix & Iterate

If errors found:
1. Fix them
2. Commit: `git add -A && git commit -m "fix: address review findings"`
3. If errors were from Opus/Codex → restart from Pass 1
4. If errors were only from Sonnet → re-run Pass 1 only
5. Max 3 iterations before asking user

## Step 6: Merge

When all passes are clean:

```bash
git checkout main
git merge feature/issue-NUMBER
git push origin main
git branch -d feature/issue-NUMBER
gh issue close NUMBER --comment "Completed in $(git rev-parse --short HEAD)"
```

## Step 6.5: Move to Done

Update project status to Done:

```bash
# Get "Done" option ID (reuse FIELD_ID from Step 1.5)
DONE_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "Done") | .id')

# Update status to Done
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_NUM" \
  --field-id "$FIELD_ID" --single-select-option-id "$DONE_ID"
```

Report:
```
## Done

Issue #NUMBER completed and merged to main.

Review passes:
- Pass 1 (Sonnet): ✓
- Pass 2 (Opus): ✓
- Pass 3 (Codex): ✓

Commit: abc1234
```
