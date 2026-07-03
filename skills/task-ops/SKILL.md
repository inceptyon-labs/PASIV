---
name: task-ops
description: Task backend router. Reads .pasiv.yml, routes to github / beans / local. Use instead of issue-ops for task CRUD.
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

- If file missing or `task_backend` not set: default to `local` (zero-dependency; github/beans are opt-in via `.pasiv.yml`)
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
| `get-context` | `IDENTIFIER` | Composite: everything /kick needs in one fork |

### `get-context` (composite — handled here, not by the backend)

Run these backend ops **inside this fork** and merge into one report: `get $IDENTIFIER`, `get-sub-issues $IDENTIFIER`, `get-parent $IDENTIFIER`, and — only if a parent came back — `get-sibling-context $PARENT`. Return one structured report:

```
IDENTIFIER / TITLE / BODY / LABELS / STATUS [/ URL for github]
PARENT: <id + title, or "none">
SUB-ISSUES: <id + title + status each, or "none">
SIBLING CONTEXT: <files/decisions/notes from completed siblings, or "none">
```

This replaces 3–4 sequential forks from /kick with one.

Note: GitHub backend requires `OWNER` and `REPO` for GraphQL operations (`get-sub-issues`, `get-parent`, `get-sibling-context`); it can derive them itself if omitted. Beans and local backends do not need these — they work with local files.

## Shared Contract (all backends)

- **Status vocabulary:** every backend returns `open | in-progress | closed`. Mapping: github `OPEN`→`open`, `CLOSED`→`closed`; beans `draft`→`open`, `in-progress`→`in-progress`, `completed`/`scrapped`→`closed`; local is native.
- **Completion summaries** use the heading `## Completed` in all backends — `get-sibling-context` filters on it.
- **Labels:** canonical definitions live in `docs/reference/labels.md`; `issue-ops` carries the runtime copy (colors) and creates missing labels on every `create`. Callers never pre-create labels.
- **`get-next`:** returns the highest-priority open Task (id + title), or a "No open tasks" message — never the string `null`.

## Response Format

Pass through the backend's response format unchanged.
