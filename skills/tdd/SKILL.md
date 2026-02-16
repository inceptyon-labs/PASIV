---
name: tdd
description: Test-Driven Development cycle. Split-model — Opus writes tests (RED), Sonnet writes code (GREEN/REFACTOR). Called by /kick for GREEN and REFACTOR phases.
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
---

# Test-Driven Development

No production code without a failing test first.

## Split-Model Design

| Phase | Model | Why |
|-------|-------|-----|
| RED (write test) | Opus (caller) | Tests are the spec — edge cases, API design, boundary conditions |
| GREEN (write code) | Sonnet (this skill) | Constrained by test, "simplest thing that works" |
| REFACTOR | Sonnet (this skill) | Tests guard against regressions |

Opus writes the test in `/kick` Step 3, then invokes this skill for GREEN and REFACTOR.

---

## Operations

### green

**PREREQUISITE**: A failing test exists. Opus (the caller) has already written and verified it fails for the right reason.

#### Step 1: Read the Failing Test

Read the test file to understand what behavior is expected. The test IS the spec.

#### Step 2: Write MINIMAL Implementation

Write the SIMPLEST code that makes the test pass:
- No extra features
- No "while I'm here" improvements
- No defensive code "just in case"
- ONLY what the failing test requires

```
# Use Edit or Write to create/modify implementation file
```

#### Step 3: Run Tests

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

#### Step 4: Verify GREEN

Check:
- [ ] New test passes → return success
- [ ] New test still fails → fix implementation, re-run, stay in GREEN
- [ ] Other tests broke → fix regression, re-run, stay in GREEN
- [ ] No skipped tests

All tests must pass before returning.

---

### refactor

**PREREQUISITE**: All tests are passing (GREEN verified).

#### Step 1: Assess

Look at the code written during GREEN. Identify:
- Duplication to remove
- Names to improve
- Helpers to extract (only if truly needed)

If nothing needs cleanup, return immediately.

#### Step 2: Refactor

Make ONE change at a time.

**After EACH change**:
```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Tests must stay green throughout. If tests fail, revert the refactor.

#### Step 3: Return

Return summary of what was cleaned up (or "No refactoring needed").

---

## Violation Detection

You are violating TDD if:

1. You wrote implementation before a failing test exists
2. You added features beyond what the test requires
3. Tests are failing after refactoring (revert immediately)

If you detect a violation: STOP. Delete the implementation code. Report back to the caller.

---

## Turn-by-Turn Checklist (full cycle, across models)

```
┌─────────────────────────────────────────────────────────┐
│ TURN 1 (Opus): Write test (Edit/Write to test file)    │
│         → "Test written, running it now..."             │
├─────────────────────────────────────────────────────────┤
│ TURN 2 (Opus): Run test (Bash)                         │
│         → FAIL (show the failure message)               │
│         → "Test fails because X doesn't exist. RED ✓"   │
├─────────────────────────────────────────────────────────┤
│ TURN 3 (Sonnet via tdd green): Write implementation    │
│         → Run tests → PASS                              │
│         → "All tests pass. GREEN ✓"                     │
├─────────────────────────────────────────────────────────┤
│ TURN 4 (Sonnet via tdd refactor): Clean up if needed   │
│         → Run tests → still PASS                        │
│         → "REFACTOR ✓"                                  │
├─────────────────────────────────────────────────────────┤
│ TURN 5 (Opus): Commit (Skill: git-ops)                 │
│         → Committed                                     │
└─────────────────────────────────────────────────────────┘
```

---

## TDD for Bug Fixes

Same split applies:
1. **Opus**: Write a test that fails, demonstrating the bug
2. **Opus**: Verify RED — test fails for the bug reason
3. **Sonnet (tdd green)**: Minimal code to make test pass
4. **Opus**: Verify GREEN, commit: `fix: [bug description] (#$ISSUE_NUM)`

The failing test PROVES the bug exists. The passing test PROVES it's fixed.
