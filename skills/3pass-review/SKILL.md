---
name: 3pass-review
description: Run 4-model code review pipeline (Haiku, Sonnet, Opus, Codex). Use when user says "3pass review", "three pass review", "full review", "review pipeline", or wants multi-model feedback on a branch or pull request.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Code Review (4-Model Pipeline)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

**Flow: Haiku → fix → Sonnet → fix → Opus → fix → Codex → fix → Done**

Linear progression, no loops. Each pass adds a different perspective.

## Get the Diff

```bash
# If branch name provided
git diff main..branch-name

# Otherwise current branch vs main
git diff main
```

---

## Pass 1: Pre-filter (Haiku)

Use model `claude-haiku-4-20250514` for cheap/fast pre-filter:

Catch the obvious stuff:
- Syntax errors
- Missing imports / typos
- Obvious logic errors (null checks, off-by-one)
- Hardcoded secrets
- Dead code / unused variables

Output as:
```
### Pass 1: Pre-filter (Haiku)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### Fix Pass 1 Errors

**If any ERRORs found:**
1. Fix all errors
2. Commit: `git add -A && git commit -m "fix: address Haiku review findings"`

**Proceed to Pass 2.**

---

## Pass 2: Fast Review (Sonnet)

Use model `claude-sonnet-4-20250514` for quick scan:

Focus on:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling on critical paths
- Style violations
- Test coverage gaps

Output as:
```
### Pass 2: Fast Review (Sonnet)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### Fix Pass 2 Errors

**If any ERRORs found:**
1. Fix all errors
2. Commit: `git add -A && git commit -m "fix: address Sonnet review findings"`

**Proceed to Pass 3.**

---

## Pass 3: Deep Review (Opus)

Use model `claude-opus-4-20250514` for thorough analysis:

Think like a senior engineer:
- Architecture and design patterns
- Edge cases and error scenarios
- Performance implications
- Over/under-engineering
- API design quality
- Security in depth
- Maintainability long-term

Take your time - be thorough.

Output as:
```
### Pass 3: Deep Review (Opus)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

### Fix Pass 3 Errors

**If any ERRORs found:**
1. Fix all errors
2. Commit: `git add -A && git commit -m "fix: address Opus review findings"`

**Proceed to Pass 4.**

---

## Pass 4: Independent Review (Codex)

**IMPORTANT: Use the custom prompt, NOT `codex review --base main`.**

Get the diff and run Codex with custom focus:

```bash
DIFF=$(git diff main)

codex exec -s read-only "Independent code review - catch what others missed.

Here is the diff:
$DIFF

Focus on:
1. Things other reviewers typically miss
2. Subtle bugs or logic errors
3. Security edge cases
4. Test coverage gaps
5. Alternative approaches worth considering

For each finding, specify:
- Severity: ERROR / WARNING / SUGGESTION
- Location: file:line
- Issue and recommended fix

Be thorough but don't repeat obvious issues."
```

### Fix Pass 4 Errors

**If any ERRORs found:**
1. Fix all errors
2. Commit: `git add -A && git commit -m "fix: address Codex review findings"`

---

## Done

Report final summary:

```
## Review Complete

Pass 1 (Haiku):  ✓ [N errors fixed]
Pass 2 (Sonnet): ✓ [N errors fixed]
Pass 3 (Opus):   ✓ [N errors fixed]
Pass 4 (Codex):  ✓ [N errors fixed]

### Warnings (non-blocking)
- file:line - description

### Suggestions
- description

Ready to merge.
```
