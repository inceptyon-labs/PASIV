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

**Run all applicable checks with the deterministic runner** — it detects the stack, runs tests/build/lint/typecheck/smoke (incl. `verify.command`) concurrently, and prints ✓/✗ per check with failure log tails. Never compose the check commands yourself:

```bash
VC=$(find ~/.claude -name "verify-checks.sh" -path "*pasiv*/scripts/*" 2>/dev/null | head -1)
bash "$VC"
```

Exit 0 → all detected checks passed → write the report. Exit 1 → **fix the failed checks serially** (escalation table below; lint auto-fix is allowed now — the runner itself never mutates files), then **re-run the script** until it exits 0. Full logs live in `/tmp/pasiv-verify/<check>.log`. If the runner reports "no checks detected", flag it in the report — after TDD that should not happen.

## Fix escalation (applies to every check)

| Failure | Who fixes | How |
|---------|-----------|-----|
| Simple: missing import, typo'd identifier, syntax error, lint auto-fix, obvious type annotation | You (Haiku), max 2 attempts per check | Fix → commit `fix: address simple <check> errors` → re-run |
| Complex: logic errors, multiple failures with different causes, anything needing business-logic understanding | Escalate | **Skill:** `systematic-debugging` with the full failure output; it fixes and commits, then you re-run the check |

Loop each check until it passes. Hard rules:

- NEVER skip, disable, or mark tests as skipped to get past a failure
- NEVER use `--no-verify` or similar bypass flags
- NEVER move to the next check while the current one fails

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
