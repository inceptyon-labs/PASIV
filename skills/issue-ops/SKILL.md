---
name: issue-ops
description: GitHub issue operations helper. Use for creating issues, updating issue body, closing issues. Internal skill - typically called by /start or /issue.
model: haiku
context: fork
allowed-tools:
  - Bash
user-invocable: false
---

# Issue Operations

Perform issue operation: $ARGUMENTS

## Label Definitions

PASIV labels with their colors and descriptions. Create missing labels before use.

| Label | Color | Description |
|-------|-------|-------------|
| `pasiv` | `1a1a2e` | Created by PASIV automation |
| `enhancement` | `84CC16` | New feature or improvement |
| `bug` | `EF4444` | Something isn't working |
| `documentation` | `06B6D4` | Documentation changes |
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

## Issue Type Hierarchy

Use the correct issue type based on scope:

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| **Epic** | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| **Feature** | Tactical | Single capability, spans days/week | "OAuth Login" |
| **Task** | Execution | Single work item, hours | "Create OAuth callback endpoint" |

## Available Operations

### create
Create a new GitHub issue.

Arguments: title, body, labels (comma-separated), type (Epic/Feature/Task), parent (optional issue number)

**Step 1: Ensure labels exist**

For each label in the comma-separated list, create it if missing:

```bash
# Get existing labels
EXISTING=$(gh label list --json name -q '.[].name')

# For each required label, check and create if missing
# Example for priority:high:
if ! echo "$EXISTING" | grep -q "^priority:high$"; then
  gh label create "priority:high" --color "DC2626" --description "Critical priority" --force
fi
```

Use the Label Definitions table above for colors and descriptions.

**Step 2: Create the issue**

```bash
# Without parent:
gh issue create \
  --title "$TITLE" \
  --body "$BODY" \
  --label "$LABELS" \
  --type "$TYPE"

# With parent (for sub-issues):
gh issue create \
  --title "$TITLE" \
  --body "$BODY" \
  --label "$LABELS" \
  --type "$TYPE" \
  --parent $PARENT_NUMBER
```

Return the issue URL.

### get
Get issue details.

Arguments: issue number

```bash
ISSUE_TITLE=$(gh issue view $NUM --json title -q '.title')
ISSUE_URL=$(gh issue view $NUM --json url -q '.url')
ISSUE_STATE=$(gh issue view $NUM --json state -q '.state')
ISSUE_BODY=$(gh issue view $NUM --json body -q '.body')
```

Return: number, title, url, state, body

### check-off-criteria
Update issue body to check off acceptance criteria.

Arguments: issue number

```bash
# Get current body
BODY=$(gh issue view $NUM --json body -q '.body')

# Replace [ ] with [x] in Acceptance Criteria section
UPDATED_BODY=$(echo "$BODY" | sed 's/- \[ \]/- [x]/g')

# Update the issue
gh issue edit $NUM --body "$UPDATED_BODY"
```

### close
Close an issue with a comment.

Arguments: issue number, comment

```bash
gh issue close $NUM --comment "$COMMENT"
```

### get-sub-issues
Get sub-issues of a parent issue (requires GraphQL).

Arguments: owner, repo, issue number

```bash
gh api graphql -f query="
query {
  repository(owner: \"$OWNER\", name: \"$REPO\") {
    issue(number: $NUM) {
      subIssues(first: 50) {
        nodes { number title state }
      }
    }
  }
}" --jq '.data.repository.issue.subIssues.nodes'
```

### get-parent
Get parent issue number (requires GraphQL).

Arguments: owner, repo, issue number

```bash
gh api graphql -f query="
query {
  repository(owner: \"$OWNER\", name: \"$REPO\") {
    issue(number: $NUM) {
      parent { number }
    }
  }
}" --jq '.data.repository.issue.parent.number // empty'
```

## Response Format

Return a brief confirmation with relevant data:
```
✓ [operation]: [details]
```

Example:
```
✓ create: #42 - Add user authentication
✓ close: #42 - Completed in abc1234
✓ check-off: #42 - All criteria marked complete
```
