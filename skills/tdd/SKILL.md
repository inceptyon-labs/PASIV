---
name: tdd
description: Test-Driven Development cycle. Enforces RED-GREEN-REFACTOR methodology. Used internally by /start.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
---

# Test-Driven Development

**The Iron Law**: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Any code written before tests must be deleted and reimplemented through TDD.

---

## RED Phase

1. Write ONE minimal test for the next piece of functionality
2. Test must be clear and test real behavior (avoid mocks when possible)
3. Run the test

**Verify RED**:
```bash
# Detect and run test suite
npm test || pytest || go test ./... || cargo test || bun test
```

The test MUST fail. Check:
- [ ] Test fails because feature doesn't exist (correct)
- [ ] Test fails due to syntax/import error (fix the test)
- [ ] Test passes immediately (test doesn't test what you think - rewrite it)

**Expected**: Test fails for the RIGHT reason - missing functionality.

---

## GREEN Phase

1. Write the SIMPLEST code that makes the test pass
2. No extra features, no "while I'm here" improvements
3. No defensive code "just in case"

**Verify GREEN**:
```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Check:
- [ ] New test passes
- [ ] All existing tests still pass
- [ ] No skipped tests

---

## REFACTOR Phase

Only after GREEN:
1. Remove duplication
2. Improve naming
3. Extract helpers only if truly needed
4. Run tests after EACH change

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Tests must stay green throughout refactoring.

---

## COMMIT

After each complete RED-GREEN-REFACTOR cycle:

**Use Skill tool**: `git-ops` with args: `commit "feat: [what was added] (#$ISSUE_NUM)"`

Small cycles = frequent commits = easy rollback.

---

## Red Flags - STOP and Restart

If any of these occur, delete the production code and restart TDD properly:

| Red Flag | What Happened | Fix |
|----------|---------------|-----|
| Wrote code before test | Skipped RED phase | Delete code, write test first |
| Test passed immediately | Test doesn't verify new behavior | Rewrite test to actually test it |
| Can't explain why test should fail | Test is unclear | Rewrite test with clear assertion |
| Added features beyond test | Over-engineering in GREEN | Remove extras, stay minimal |
| "I'll add tests later" | TDD violation | Stop, write test now |
| Excessive mocking | Not testing real behavior | Use real implementations |

---

## When to Use TDD

**Always use for**:
- New features
- Bug fixes (write failing test that reproduces bug FIRST)
- Refactoring (ensure tests exist before changing)
- Any behavior change

**May skip** (with explicit user approval only):
- Throwaway prototypes
- Generated/scaffolded code
- Pure config changes with no logic

---

## Common Rationalizations (Don't Fall For These)

| Excuse | Reality |
|--------|---------|
| "I'll test after" | Tests that pass immediately prove nothing |
| "Already manually tested" | Manual testing is not systematic or repeatable |
| "Too simple to test" | Simple code still breaks |
| "Deleting code is wasteful" | Unverified code is technical debt |
| "TDD slows me down" | Debugging untested code is slower |

---

## TDD for Bug Fixes

1. **Reproduce**: Write a test that fails, demonstrating the bug
2. **Verify RED**: Test fails for the bug reason
3. **Fix**: Minimal code to make test pass
4. **Verify GREEN**: Bug test passes, no regressions
5. **Commit**: `fix: [bug description] (#$ISSUE_NUM)`

The failing test PROVES the bug exists. The passing test PROVES it's fixed.
