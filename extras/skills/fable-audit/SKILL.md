---
name: fable-audit
description: Judgment-led deep audit of a repo's highest-risk paths — tenant isolation, auth, money movement, shared state. Fable judges, cheap scouts discover, findings are adversarially verified. Use for "fable audit", "deep audit", "audit this repo with fable". Temporary skill — delete when Fable leaves the subscription.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Task
  - Write
---

# Fable Audit

Whole-repo audit of the paths where a bug costs real money or real trust. You (the session model — run this on Fable) are the judge: scouts gather facts, deep-divers analyze, you decide what's real and what matters. Spend your own reasoning only where the verdict hinges on it.

`$ARGUMENTS` (optional): specific domains to audit, e.g. `tenant isolation, billing`. Absent → derive from the repo.

## 1. Scope the risk surface

Read `README.md` and the top-level structure (`ls`, key config). Decide this repo's 3–6 high-risk domains from: auth/session, tenant/user data isolation, money movement (billing, trading, payouts), permissions/roles, shared state & concurrency, public API surface, migrations/data loss. Skip domains the repo doesn't have. State the chosen domains in one line each — what a failure there costs.

## 2. Scout fan-out (parallel, cheap)

Dispatch one Haiku subagent per domain, **all in one message**. Delegation template, nothing else:

```
GOAL: Map where <domain> lives in this repo.
SCOPE: read-only. Search and read; never edit.
CONTRACT: ≤15 lines. file:line refs + one-sentence facts (entry points, guards, queries,
where the boundary is enforced, where it looks unenforced). Never paste file contents.
DONE MEANS: every entry point and enforcement site for <domain> is listed, or explicitly "none found".
```

## 3. Judge the maps — you read the code that matters

From the scout reports, pick the sites where a decision hinges on the actual code (an unguarded query, a raw tenant filter, a money calculation). Read those ranges yourself — ~40 lines around each target, not whole files. Form a hypothesis list: suspected flaws, each with file:line and the failure it would cause.

## 4. Deep-dive the hard ones (Opus, parallel where disjoint)

For each hypothesis that needs cross-module reasoning (call chains, race windows, cache coherence), dispatch an Opus subagent:

```
GOAL: Confirm or kill this suspected flaw: <hypothesis, file:line, suspected failure>.
SCOPE: read-only; trace callers/callees as needed.
CONTRACT: ≤40 lines. Conclusion first (CONFIRMED | REFUTED | UNCLEAR), then reasoning, then evidence refs.
DONE MEANS: a concrete input/state → wrong outcome trace, or a demonstration the guard holds.
```

Simple single-file checks go to Sonnet with the same template, ≤20 lines.

## 5. Adversarial verify

Every CONFIRMED finding gets one skeptic pass (Sonnet): "Try to refute: <finding>. Default to refuted if the exploit path doesn't survive scrutiny." Findings the skeptic kills are dropped or downgraded — you break ties, agents don't re-litigate each other.

## 6. Report

Write `docs/scans/fable-audit-<YYYY-MM-DD>.md` (create the dir if missing) and summarize to the user:

- Findings ranked by severity (critical / important / note), each with `file:line`, the concrete failure scenario, and a fix sketch (not the fix itself).
- Domains audited and domains explicitly skipped — no silent gaps.
- Remaining risk: what this audit could not rule out.

Do not fix anything in this run. Fixes go through the project's normal flow (`/issue` + `/kick` where PASIV is configured).
