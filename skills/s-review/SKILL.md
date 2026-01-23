---
name: s-review
description: Run S (Sonnet) single-pass review. Use when user says "s review", "quick review", "sonnet review", or wants fast feedback on trivial changes.
model: sonnet
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# S Review (Sonnet)

Fast single-pass review for: $ARGUMENTS (branch name, or empty for current branch vs main)

**Best for:** Typos, config changes, trivial fixes, `size:XS` issues.

---

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
### S Review (Sonnet)

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
2. Commit: `git add -A && git commit -m "fix: address S review findings"`

## When to Use

- Trivial fixes and typos
- Small config changes
- `size:XS` issues
- Quick sanity check before deeper review

For moderate changes, use `/sc-review`. For complex changes, use `/oc-review` or `/soc-review`.
