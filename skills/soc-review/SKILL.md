---
name: soc-review
description: Run SOC (Sonnet → Opus → Codex) cascading review pipeline. Use when user says "soc review", "full review", "3pass review", or wants comprehensive multi-model feedback.
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - mcp__my-codex-mcp__codex
---

# SOC Review (Sonnet → Opus → Codex)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

All passes are **cascading** - each pass reviews cumulative changes including previous fixes.

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

## Pass 2: Opus

Get a fresh diff (now includes Pass 1 fixes):

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
### Pass 2: Opus
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### STOP - Fix Pass 2 Errors Now

**IMPORTANT: You MUST fix all ERRORs before proceeding to Pass 3.**

If any ERRORs found:
1. STOP reviewing
2. Fix each error one by one
3. Commit: `git add -A && git commit -m "fix: address Opus review findings"`
4. Only after ALL errors are fixed, proceed to Pass 3

**DO NOT skip to Pass 3 with unfixed errors.**

---

## Pass 3: Codex

Get a fresh diff (now includes Pass 1 + Pass 2 fixes):

```bash
git diff main
```

Then call the `mcp__my-codex-mcp__codex` tool with:

| Parameter | Value |
|-----------|-------|
| `prompt` | "Independent code review - catch what others missed. Focus on: 1) Things other reviewers typically miss, 2) Subtle bugs or logic errors, 3) Security edge cases, 4) Test coverage gaps. For each finding: Severity (ERROR/WARNING/SUGGESTION), Location (file:line), Issue and recommended fix. Be thorough but don't repeat obvious issues." |
| `code` | The diff output |
| `context` | "Pass 3 of SOC review. Looking for issues Sonnet and Opus may have missed." |

### STOP - Fix Pass 3 Errors Now

**IMPORTANT: You MUST fix all ERRORs before completing the review.**

If any ERRORs found:
1. STOP
2. Fix each error one by one
3. Commit: `git add -A && git commit -m "fix: address Codex review findings"`

---

## Done

Report final summary:

```
## SOC Review Complete

Pass 1 (Sonnet): ✓ [N errors fixed]
Pass 2 (Opus):   ✓ [N errors fixed]
Pass 3 (Codex):  ✓ [N errors fixed]

### Warnings (non-blocking)
- file:line - description

### Suggestions
- description

Ready to merge.
```
