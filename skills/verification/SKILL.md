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

# Verification Gate

**The rule: no completion claim without fresh evidence.** Run the command, read the full output, and claim only what the output shows — with counts and exit code. Not evidence: a previous run, "should pass", "was passing earlier", a partial check, a subagent's success report.

**Good claim:** "Tests pass: 47/47, 0 skipped, exit 0"
**Bad claim:** "Tests should pass"

Run checks 1–5 in order. A check passes only on exit code 0 — investigate skipped tests and warnings before counting a pass.

## Fix escalation (applies to every check)

| Failure | Who fixes | How |
|---------|-----------|-----|
| Simple: missing import, typo'd identifier, syntax error, lint auto-fix, obvious type annotation | You (Haiku), max 2 attempts per check | Fix → commit `fix: address simple <check> errors` → re-run |
| Complex: logic errors, multiple failures with different causes, anything needing business-logic understanding | Escalate | **Skill:** `systematic-debugging` with the full failure output; it fixes and commits, then you re-run the check |

Loop each check until it passes. Hard rules:

- NEVER skip, disable, or mark tests as skipped to get past a failure
- NEVER use `--no-verify` or similar bypass flags
- NEVER move to the next check while the current one fails

## Check 1: Tests (required)

**Skill:** `test-runner`

Pass → Check 2. Fail → escalation table. "No tests found" should not happen after TDD — flag it in the report and continue.

## Check 2: Build (if applicable)

```bash
if [ -f package.json ] && grep -q '"build"' package.json; then npm run build
elif [ -f go.mod ]; then go build ./...
elif [ -f Cargo.toml ]; then cargo build
fi
```

## Check 3: Lint (if configured)

Try auto-fix first (`npm run lint -- --fix`, `cargo clippy --fix`), then:

```bash
if [ -f package.json ] && grep -q '"lint"' package.json; then npm run lint
elif [ -f go.mod ]; then golangci-lint run
elif [ -f Cargo.toml ]; then cargo clippy
fi
```

## Check 4: Type check (if applicable)

```bash
if [ -f tsconfig.json ]; then
  if grep -q '"typecheck"' package.json 2>/dev/null; then npm run typecheck; else tsc --noEmit; fi
fi
```

## Check 5: Project smoke command (if configured)

If `.pasiv.yml` has `verify.command`, run it verbatim — exit 0 required, escalation table applies. If not configured, skip silently.

## Report

After all checks pass:

```
## Verification Gate ✓

Tests:     ✓ 47/47 passed (exit 0)
Build:     ✓ completed (exit 0)
Lint:      ✓ no errors (exit 0)
TypeCheck: ✓ no errors (exit 0)
Smoke:     ✓ verify.command passed (exit 0)   [omit line if not configured]

All verification checks passed. Ready to merge.
```

If fixes were needed, list them above the table — what was fixed, and whether it was a simple fix or escalated.
