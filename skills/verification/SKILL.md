---
name: verification
description: Verification gate before completion claims. Ensures fresh evidence before merge or "done" claims. Used internally by /start.
allowed-tools:
  - Bash
  - Read
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

```bash
# 1. Tests pass
npm test || pytest || go test ./... || cargo test

# 2. Build succeeds (if applicable)
npm run build || go build ./... || cargo build

# 3. Lint clean (if configured)
npm run lint || golangci-lint run || cargo clippy

# 4. Type check (if applicable)
npm run typecheck || tsc --noEmit
```

**Each must show clean output with exit code 0.**

If any fail:
1. Fix the issue
2. Re-run verification
3. Only proceed when ALL pass

---

## Verification Report Format

After running verification, report:

```
## Verification Gate

Tests:     ✓ 47/47 passed (exit 0)
Build:     ✓ completed (exit 0)
Lint:      ✓ no errors (exit 0)
TypeCheck: ✓ no errors (exit 0)

Ready to merge.
```

Or if issues found:

```
## Verification Gate

Tests:     ✗ 45/47 passed, 2 failed
Build:     — skipped (tests failing)
Lint:      — skipped (tests failing)

BLOCKED: Fix failing tests before merge.
```

---

## Usage

This skill is called automatically by `/start` before merge (Step 6.5).

Can also invoke directly for any verification need.
