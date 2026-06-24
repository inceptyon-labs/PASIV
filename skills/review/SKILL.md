---
name: review
description: Run the selected review tier over the branch diff, dispatching reviewer subagents per pass. Cascading — each pass sees prior fixes. Internal — called by /kick. (Phase 2 turns the tier chains into .pasiv.yml profiles + engine adapters.)
model: opus
user-invocable: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
  - Task
  - mcp__my-codex-mcp__codex
  - TaskUpdate
---

# Review

Run `REVIEW_TIER` over the branch diff. Each pass is dispatched with **crafted context + a SHA range**, never your session history — this keeps your coordinator context lean and makes the model boundary real (a "Sonnet pass" actually runs on Sonnet).

Inputs from `/kick`: `REVIEW_TIER`, `WORKFLOW_REVIEW`, `$IDENTIFIER`, the review task id.

## Skip path

If `WORKFLOW_REVIEW` is false or `REVIEW_TIER = "SKIP"` → display "Code review skipped", mark the review task completed, return.

## Tier → pass chain

```
S   → [sonnet]
O   → [opus]
SC  → [sonnet, codex]
OC  → [opus, codex]
SOC → [sonnet, opus, codex]
```

Mark the review task `in_progress`.

## Per pass (in order)

Reviews are **cascading** — get a fresh diff before each pass so it sees prior fixes:

```bash
BASE_SHA=$(git rev-parse main)
HEAD_SHA=$(git rev-parse HEAD)
git diff main
```

**Claude pass (`sonnet` / `opus`):** dispatch a reviewer subagent with the Task tool at that `model`, handing it the diff + this brief:

```
Independent code review of the diff below (BASE <BASE_SHA> → HEAD <HEAD_SHA>).
What it should do: <issue title / acceptance criteria>.
Look for: correctness bugs, security (injection/auth/XSS/secrets), missing error handling,
test gaps, and over-engineering (code that stdlib/native/an existing helper already covers).
Classify each finding: blocker | important | nit. Return findings only — no preamble.

<diff>
```

**Codex pass:** call `mcp__my-codex-mcp__codex` with `code` = the fresh diff, `prompt` = "Independent review — catch what earlier passes missed: subtle bugs, security edge cases, test gaps. Classify blocker/important/nit.", `context` = "Pass N of <TIER>; issues prior passes missed." (Codex MCP times out on large inputs — chunk a big diff.)

**After each pass:** fix every **blocker** and **important** finding (TDD — write the failing test first if missing), then:

**Use Skill tool:** `git-ops` with args: `commit "fix: address <pass> review findings"`

Note nits, don't block on them. Push back (with evidence) if a finding is wrong. Then proceed to the next pass.

## Return

Mark the review task `completed`. Check off the issue's acceptance criteria:

**Use Skill tool:** `task-ops` with args: `check-off-criteria $IDENTIFIER`

End your response with:

```
>>> REVIEW COMPLETE — proceed to verification (Step 6) <<<
```
