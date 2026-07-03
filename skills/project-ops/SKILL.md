---
name: project-ops
description: GitHub Project operations helper. Project setup, add issues, update status. Internal — called by /kick or /issue.
model: haiku
context: fork
allowed-tools:
  - Bash
user-invocable: false
---

# Project Operations

Perform project operation: $ARGUMENTS

**On permission errors:** if any `gh project` command fails with a scope/permission error, report that the token is missing the `project` scope — fix is `gh auth refresh -s project` — and stop.

## Available Operations

### setup
Find or create a project for the repo.

```bash
REPO_NAME=$(gh repo view --json name -q '.name')
OWNER=$(gh repo view --json owner -q '.owner.login')

# Get project number AND node ID
PROJECT_DATA=$(gh project list --owner "$OWNER" --format json \
  | jq -r --arg name "$REPO_NAME" '.projects[]? | select(.title == $name)')
PROJECT_NUM=$(echo "$PROJECT_DATA" | jq -r '.number')
PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.id')

# Create if doesn't exist
if [ -z "$PROJECT_NUM" ]; then
  PROJECT_DATA=$(gh project create --owner "$OWNER" --title "$REPO_NAME" --format json)
  PROJECT_NUM=$(echo "$PROJECT_DATA" | jq -r '.number')
  PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.id')
fi
```

Return: PROJECT_NUM, PROJECT_ID, OWNER, REPO_NAME

### add-issue
Add an issue to the project.

Arguments: project_num, owner, issue_url

```bash
gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL"
```

### move-to-in-progress / move-to-done
Move an issue to the "In Progress" or "Done" status. Same recipe, `STATUS_NAME` = `"In Progress"` or `"Done"`.

Arguments: project_id, project_num, owner, issue_url

```bash
# Get item ID
ITEM_ID=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r --arg url "$ISSUE_URL" '.items[] | select(.content.url == $url) | .id')
# Empty ITEM_ID → issue not on the board: run add-issue, then retry this lookup once.

# Get Status field + target option
STATUS_FIELD=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name == "Status")')
FIELD_ID=$(echo "$STATUS_FIELD" | jq -r '.id')
OPTION_ID=$(echo "$STATUS_FIELD" | jq -r --arg s "$STATUS_NAME" '.options[] | select(.name == $s) | .id')
# Empty OPTION_ID → the board has non-default status columns: report the available option names and skip the move.

# Update status
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$FIELD_ID" --single-select-option-id "$OPTION_ID"
```

## Response Format

Return a brief confirmation with relevant data:
```
✓ [operation]: [details]
```

Example:
```
✓ setup: Project "my-repo" (#3, PVT_kwDO...)
✓ add-issue: #42 added to project
✓ move-to-in-progress: #42 → In Progress
✓ move-to-done: #42 → Done
```
