---
name: verification
description: Verification gate before completion claims. Ensures fresh evidence before merge or "done" claims. Used internally by /kick.
model: haiku
context: fork
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
---

# Verification Before Completion

**The Rule**: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

Before asserting work is complete, fixed, or passing - execute verification and examine actual output.

---

## The Five-Step Gate

Before ANY completion claim:

### 1. IDENTIFY

What command proves your assertion?

| Claim | Command |
|-------|---------|
| "Tests pass" | `npm test` / `pytest` / `go test ./...` |
| "Build succeeds" | `npm run build` / `go build ./...` |
| "No lint errors" | `npm run lint` / `golangci-lint run` |
| "Types check" | `npm run typecheck` / `tsc --noEmit` |

### 2. RUN

Execute it completely and freshly:
```bash
# Run the actual command - don't rely on memory
npm test
```

### 3. READ

Examine the FULL output:
- Exit code (0 = success)
- All test results (passed/failed/skipped)
- Any warnings or deprecations
- Error messages if failed

### 4. VERIFY

Do the results ACTUALLY support your claim?

| Output | Verdict |
|--------|---------|
| "47 passed, 0 failed" | ✓ Valid claim |
| "45 passed, 2 skipped" | ⚠ Investigate skipped |
| "All passed" with warnings | ⚠ Are warnings acceptable? |
| Exit code non-zero | ✗ Cannot claim success |

### 5. CLAIM

Only now state the result WITH evidence:

**Good**: "Tests pass: 47/47 passing, 0 skipped, exit 0"
**Bad**: "Tests should pass" / "Tests were passing earlier"

---

## What Counts as Verification

| Claim | Required Evidence |
|-------|-------------------|
| "Tests pass" | Fresh test run showing all pass |
| "Build works" | Fresh build with exit code 0 |
| "No lint errors" | Fresh lint run, clean output |
| "Feature works" | Test output OR documented manual steps |
| "Bug is fixed" | Test that reproduced bug now passes |

---

## What Does NOT Count

| Non-Evidence | Why |
|--------------|-----|
| Previous test runs | Need CURRENT evidence |
| "Should pass" | Need ACTUAL run |
| Partial checks | Full suite required |
| Memory of success | Run again |
| Linter passing | Doesn't mean tests pass |
| Agent success reports | Verify independently |
| "It worked on my machine" | Run in current environment |

---

## Red Flag Language - STOP

If you catch yourself saying any of these, STOP and run verification:

- "probably works"
- "should pass"
- "seems fine"
- "I think it's done"
- "tests were passing earlier"
- "it was working before"
- "just a small change, shouldn't break anything"

---

## Pre-Merge Checklist

Run ALL of these and verify output before merge:

### Step 1: Run Tests (REQUIRED)

**Use Skill tool:** `test-runner`

**If tests pass (✓):** Proceed to Step 2.

**If tests fail (✗):** Attempt simple fixes, escalate if complex.

#### Simple Fix Attempts (Haiku - max 2 attempts)

Try to fix **obvious** syntax/import errors:
- Missing imports
- Typos in function names
- Incorrect variable references
- Simple syntax errors (missing brackets, commas)

For each fix attempt:
1. Read error output
2. If error is simple and obvious, fix it
3. Commit fix: `fix: address simple test errors`
4. Re-run test-runner
5. If still failing after **2 simple fix attempts**, escalate to Opus

**DO NOT attempt to fix:**
- Logic errors (wrong behavior)
- Complex test failures
- Multiple failing tests with different root causes
- Anything requiring code understanding beyond syntax

#### Escalate to Opus (if simple fixes don't work)

After 2 failed simple fix attempts, **escalate**:

**Use Skill tool:** `systematic-debugging` with context of test failures

Let Opus:
1. Read full error output and test code
2. Form hypothesis about root cause
3. Make targeted fix
4. Commit: `fix: address test failures`
5. Re-run test-runner
6. Loop until passing

**CRITICAL RULES:**
- NEVER skip tests or mark them as skipped
- NEVER proceed to Step 2 until tests pass
- NEVER commit with `--no-verify` or similar flags
- Haiku fixes simple stuff, Opus fixes complex stuff

**Only when test-runner shows ✓ (all tests passing):** Proceed to Step 2.

### Step 2: Build Verification (if applicable)

Detect and run build command:

```bash
# Node.js
if [ -f "package.json" ] && grep -q '"build"' package.json; then
  npm run build
fi

# Go
if [ -f "go.mod" ]; then
  go build ./...
fi

# Rust
if [ -f "Cargo.toml" ]; then
  cargo build
fi
```

**If build fails:** Try simple fixes (missing files, typos), escalate to Opus if complex.

**Exit code must be 0.**

### Step 3: Lint Verification (if configured)

```bash
# Detect and run linter
if [ -f "package.json" ] && grep -q '"lint"' package.json; then
  npm run lint
elif [ -f "go.mod" ]; then
  golangci-lint run
elif [ -f "Cargo.toml" ]; then
  cargo clippy
fi
```

**If lint fails:** Haiku can usually auto-fix lint errors (formatting, unused vars, etc.)
- Run auto-fix if available: `npm run lint --fix` or `cargo clippy --fix`
- If no auto-fix or still failing, manually fix simple issues
- Escalate to Opus only if complex refactoring needed

### Step 4: Type Check (if applicable)

```bash
# TypeScript
if [ -f "tsconfig.json" ]; then
  npm run typecheck || tsc --noEmit
fi
```

**If type check fails:** Try simple fixes (add missing types, fix obvious type errors), escalate if complex.

---

## Verification Report Format

After ALL checks pass, report:

```
## Verification Gate ✓

Tests:     ✓ 47/47 passed (exit 0)
Build:     ✓ completed (exit 0)
Lint:      ✓ no errors (exit 0)
TypeCheck: ✓ no errors (exit 0)

All verification checks passed. Ready to merge.
```

If fixes were needed during verification:
```
## Verification Gate ✓

Fixed issues before passing:
- 2 missing imports (Haiku - simple fixes)
- 1 test failure escalated to Opus (complex logic error)

Tests:     ✓ 47/47 passed (exit 0)
Build:     ✓ completed (exit 0)
Lint:      ✓ no errors (exit 0)

All verification checks passed. Ready to merge.
```

---

## Usage

This skill is called automatically by `/kick` before merge (Step 6).

**Behavior:**
- Runs all verification checks (test-runner for tests)
- **Haiku fixes simple issues** (syntax, imports, formatting)
- **Escalates to Opus for complex issues** (logic errors, architectural problems)
- Loops until all checks pass
- Never proceeds with failures
- Never skips tests

Can also invoke directly for any verification need.

## Fix Escalation Strategy

**Haiku handles (max 2 attempts):**
- Missing imports
- Simple syntax errors
- Typos in identifiers
- Lint auto-fixes
- Obvious type annotations

**Escalate to Opus via systematic-debugging skill:**
- Logic errors in tests or code
- Multiple failing tests
- Complex type errors
- Architectural issues
- Anything requiring understanding of business logic

**Cost optimization:** Most verification passes have zero issues or simple fixes (Haiku), only escalate when needed (Opus).
