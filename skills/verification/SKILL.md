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

**Run all applicable checks with the deterministic runner** — it detects the stack, runs tests/build/lint/typecheck/smoke (incl. `verify.command`) concurrently, and prints ✓/✗ per check plus a final `PASIV_VERIFY_RESULT=` line. Lint is **scoped to the task's changed files** by the runner, so a lint failure is always inside your own diff. Never compose the check commands yourself:

```bash
VC=$(find ~/.claude -name "verify-checks.sh" -path "*pasiv*/scripts/*" 2>/dev/null | head -1)
bash "$VC"
```

Exit 0 → all detected checks passed → write the report. Exit 1 → **fix the failed checks serially** (escalation table below), then **re-run the script** until it exits 0. Full logs live in `/tmp/pasiv-verify/<check>.log`. If the runner reports "no checks detected" (`PASIV_VERIFY_RESULT=NONE`), flag it in the report — after TDD that should not happen.

## Fix escalation (applies to every check)

**Scope rule — hard, non-negotiable:** the fix loop may edit ONLY files already in the task's diff, plus new test files. NEVER edit a file the task didn't touch to make a check pass. If a check fails on unrelated, pre-existing code, that failure is **out of scope** — report it, do not fix it. (The runner already scopes lint to changed files, so this can't be provoked by lint.)

| Failure | Who fixes | How |
|---------|-----------|-----|
| Lint | You (Haiku), max 2 attempts | Run the linter's own fixer (`eslint --fix`, `swiftlint --fix`, etc.) on the **changed files only** — never hand-edit code to silence a rule. Commit `fix: lint` → re-run |
| Simple: missing import, typo'd identifier, syntax error, obvious type annotation | You (Haiku), max 2 attempts per check | Fix (changed files only) → commit `fix: address simple <check> errors` → re-run |
| Complex: logic errors, multiple failures with different causes, anything needing business-logic understanding | Escalate | **Skill:** `systematic-debugging` with the full failure output; it fixes and commits, then you re-run the check |

Loop each check until it passes. Hard rules:

- NEVER skip, disable, or mark tests as skipped to get past a failure
- NEVER use `--no-verify` or similar bypass flags
- NEVER move to the next check while the current one fails
- NEVER edit a file outside the task's diff to pass a check — that is overreach, not a fix

## Report

**Do NOT re-author the verdict.** The runner's stdout — derived from real exit codes — is the only source of truth. You may not type your own ✓/✗ lines or restyle them into a prettier table; that is exactly where a false "Build ✓" slips in. Instead:

1. Paste the runner's stdout **verbatim** inside a fenced block.
2. Quote its final `PASIV_VERIFY_RESULT=` line and act on it:
   - `=PASS` → append "All verification checks passed. Ready to merge."
   - `=FAIL` → do NOT claim done. Fix per the escalation table, re-run, repeat until PASS.
   - `=NONE` → no checks detected. Flag it (after TDD this should not happen). NOT ready to merge.

If fixes were made this run, list them above the pasted block — what was fixed, in which changed file, and whether it was a simple fix or escalated. A "Ready to merge" claim is valid ONLY when it sits directly under a pasted `PASIV_VERIFY_RESULT=PASS` from a fresh full run.
