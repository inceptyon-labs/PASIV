---
name: sc-review
description: Run SC (Sonnet → Codex) cascading review. Use when user says "sc review" or wants budget-friendly 2-pass review for moderate changes.
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - mcp__my-codex-mcp__codex
---

# SC Review (Sonnet → Codex)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

**Flow: Sonnet → FIX → Codex → FIX → Done**

This is a **cascading** review - Codex reviews cumulative changes including Sonnet's fixes.

---

## Pass 1: Sonnet

Get the current diff:

```bash
git diff main
```

Use model `sonnet` for quick scan:

Focus on:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling on critical paths
- Dead code / unused variables
- Test coverage gaps

Output as:
```
### Pass 1: Sonnet
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### STOP - Fix Pass 1 Errors Now

**IMPORTANT: You MUST fix all ERRORs before proceeding to Pass 2.**

If any ERRORs found:
1. STOP reviewing
2. Fix each error one by one
3. Commit: `git add -A && git commit -m "fix: address Sonnet review findings"`
4. Only after ALL errors are fixed, proceed to Pass 2

**DO NOT skip to Pass 2 with unfixed errors.**

---

## Pass 2: Codex

Get a fresh diff (now includes Pass 1 fixes):

```bash
git diff main
```

Then call the `mcp__my-codex-mcp__codex` tool with:

| Parameter | Value |
|-----------|-------|
| `prompt` | "Independent code review - catch what Sonnet missed. Focus on: 1) Subtle bugs or logic errors, 2) Security edge cases, 3) Test coverage gaps, 4) Architecture issues. For each finding: Severity (ERROR/WARNING/SUGGESTION), Location (file:line), Issue and recommended fix." |
| `code` | The diff output |
| `context` | "Pass 2 of SC review. Looking for issues Sonnet may have missed." |

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
## SC Review Complete

Pass 1 (Sonnet): ✓ [N errors fixed]
Pass 2 (Codex):  ✓ [N errors fixed]

### Warnings (non-blocking)
- file:line - description

### Suggestions
- description

Ready to merge.
```
