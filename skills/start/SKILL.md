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

### Cascade to Parent (if sub-issue)

```bash
# Check if this issue has a parent
PARENT_NUM=$(gh issue view NUMBER --json parent -q '.parent.number')

if [ -n "$PARENT_NUM" ]; then
  PARENT_URL=$(gh issue view "$PARENT_NUM" --json url -q '.url')
  PARENT_ITEM_ID=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json \
    | jq -r --arg url "$PARENT_URL" '.items[] | select(.content.url == $url) | .id')

  # Move parent to In Progress too (if not already)
  gh project item-edit --id "$PARENT_ITEM_ID" --project-id "$PROJECT_NUM" \
    --field-id "$FIELD_ID" --single-select-option-id "$IN_PROGRESS_ID"
fi
```

## Step 2: Create Plan

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Tests to add**: What tests will verify this works
- **Approach**: Step-by-step
- **Risks**: Potential issues

Ask: **"Does this plan look good?"**

Wait for approval before continuing.

## Step 3: Implement

```bash
git checkout -b feature/issue-NUMBER
```

Make the changes AND write tests:

1. Implement the feature/fix
2. **Write tests** that verify the acceptance criteria
3. Ensure tests cover edge cases

Commit:

```bash
git add -A && git commit -m "feat: description (#NUMBER)"
```

## Step 3.5: Run Tests

**Tests must pass before review.**

Detect test runner and run tests:

```bash
# Node.js
npm test || yarn test || pnpm test

# Python
pytest || python -m pytest

# Go
go test ./...

# Rust
cargo test

# Or check package.json/pyproject.toml for test command
```

If tests fail:
1. Fix the failing tests
2. Commit: `git add -A && git commit -m "fix: failing tests"`
3. Re-run tests until all pass

**Do not proceed to review until tests pass.**

## Step 4: 3-Model Review

Run the full review pipeline on the branch:

### Pass 1: Sonnet (fast)
Quick scan for obvious bugs, security basics, dead code, **missing tests**.

### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability, **test coverage quality**.

### Pass 3: Codex (independent)

Get the list of changed files, then run Codex:

```bash
FILES=$(git diff --name-only main)

codex --quiet "Independent code review for Issue #NUMBER.

Files changed:
$FILES

Focus on:
1. Subtle bugs or logic errors
2. Security edge cases
3. Test gaps
4. What previous reviewers missed

Categorize as ERROR/WARNING/SUGGESTION."
```

## Step 5: Fix & Iterate

If errors found:
1. Fix them
2. Commit: `git add -A && git commit -m "fix: address review findings"`
3. If errors were from Opus/Codex → restart from Pass 1
4. If errors were only from Sonnet → re-run Pass 1 only
5. Max 3 iterations before asking user

## Step 6: Check Off Acceptance Criteria

Before closing, update the issue body to check off all acceptance criteria:

```bash
# Get current issue body
BODY=$(gh issue view NUMBER --json body -q '.body')
```

Replace all `- [ ]` with `- [x]` in the Acceptance Criteria section, then update:

```bash
gh issue edit NUMBER --body "$UPDATED_BODY"
```

## Step 6.5: Final Test Run & Merge

**Run tests one final time before merge:**

```bash
# Run the test suite
npm test  # or appropriate test command
```

If tests fail, fix and re-run review cycle.

When all tests and review passes are clean:

```bash
git checkout main
git merge feature/issue-NUMBER
git push origin main
git branch -d feature/issue-NUMBER
gh issue close NUMBER --comment "Completed in $(git rev-parse --short HEAD)"
```

## Step 7: Move to Done

Update project status to Done:

```bash
# Get "Done" option ID (reuse FIELD_ID from Step 1.5)
DONE_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "Done") | .id')

# Update status to Done
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_NUM" \
  --field-id "$FIELD_ID" --single-select-option-id "$DONE_ID"
```

### Cascade to Parent (if all sub-issues done)

```bash
if [ -n "$PARENT_NUM" ]; then
  # Check if all sibling sub-issues are closed
  OPEN_SIBLINGS=$(gh issue list --parent "$PARENT_NUM" --state open --json number -q 'length')

  if [ "$OPEN_SIBLINGS" -eq 0 ]; then
    # All sub-issues done - check off parent's acceptance criteria
    PARENT_BODY=$(gh issue view "$PARENT_NUM" --json body -q '.body')
    # Replace [ ] with [x] and update parent
    gh issue edit "$PARENT_NUM" --body "$UPDATED_PARENT_BODY"

    # Move parent to Done
    gh project item-edit --id "$PARENT_ITEM_ID" --project-id "$PROJECT_NUM" \
      --field-id "$FIELD_ID" --single-select-option-id "$DONE_ID"

    # Close parent issue
    gh issue close "$PARENT_NUM" --comment "All sub-issues completed"
  fi
fi
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
