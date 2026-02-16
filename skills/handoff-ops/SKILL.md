---
name: handoff-ops
description: Handoff file management helper. Read latest handoff, archive old ones.
model: haiku
context: fork
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
user-invocable: false
---

# Handoff Operations

Perform handoff operation: $ARGUMENTS

## Available Operations

### get-latest

Find and return the most recent `docs/handoffs/handoff-*.md` file (by date in filename).

```bash
# Find most recent handoff file (not in archive/)
LATEST=$(ls -1t docs/handoffs/handoff-*.md 2>/dev/null | head -1)
```

If found: read and return its contents.
If not found: return "No active handoff found."

### archive

Move a handoff file to the archive directory.

Arguments: filename (e.g., `handoff-2026-02-16-auth-endpoint.md`)

```bash
mkdir -p docs/handoffs/archive
mv "docs/handoffs/$FILENAME" "docs/handoffs/archive/$FILENAME"
```

Return confirmation.

### list

List all active (non-archived) handoff files.

```bash
ls -1t docs/handoffs/handoff-*.md 2>/dev/null
```

Return the list, or "No active handoffs." if empty.

## Response Format

```
✓ [operation]: [details]
```
