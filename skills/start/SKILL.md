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

## Step 0: Get Issue Details

**IMPORTANT: Always fetch full issue details first to ensure reliable lookup.**

```bash
# Get the issue number (from argument or find next priority)
if [ "$ARGUMENTS" = "next" ]; then
  ISSUE_NUM=$(gh issue list --label "priority:high" --state open --limit 1 --json number -q '.[0].number')
  [ -z "$ISSUE_NUM" ] && ISSUE_NUM=$(gh issue list --state open --limit 1 --json number -q '.[0].number')
else
  ISSUE_NUM=$ARGUMENTS  # e.g., "42" or "#42"
  ISSUE_NUM=${ISSUE_NUM#\#}  # Remove # prefix if present
fi

# Fetch issue details using gh's built-in -q flag (avoids jq control character issues)
ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --json title -q '.title')
ISSUE_URL=$(gh issue view "$ISSUE_NUM" --json url -q '.url')
ISSUE_STATE=$(gh issue view "$ISSUE_NUM" --json state -q '.state')
ISSUE_LABELS=$(gh issue view "$ISSUE_NUM" --json labels -q '[.labels[].name] | join(",")')

# For body content, read directly (gh -q handles escaping)
ISSUE_BODY=$(gh issue view "$ISSUE_NUM" --json body -q '.body')

echo "Issue #$ISSUE_NUM: $ISSUE_TITLE"
```

## Step 0.5: Check for Sub-Issues (Parent Detection)

**If this is a parent issue with sub-issues, work through each sub-issue sequentially.**

```bash
# Check if this issue has sub-issues
SUB_ISSUES=$(gh issue list --parent "$ISSUE_NUM" --state open --json number,title -q '.')

if [ "$(echo "$SUB_ISSUES" | jq 'length')" -gt 0 ]; then
  echo "This is a parent issue with sub-issues:"
  echo "$SUB_ISSUES" | jq -r '.[] | "  - #\(.number): \(.title)"'

  # Get prioritized order (by labels: area:db → area:infra → area:backend → area:frontend)
  # Then work through each one
fi
```

**If sub-issues exist:**
1. Move parent to In Progress (Step 1.5)
2. For each sub-issue (in priority order):
   - Run Steps 1-7 for that sub-issue
   - After completing, continue to next sub-issue
3. After all sub-issues done, parent auto-closes (Step 7 cascade)

**If no sub-issues:** Continue with normal flow below.

---

## Step 1: Confirm Working Issue

Use the issue data already fetched in Step 0:

```bash
echo "Working on Issue #$ISSUE_NUM: $ISSUE_TITLE"
echo "URL: $ISSUE_URL"
```

## Step 1.5: Move to In Progress

Get project and field info, then update status:

```bash
REPO_NAME=$(gh repo view --json name -q '.name')
OWNER=$(gh repo view --json owner -q '.owner.login')
# ISSUE_URL already set from Step 0

# Get project number AND node ID (item-edit needs the node ID, not number)
PROJECT_DATA=$(gh project list --owner "$OWNER" --format json \
  | jq -r --arg name "$REPO_NAME" '.projects[]? | select(.title == $name)')
PROJECT_NUM=$(echo "$PROJECT_DATA" | jq -r '.number')
PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.id')  # Node ID like PVT_kwDO...

# Get project item ID for this issue
ITEM_ID=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r --arg url "$ISSUE_URL" '.items[] | select(.content.url == $url) | .id')

# Get Status field ID and "In Progress" option ID
STATUS_FIELD=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name == "Status")')
FIELD_ID=$(echo "$STATUS_FIELD" | jq -r '.id')
IN_PROGRESS_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "In Progress") | .id')

# Update status to In Progress (use PROJECT_ID not PROJECT_NUM)
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$FIELD_ID" --single-select-option-id "$IN_PROGRESS_ID"
```

### Cascade to Parent (if sub-issue)

```bash
# Check if this issue has a parent
PARENT_NUM=$(gh issue view "$ISSUE_NUM" --json parent -q '.parent.number')

if [ -n "$PARENT_NUM" ]; then
  PARENT_URL=$(gh issue view "$PARENT_NUM" --json url -q '.url')
  PARENT_ITEM_ID=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json \
    | jq -r --arg url "$PARENT_URL" '.items[] | select(.content.url == $url) | .id')

  # Move parent to In Progress too (use PROJECT_ID not PROJECT_NUM)
  gh project item-edit --id "$PARENT_ITEM_ID" --project-id "$PROJECT_ID" \
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

**Use AskUserQuestion tool** to get approval:

```
AskUserQuestion(
  questions: [{
    question: "Does this implementation plan look good?",
    header: "Plan",
    options: [
      { label: "Approve", description: "Proceed with implementation" },
      { label: "Revise", description: "I have changes to suggest" },
      { label: "Cancel", description: "Don't implement this" }
    ],
    multiSelect: false
  }]
)
```

- If **Approve**: Continue to Step 3
- If **Revise**: Ask what to change, update plan, ask again
- If **Cancel**: Stop and explain why

## Step 3: Implement

```bash
git checkout -b feature/issue-$ISSUE_NUM
```

Make the changes AND write tests:

1. Implement the feature/fix
2. **Write tests** that verify the acceptance criteria
3. Ensure tests cover edge cases

Commit:

```bash
git add -A && git commit -m "feat: description (#$ISSUE_NUM)"
```

## Step 3.25: Format & Lint

**Run formatters first, then linters.**

Detect and run formatters:

```bash
# Node.js / TypeScript
npx prettier --write . || npm run format || yarn format

# Python
black . || ruff format .

# Go
go fmt ./...

# Rust
cargo fmt
```

Then run linters:

```bash
# Node.js / TypeScript
npx eslint --fix . || npm run lint || yarn lint

# Python
ruff check --fix . || flake8 .

# Go
golangci-lint run

# Rust
cargo clippy --fix
```

If formatting/linting made changes:
```bash
git add -A && git commit -m "style: format and lint"
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

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

### Pass 1: Sonnet (fast)
Quick scan for bugs, security basics, missing error handling, **missing tests**.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error
2. Commit: `git add -A && git commit -m "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability, **test coverage quality**.

**STOP after Pass 2.** If any ERRORs:
1. Fix each error
2. Commit: `git add -A && git commit -m "fix: address Opus review findings"`
3. Then proceed to Pass 3

### Pass 3: Codex (independent)

**IMPORTANT: Use the custom prompt, NOT `codex review --base main`.**

```bash
DIFF=$(git diff main)

codex exec -s read-only "Independent code review for Issue #$ISSUE_NUM.

Here is the diff:
$DIFF

Focus on:
1. Subtle bugs or logic errors
2. Security edge cases
3. Test gaps
4. What previous reviewers missed

Categorize as ERROR/WARNING/SUGGESTION."
```

**STOP after Pass 3.** If any ERRORs:
1. Fix each error
2. Commit: `git add -A && git commit -m "fix: address Codex review findings"`

## Step 6: Check Off Acceptance Criteria

Before closing, update the issue body to check off all acceptance criteria:

```bash
# Get current issue body (refresh from server)
BODY=$(gh issue view "$ISSUE_NUM" --json body -q '.body')
```

Replace all `- [ ]` with `- [x]` in the Acceptance Criteria section, then update:

```bash
gh issue edit "$ISSUE_NUM" --body "$UPDATED_BODY"
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
git merge feature/issue-$ISSUE_NUM
git push origin main
git branch -d feature/issue-$ISSUE_NUM
gh issue close "$ISSUE_NUM" --comment "Completed in $(git rev-parse --short HEAD)"
```

## Step 7: Move to Done

Update project status to Done:

```bash
# Get "Done" option ID (reuse FIELD_ID from Step 1.5)
DONE_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "Done") | .id')

# Update status to Done (use PROJECT_ID not PROJECT_NUM)
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
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

    # Move parent to Done (use PROJECT_ID not PROJECT_NUM)
    gh project item-edit --id "$PARENT_ITEM_ID" --project-id "$PROJECT_ID" \
      --field-id "$FIELD_ID" --single-select-option-id "$DONE_ID"

    # Close parent issue
    gh issue close "$PARENT_NUM" --comment "All sub-issues completed"
  fi
fi
```

Report:
```
## Done

Issue #$ISSUE_NUM completed and merged to main.

Review passes:
- Pass 1 (Sonnet): ✓
- Pass 2 (Opus): ✓
- Pass 3 (Codex): ✓

Commit: $(git rev-parse --short HEAD)
```

---

## Parent Issue Flow (when sub-issues exist)

When `/start` is called on a parent issue that has sub-issues:

1. **List all sub-issues** and show the suggested order
2. **Move parent to In Progress**
3. **For each sub-issue** (in priority order):
   - Ask user: "Ready to start sub-issue #N: Title?"
   - Run the full flow (Steps 1-7) for that sub-issue
   - Report completion
   - Ask: "Continue to next sub-issue #M?"
4. **After all sub-issues complete**, parent auto-closes

**Priority order for sub-issues:**
1. `area:db` (database first)
2. `area:infra` (infrastructure)
3. `area:backend` (backend services)
4. `area:frontend` (frontend last)
5. Within same area: `priority:high` → `priority:medium` → `priority:low`
