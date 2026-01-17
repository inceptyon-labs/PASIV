---
name: 3pass-review
description: Run 3-model code review pipeline (Sonnet, Opus, Codex). Use when user says "3pass review", "three pass review", "full review", "review pipeline", or wants multi-model feedback on a branch or pull request.
allowed-tools:
  - Bash
  - Read
---

# Code Review (3-Model Pipeline)

Review: $ARGUMENTS (branch name, or empty for current branch vs main)

## Get the Diff

```bash
# If branch name provided
git diff main..branch-name

# Otherwise current branch vs main
git diff main
```

Save the diff for all passes.

---

## Pass 1: Fast Review (Sonnet)

Use model `claude-sonnet-4-20250514` for quick scan:

Focus on obvious issues only:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling on critical paths
- Unused imports/dead code
- Style violations

Be quick - only flag issues you're confident about.

Output as:
```
### Pass 1: Fast Review (Sonnet)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

---

## Pass 2: Deep Review (Opus)

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
### Pass 2: Deep Review (Opus)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

---

## Pass 3: Independent Review (Codex)

Get the list of changed files and run Codex CLI:

```bash
FILES=$(git diff --name-only main)

codex --quiet "Independent code review - catch what others missed.

Files changed:
$FILES

Focus on:
1. Things other reviewers typically miss
2. Subtle bugs or logic errors
3. Security edge cases
4. Test coverage gaps
5. Documentation clarity
6. Alternative approaches worth considering
7. Technical debt being introduced

For each finding, specify:
- Severity: ERROR / WARNING / SUGGESTION
- Location: file:line
- Issue and recommended fix

Be thorough but don't repeat obvious issues."
```

---

## Aggregate Results

Combine all findings:

```
## Review Results

### Errors (must fix before merge)
- [Pass X] file:line - description → fix

### Warnings (should fix)
- [Pass X] file:line - description

### Suggestions
- description

## Summary
[Overall assessment - is this ready to merge?]
```

If any **Errors** from Pass 2 (Opus) or Pass 3 (Codex), restart from Pass 1 after fixing.

If only Pass 1 errors, fix and re-run Pass 1 only.

Offer to auto-fix errors found.
