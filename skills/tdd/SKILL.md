---
name: tdd
description: Test-Driven Development cycle. Enforces RED-GREEN-REFACTOR methodology. Used internally by /start.
model: opus
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

## CRITICAL ENFORCEMENT RULES

**NEVER write test code and implementation code in the same tool call.**

**NEVER write implementation code until you have shown failing test output.**

These are hard requirements, not guidelines.

---

## RED Phase

### Step 1: Write ONE Test

Write ONE minimal test for the next piece of functionality.

```
# Use Edit or Write to create/modify test file
# Test must be clear and test real behavior
```

**STOP HERE.** Do not write any implementation code yet.

### Step 2: Run the Test

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

**STOP HERE.** Show the failure output.

### Step 3: Verify RED

The test MUST fail. Check:
- [ ] Test fails because feature doesn't exist (correct) → proceed to GREEN
- [ ] Test fails due to syntax/import error → fix the test, re-run, stay in RED
- [ ] Test passes immediately → test is wrong, rewrite it, stay in RED

**Expected**: Test fails for the RIGHT reason - missing functionality.

**HARD GATE**: You MUST have shown failing test output before proceeding. If you have not run the test and seen it fail, you are NOT allowed to write implementation code.

---

## GREEN Phase

**PREREQUISITE**: You must have shown failing test output from RED phase.

If you cannot point to the failing test output in this conversation, STOP and go back to RED.

### Step 1: Write MINIMAL Implementation

Write the SIMPLEST code that makes the test pass:
- No extra features
- No "while I'm here" improvements
- No defensive code "just in case"
- ONLY what the failing test requires

```
# Use Edit or Write to create/modify implementation file
# This is the ONLY place implementation code is written
```

### Step 2: Run the Test

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

**STOP HERE.** Show the output.

### Step 3: Verify GREEN

Check:
- [ ] New test passes → proceed to REFACTOR
- [ ] New test still fails → fix implementation, re-run, stay in GREEN
- [ ] Other tests broke → fix regression, re-run, stay in GREEN
- [ ] No skipped tests

**HARD GATE**: All tests must pass before proceeding to REFACTOR or next cycle.

---

## REFACTOR Phase

**PREREQUISITE**: All tests must be passing (GREEN verified).

Only after GREEN is verified:
1. Remove duplication
2. Improve naming
3. Extract helpers only if truly needed

**After EACH refactoring change**:
```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Tests must stay green throughout refactoring. If tests fail, revert the refactor.

---

## COMMIT

After each complete RED-GREEN-REFACTOR cycle:

**Use Skill tool**: `git-ops` with args: `commit "feat: [what was added] (#$ISSUE_NUM)"`

Small cycles = frequent commits = easy rollback.

---

## TDD Violation Detection

**You are violating TDD if any of these are true:**

1. **You wrote test + implementation in the same Edit/Write call**
   - This is ALWAYS a violation, no exceptions

2. **You cannot point to failing test output in this conversation**
   - If there's no RED output shown, you skipped RED

3. **You wrote implementation before showing test failure**
   - Even if you "planned to run the test after"

**If you detect a violation**: STOP. Delete the implementation code. Go back to RED.

---

## Red Flags - STOP and Restart

If any of these occur, delete the production code and restart TDD properly:

| Red Flag | What Happened | Fix |
|----------|---------------|-----|
| Wrote test + impl together | Batched tool calls | Delete impl, show RED first |
| No failure output shown | Skipped verification | Run test, show failure |
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

---

## Explicit Turn-by-Turn Checklist

Each TDD cycle should look like this sequence of separate actions:

```
┌─────────────────────────────────────────────────────────┐
│ TURN 1: Write test (Edit/Write to test file)           │
│         → Output: "Test written, running it now..."    │
├─────────────────────────────────────────────────────────┤
│ TURN 2: Run test (Bash)                                │
│         → Output: FAIL (show the failure message)      │
│         → "Test fails because X doesn't exist. RED ✓"  │
├─────────────────────────────────────────────────────────┤
│ TURN 3: Write implementation (Edit/Write to src file)  │
│         → Output: "Implementation written, verifying.."│
├─────────────────────────────────────────────────────────┤
│ TURN 4: Run test (Bash)                                │
│         → Output: PASS                                 │
│         → "All tests pass. GREEN ✓"                    │
├─────────────────────────────────────────────────────────┤
│ TURN 5: Commit (Skill: git-ops)                        │
│         → Output: Committed                            │
└─────────────────────────────────────────────────────────┘
```

**What is NOT allowed:**

```
┌─────────────────────────────────────────────────────────┐
│ ❌ WRONG: Write test + implementation in same turn     │
│ ❌ WRONG: Write implementation before showing FAIL     │
│ ❌ WRONG: Skip running the test after writing it       │
│ ❌ WRONG: "I know it will fail, so I'll just..."       │
└─────────────────────────────────────────────────────────┘
```

**Self-check before writing implementation:**
> "Can I point to failing test output in THIS conversation?"
> If NO → STOP, go run the test first
