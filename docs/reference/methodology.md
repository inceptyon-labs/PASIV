# Development Methodology

## Baseline Test Run

Before starting work on an issue, `/kick` runs the full test suite to establish a clean baseline.

1. Haiku runs tests in background and reports results
2. If tests pass: continue with implementation
3. If tests fail: ask user how to proceed
   - Fix tests first (recommended) — repair baseline before starting
   - Proceed anyway — note that tests were already broken
   - Cancel — handle manually

This ensures you are not blamed for pre-existing test failures.

## TDD Cycle (Split-Model)

Enforced in `/kick`: RED → GREEN → REFACTOR → COMMIT → repeat.

| Phase | Model | Why |
|-------|-------|-----|
| RED (write test) | Opus | Tests are the spec — edge cases, API design, boundary conditions |
| GREEN (write code) | Sonnet | Constrained by test, "simplest thing that works" |
| REFACTOR | Sonnet | Tests guard against regressions |

1. **RED (Opus)**: Write one failing test
2. **Verify**: Test fails for the right reason (missing feature, not syntax error)
3. **GREEN + REFACTOR (Sonnet via `tdd`)**: Write minimal code to pass, clean up — single skill call
4. **COMMIT (Opus)**: Immediately after `tdd` returns, commit and continue to next cycle

No production code without a failing test first. The better model writes the test because the test IS the spec — a bad test is invisible while bad code gets caught immediately.

### TDD Violations

If you find yourself:
- Writing code before tests → delete code, write test first
- Test passes immediately → test does not test what you think, rewrite
- Adding features beyond the test → remove extras, stay minimal

## Verification Gate

Automated, smart escalation — Haiku handles simple issues, Opus handles complex.

1. **Tests**: Haiku runs test-runner
   - If pass: continue to next check
   - If fail: Haiku tries simple fixes (syntax, imports) — max 2 attempts
   - Still failing: escalate to Opus for systematic debugging
   - Loop until all pass
   - Never skip tests
2. **Build**: Same strategy — simple fixes first, escalate if needed
3. **Lint**: Haiku auto-fixes (usually works), escalate if complex
4. **Type Check**: Simple type fixes first, escalate if complex

Cost optimization: most verifications pass or need only simple Haiku fixes. Opus only invoked for complex failures.

Only proceeds to merge when all checks pass.

No "should work" or "was passing earlier" — verification gate ensures fresh evidence.

## Systematic Debugging

When tests fail during implementation or verification:

1. **Investigate** — read full error, identify root cause
2. **Hypothesize** — form specific theory ("X fails because Y")
3. **Test** — make one minimal change
4. **Verify** — run tests again

After 3 failed fix attempts, stop and reassess architecture. Do not guess at fixes.
