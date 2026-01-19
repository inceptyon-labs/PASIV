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

## Available Operations

### create
Create a new GitHub issue.

Arguments: title, body, labels (comma-separated)

```bash
gh issue create \
  --title "$TITLE" \
  --body "$BODY" \
  --label "$LABELS"
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
