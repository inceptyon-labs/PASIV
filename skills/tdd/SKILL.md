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

## Operation

**PREREQUISITE**: A failing test exists. Opus (the caller) has already written and verified it fails for the right reason.

This skill runs GREEN then REFACTOR in a single invocation and returns control to the caller.

### GREEN: Write MINIMAL Implementation

1. Read the failing test file to understand what behavior is expected. The test IS the spec.

2. Write the SIMPLEST code that makes the test pass:
   - No extra features
   - No "while I'm here" improvements
   - No defensive code "just in case"
   - ONLY what the failing test requires

3. Run tests:
   ```bash
   npm test || pytest || go test ./... || cargo test || bun test
   ```

4. Verify:
   - New test passes → continue to REFACTOR
   - New test still fails → fix implementation, re-run, stay in GREEN
   - Other tests broke → fix regression, re-run, stay in GREEN

All tests must pass before moving to REFACTOR.

### REFACTOR: Clean Up

1. Assess the code written during GREEN:
   - Duplication to remove
   - Names to improve
   - Helpers to extract (only if truly needed)

2. If nothing needs cleanup, skip to return.

3. Make ONE change at a time. After EACH change:
   ```bash
   npm test || pytest || go test ./... || cargo test || bun test
   ```
   Tests must stay green throughout. If tests fail, revert the refactor.

### Return

Return a brief summary:
```
GREEN ✓ — [what was implemented]
REFACTOR ✓ — [what was cleaned up, or "No refactoring needed"]
```

The caller (kick) will handle the COMMIT step and continue the workflow.

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
┌──────────────────────────────────────────────────────────┐
│ TURN 1 (Opus/kick): Write test (Edit/Write)             │
│         → "Test written, running it now..."              │
├──────────────────────────────────────────────────────────┤
│ TURN 2 (Opus/kick): Run test (Bash)                     │
│         → FAIL → "Test fails because X. RED ✓"           │
├──────────────────────────────────────────────────────────┤
│ TURN 3 (Sonnet/tdd): GREEN + REFACTOR in one call       │
│         → Write implementation → run tests → PASS        │
│         → Clean up if needed → run tests → still PASS    │
│         → Return "GREEN ✓ / REFACTOR ✓"                  │
├──────────────────────────────────────────────────────────┤
│ TURN 4 (Opus/kick): Commit (Skill: git-ops)             │
│         → MUST continue to next cycle or next step       │
└──────────────────────────────────────────────────────────┘
```

---

## TDD for Bug Fixes

Same split applies:
1. **Opus**: Write a test that fails, demonstrating the bug
2. **Opus**: Verify RED — test fails for the bug reason
3. **Sonnet (tdd)**: GREEN + REFACTOR in one call — minimal fix
4. **Opus**: Commit: `fix: [bug description] (#$ISSUE_NUM)`, then continue workflow

The failing test PROVES the bug exists. The passing test PROVES it's fixed.
