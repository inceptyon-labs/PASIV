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

Enforced in `/kick`'s `execute` step: the Opus coordinator writes tests, a Sonnet implementer subagent makes them pass. Context isolation per task.

| Phase | Model | What Happens |
|-------|-------|-------------|
| RED | Opus (`execute` coordinator) | Writes ALL failing tests for the task, in-context |
| GREEN + REFACTOR + COMMIT | Sonnet (implementer subagent) | Implements each test, refactors, commits — in an isolated window |

1. **RED (Opus)**: Write all failing tests for this task's acceptance criteria
2. **Verify**: Tests fail for the right reason (missing feature, not syntax error)
3. **Dispatch the implementer subagent (Sonnet)**: it loops each failing test — GREEN → REFACTOR → COMMIT — in its own context, then returns a short status
4. **Continue (Opus)**: absorb the status, move to the next task

No production code without a failing test first. The better model writes tests because the test IS the spec — a bad test is invisible while bad code gets caught immediately. The noisy edit-test-iterate loop lives in the subagent's window, keeping the coordinator lean (standard 200k).

### TDD Violations

If you find yourself:
- Writing code before tests → delete code, write test first
- Writing production code in the coordinator instead of dispatching the implementer subagent → delete code, dispatch it
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
