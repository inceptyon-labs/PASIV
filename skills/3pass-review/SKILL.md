---
name: 3pass-review
description: Run 3-model code review pipeline (Sonnet, Opus, Codex). Use when user says "3pass review", "three pass review", "full review", "review pipeline", or wants multi-model feedback on a branch or pull request.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Code Review (3-Model Pipeline)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

## Get the Diff

```bash
# If branch name provided
git diff main..branch-name

# Otherwise current branch vs main
git diff main
```

---

## Pass 1: Fast Review (Sonnet)

Use model `sonnet` for quick scan:

Focus on:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling on critical paths
- Dead code / unused variables
- Test coverage gaps

Output as:
```
### Pass 1: Fast Review (Sonnet)
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

## Pass 2: Deep Review (Opus)

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
### Pass 2: Deep Review (Opus)
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

## Pass 3: Independent Review (Codex)

**IMPORTANT: Use the custom prompt, NOT `codex review --base main`.**

```bash
DIFF=$(git diff main)

codex exec -s read-only -o /tmp/codex-review.txt "Independent code review - catch what others missed.

Here is the diff:
$DIFF

Focus on:
1. Things other reviewers typically miss
2. Subtle bugs or logic errors
3. Security edge cases
4. Test coverage gaps

For each finding, specify:
- Severity: ERROR / WARNING / SUGGESTION
- Location: file:line
- Issue and recommended fix

Be thorough but don't repeat obvious issues."

cat /tmp/codex-review.txt
```

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
## Review Complete

Pass 1 (Sonnet): ✓ [N errors fixed]
Pass 2 (Opus):   ✓ [N errors fixed]
Pass 3 (Codex):  ✓ [N errors fixed]

### Warnings (non-blocking)
- file:line - description

### Suggestions
- description

Ready to merge.
```
