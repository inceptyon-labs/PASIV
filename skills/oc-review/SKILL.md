---
name: oc-review
description: Run OC (Opus → Codex) cascading review. Use when user says "oc review" or wants quality-focused 2-pass review for complex changes.
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - mcp__my-codex-mcp__codex
---

# OC Review (Opus → Codex)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

**Flow: Opus → FIX → Codex → FIX → Done**

This is a **cascading** review - Codex reviews cumulative changes including Opus's fixes.

---

## Pass 1: Opus

Get the current diff:

```bash
git diff main
```

Use model `opus` for thorough analysis:

Think like a senior engineer:
- Architecture and design patterns
- Edge cases and error scenarios
- Performance implications
- Over/under-engineering
- API design quality
- Security in depth
- Maintainability long-term

Output as:
```
### Pass 1: Opus
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### STOP - Fix Pass 1 Errors Now

**IMPORTANT: You MUST fix all ERRORs before proceeding to Pass 2.**

If any ERRORs found:
1. STOP reviewing
2. Fix each error one by one
3. Commit: `git add -A && git commit -m "fix: address Opus review findings"`
4. Only after ALL errors are fixed, proceed to Pass 2

**DO NOT skip to Pass 2 with unfixed errors.**

---

## Pass 2: Codex

Get a fresh diff (now includes Pass 1 fixes):

```bash
git diff main
```

### Check Diff Size

```bash
git diff main --stat | tail -1  # Shows total lines changed
```

**If diff is large (> 500 lines changed):** Split by file to avoid timeout.

```bash
# Get list of changed files
git diff main --name-only
```

For each file (or logical group of related files):
1. Get file-specific diff: `git diff main -- path/to/file.ts`
2. Call Codex with that chunk
3. Collect findings
4. Move to next file

**If diff is small (≤ 500 lines):** Review entire diff at once.

### Call Codex

Then call the `mcp__my-codex-mcp__codex` tool with:

| Parameter | Value |
|-----------|-------|
| `prompt` | "Independent code review - catch what Opus missed. Focus on: 1) Subtle bugs or logic errors, 2) Security edge cases, 3) Test coverage gaps, 4) Fresh perspective on architecture. For each finding: Severity (ERROR/WARNING/SUGGESTION), Location (file:line), Issue and recommended fix." |
| `code` | The diff output |
| `context` | "Pass 2 of OC review. Looking for issues Opus may have missed." |

### STOP - Fix Pass 2 Errors Now

**IMPORTANT: You MUST fix all ERRORs before completing the review.**

If any ERRORs found:
1. STOP
2. Fix each error one by one
3. Commit: `git add -A && git commit -m "fix: address Codex review findings"`

---

## Done

Report final summary:

```
## OC Review Complete

Pass 1 (Opus):  ✓ [N errors fixed]
Pass 2 (Codex): ✓ [N errors fixed]

### Warnings (non-blocking)
- file:line - description

### Suggestions
- description

Ready to merge.
```
