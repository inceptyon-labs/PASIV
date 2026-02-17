---
name: tdd
description: Test-Driven Development implementation. Sonnet implements all failing tests written by Opus, committing after each. Called ONCE per implementation step by /kick.
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

| Phase | Model | Where |
|-------|-------|-------|
| RED (write tests) | Opus | `/kick` Step 3 — writes ALL failing tests for the step |
| GREEN + REFACTOR + COMMIT | Sonnet | This skill — implements each test, cleans up, commits |

Opus writes all tests upfront, then invokes this skill ONCE. This skill loops through each failing test: implement → verify → refactor → commit. Returns when all tests pass.

---

## Operation

**PREREQUISITE**: Opus has written one or more failing tests. All tests have been verified to fail for the right reason (missing feature, not syntax error).

### Step 1: Discover Failing Tests

Run the test suite to identify which tests are failing:

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Parse the output to get the list of failing test names/files.

### Step 2: For EACH Failing Test, Loop

#### GREEN: Write MINIMAL Implementation

1. Read the failing test to understand what behavior is expected. The test IS the spec.

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
   - Target test passes → continue to REFACTOR
   - Target test still fails → fix implementation, re-run
   - Other tests broke → fix regression, re-run

#### REFACTOR: Clean Up

1. Assess the code just written:
   - Duplication to remove
   - Names to improve
   - Helpers to extract (only if truly needed)

2. If nothing needs cleanup, skip to COMMIT.

3. Make ONE change at a time. After EACH change run tests — they must stay green.

#### COMMIT

**Use Skill tool:** `git-ops` with args: `commit "feat: [what was implemented] (#$ISSUE_NUM)"`

Then continue to the NEXT failing test.

### Step 3: Final Verification

After all failing tests have been implemented, run the full suite one more time:

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

All tests must pass.

### Step 4: Return

Return a summary of all cycles:

```
TDD Implementation Complete

Cycles:
1. [test name] — GREEN ✓ REFACTOR ✓ COMMIT ✓
2. [test name] — GREEN ✓ REFACTOR ✓ COMMIT ✓
3. [test name] — GREEN ✓ (no refactor needed) COMMIT ✓

All tests passing. [N] commits made.
```

---

## Violation Detection

You are violating TDD if:

1. You wrote implementation before a failing test exists
2. You added features beyond what the test requires
3. Tests are failing after refactoring (revert immediately)

If you detect a violation: STOP. Delete the implementation code. Report back to the caller.

---

## TDD for Bug Fixes

Same split applies:
1. **Opus**: Write a test that fails, demonstrating the bug
2. **Sonnet (this skill)**: GREEN + REFACTOR + COMMIT
3. Control returns to Opus to continue workflow

The failing test PROVES the bug exists. The passing test PROVES it's fixed.
