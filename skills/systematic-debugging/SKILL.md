---
name: systematic-debugging
description: Systematic debugging methodology with root cause analysis. Use when tests fail or bugs occur. Prevents guess-and-check debugging.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
---

# Systematic Debugging

**The Rule**: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

Symptom-focused fixes mask problems and create technical debt.

---

## Phase 1: Root Cause Investigation

### Read the Error

```bash
# Get full error output
npm test 2>&1 | head -100
```

Extract:
- [ ] Exact error message
- [ ] Stack trace (file:line numbers)
- [ ] Expected vs actual values
- [ ] Which test/function failed

### Reproduce Consistently

Can you make it fail every time?

```bash
# Run specific failing test
npm test -- --grep "test name"
```

If intermittent:
- Note conditions when it fails
- Note conditions when it passes
- Look for race conditions, timing issues, external dependencies

### Check Recent Changes

```bash
# What changed recently?
git log --oneline -10
git diff HEAD~3
```

Ask: What changed that could cause this?

---

## Phase 2: Pattern Analysis

### Find Similar Working Code

```bash
# Search for similar patterns that work
grep -r "similar_function" --include="*.ts" src/
```

### Compare Methodically

Document EVERY difference between working and broken:

| Aspect | Working Code | Broken Code |
|--------|--------------|-------------|
| Imports | | |
| Function signature | | |
| Parameter types | | |
| Return handling | | |
| Error handling | | |
| Async/await | | |

Even "insignificant" differences may be the cause.

---

## Phase 3: Hypothesis Testing

### Form Specific Hypothesis

**Bad**: "Something is wrong with the auth"
**Good**: "The JWT token is not refreshed because the refresh endpoint returns 401 when the token is expired"

The hypothesis must be:
- Specific (names exact component/function)
- Testable (can verify true/false)
- Explains the symptoms

### Test with Minimal Change

ONE change at a time:

1. Make the smallest possible change to test hypothesis
2. Run tests
3. Observe result

```bash
npm test -- --grep "failing test"
```

| Result | Action |
|--------|--------|
| Fixed | Hypothesis confirmed, proceed to Phase 4 |
| Still fails | Revert change, form new hypothesis |
| Different error | Revert, investigate new error |

### Three Strikes Rule

**If 3 independent fix attempts have failed: STOP**

The bug may be a symptom of deeper design issues. Ask:
- Is the architecture fundamentally flawed?
- Am I fixing the wrong layer?
- Should I ask for help or reassess approach?

---

## Phase 4: Implementation

### Write Failing Test First

```bash
# Add test that reproduces the bug
npm test -- --grep "bug description"
```

Test must fail, confirming it catches the bug.

### Apply Single Root-Cause Fix

Fix the ROOT CAUSE, not symptoms.

| Approach | Example |
|----------|---------|
| **Root cause fix** | Fix the null check in the function that should validate input |
| **Symptom fix** | Add try/catch around every call site |

### Verify

```bash
npm test
```

- [ ] Bug test now passes
- [ ] No other tests broken
- [ ] No new warnings

### Commit

**Use Skill tool**: `git-ops` with args: `commit "fix: [root cause description] (#$ISSUE_NUM)"`

---

## Red Flags - Restart Phase 1

| Red Flag | What to Do |
|----------|------------|
| Proposing fix before understanding cause | Stop, go back to Phase 1 |
| "Let me just try one more thing" | Stop after 3 attempts |
| Each fix reveals new problems | Deeper issue, reassess architecture |
| Assuming cause without verification | Stop, verify the assumption |
| Fix works but can't explain why | Investigate until you understand |

---

## Debug Log Template

When debugging, maintain this log:

```markdown
## Bug: [brief description]

### Error Output
[paste actual error message and stack trace]

### Hypothesis 1: [specific theory]
- Evidence for: [what supports this]
- Evidence against: [what contradicts]
- Test: [what change I made]
- Result: [what happened]

### Hypothesis 2: [specific theory]
- Evidence for:
- Evidence against:
- Test:
- Result:

### Root Cause
[final determination with evidence]

### Fix
[what was changed and why it fixes the root cause]
```

---

## Common Debugging Scenarios

### Test Passes Locally, Fails in CI

Check:
- Environment variables
- Node/Python/Go version differences
- File system case sensitivity (Mac vs Linux)
- Timezone differences
- Missing test fixtures

### Intermittent Failures

Check:
- Race conditions
- Shared mutable state
- External service dependencies
- Time-based logic
- Random number usage without seed

### "It Was Working Yesterday"

Check:
- Recent commits: `git log --oneline -20`
- Dependency updates: `git diff HEAD~5 package-lock.json`
- Environment changes
- External API changes

---

## Effectiveness

| Approach | Avg Time | Success Rate |
|----------|----------|--------------|
| Systematic debugging | 15-30 min | 95% first-time |
| Random fix attempts | 2-3 hours | 40% first-time |

Invest in understanding. It pays off.
