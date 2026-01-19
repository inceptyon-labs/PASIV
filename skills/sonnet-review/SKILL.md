---
name: sonnet-review
description: Quick code review using Sonnet. Use when user says "sonnet review", "quick review", "light review", or wants fast feedback on simple changes.
model: sonnet
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Sonnet Quick Review

Fast review for: $ARGUMENTS (branch name, or empty for current branch vs main)

## Get the Diff

```bash
# If branch name provided
git diff main..$ARGUMENTS

# Otherwise current branch vs main
git diff main
```

## Review Focus

Quick scan for practical issues:

1. **Clear bugs and errors**
   - Null/undefined access
   - Off-by-one errors
   - Missing return statements
   - Incorrect conditionals

2. **Security basics**
   - SQL injection
   - XSS vulnerabilities
   - Auth/authz flaws
   - Hardcoded secrets

3. **Missing error handling**
   - Unhandled promises
   - Missing try/catch on critical paths
   - Silent failures

4. **Dead code**
   - Unused variables
   - Unreachable code
   - Commented-out code

5. **Test coverage gaps**
   - New code without tests
   - Edge cases not covered

## Output Format

```
### Quick Review (Sonnet)

**Errors (must fix):**
- [ERROR] file:line - description

**Warnings (should fix):**
- [WARNING] file:line - description

**Suggestions (optional):**
- [SUGGESTION] file:line - description
```

## If Errors Found

Offer to fix them:

"Found N errors. Would you like me to fix them?"

If yes:
1. Fix each error
2. Commit: `git add -A && git commit -m "fix: address Sonnet review findings"`

## When to Use

- Simple bug fixes
- Small config changes
- `size:S` issues
- Quick sanity check before deeper review

For complex changes, use `/3pass-review` or `/codex-review` instead.
