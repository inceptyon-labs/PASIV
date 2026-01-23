---
name: o-review
description: Run O (Opus) single-pass review. Use when user says "o review", "opus review", or wants thorough single-pass review for simple features.
model: opus
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# O Review (Opus)

Thorough single-pass review for: $ARGUMENTS (branch name, or empty for current branch vs main)

**Best for:** Simple features, clear scope, `size:S` issues.

---

## Get the Diff

```bash
# If branch name provided
git diff main..$ARGUMENTS

# Otherwise current branch vs main
git diff main
```

## Review Focus

Think like a senior engineer:

1. **Architecture and design patterns**
   - Appropriate abstractions
   - Separation of concerns
   - SOLID principles

2. **Edge cases and error scenarios**
   - Boundary conditions
   - Failure modes
   - Race conditions

3. **Performance implications**
   - N+1 queries
   - Unnecessary allocations
   - Blocking operations

4. **Over/under-engineering**
   - Unnecessary complexity
   - Missing necessary abstractions

5. **API design quality**
   - Consistent interfaces
   - Clear contracts
   - Backward compatibility

6. **Security in depth**
   - Input validation
   - Authorization checks
   - Data exposure

7. **Maintainability long-term**
   - Readability
   - Documentation needs
   - Test coverage quality

## Output Format

```
### O Review (Opus)

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
2. Commit: `git add -A && git commit -m "fix: address O review findings"`

## When to Use

- Simple features with clear scope
- `size:S` issues
- When you want thorough review but single-pass is sufficient

For moderate changes, use `/sc-review`. For complex/security-sensitive changes, use `/oc-review` or `/soc-review`.
