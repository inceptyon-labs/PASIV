---
name: task-ops
description: Task backend router. Reads .pasiv.yml and routes to github (issue-ops), beans (beans-ops), or local (local-ops) backend. Use instead of issue-ops for all task CRUD.
model: haiku
context: fork
allowed-tools:
  - Bash
  - Read
  - Write
  - Skill
user-invocable: false
---

# Task Operations (Backend Router)

Perform task operation: $ARGUMENTS

## Step 1: Detect Backend

Read `.pasiv.yml` if it exists to determine the task backend:

```bash
[ -f .pasiv.yml ] && cat .pasiv.yml || echo "missing"
```

- If file missing or `task_backend` not set: default to `github`
- Extract `task_backend` value: `github`, `beans`, or `local`

## Step 2: Route to Backend

### If github

**Use Skill tool:** `issue-ops` with args: `$ARGUMENTS`

Pass all arguments through unchanged. The `issue-ops` skill handles GitHub Issues natively.

### If beans

**Use Skill tool:** `beans-ops` with args: `$ARGUMENTS`

### If local

**Use Skill tool:** `local-ops` with args: `$ARGUMENTS`

## Step 3: Return Result

Return the result from the backend skill unchanged.

## Available Operations

These operations are supported by all backends:

| Operation | Arguments | Description |
|-----------|-----------|-------------|
| `create` | `"Title" "Body" "labels" "type" [parent]` | Create a new task |
| `get` | `NUMBER_OR_ID` | Get task details |
| `close` | `NUMBER_OR_ID "Comment"` | Close a task |
| `get-sub-issues` | `IDENTIFIER [OWNER REPO]` | Get child tasks |
| `get-parent` | `IDENTIFIER [OWNER REPO]` | Get parent task |
| `check-off-criteria` | `IDENTIFIER` | Mark acceptance criteria done |
| `add-completion-summary` | `IDENTIFIER "$FILES" "$DECISIONS" "$NOTES"` | Add completion context |
| `get-sibling-context` | `IDENTIFIER [OWNER REPO]` | Get context from completed siblings |
| `get-next` | (none) | Get the highest priority actionable task |

Note: GitHub backend requires `OWNER` and `REPO` for GraphQL operations (`get-sub-issues`, `get-parent`, `get-sibling-context`). Beans and local backends do not need these — they work with local files.

## Response Format

Pass through the backend's response format unchanged.
