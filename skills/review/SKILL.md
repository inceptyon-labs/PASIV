---
name: review
description: Review the branch diff at a configurable depth. Use for "review", "code review", "s-review/o-review/sc-review/oc-review/soc-review", "codex review", or a named profile (quick/standard/deep/codex). Reads review profiles from .pasiv.yml with built-in fallbacks. Also called by /kick.
model: opus
user-invocable: true
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

Run a review profile over the branch diff. Each pass is dispatched with **crafted context + a SHA range**, never your session history — this keeps your coordinator context lean and makes the model boundary real (a "sonnet pass" actually runs on Sonnet).

**Invocation:**
- **Standalone** `/review [profile]` — reviews `git diff main` at the named profile (default: `.pasiv.yml` `review.default`, else `standard`).
- **From `/kick`** — the router sets `REVIEW_PROFILE`, `WORKFLOW_REVIEW`, `$IDENTIFIER`, and the review task id.

## Resolve the profile → a pass chain

A profile is an ordered list of passes; each pass is an `engine` plus (for claude) a `model`. Resolve in order:

1. **`.pasiv.yml` `review.profiles.<name>`** if defined.
2. **Built-ins:**

   | Profile | Passes |
   |---------|--------|
   | `none` | — (skip) |
   | `quick` | claude:sonnet |
   | `standard` | claude:opus → codex |
   | `deep` | claude:sonnet → claude:opus → codex |

3. **Legacy tier aliases** (back-compat for the size/security recommendation and old muscle memory): `S`→`quick`, `O`→[claude:opus], `SC`→[claude:sonnet, codex], `OC`→`standard`, `SOC`→`deep`, `codex`→[codex].

`.pasiv.yml` schema (optional — built-ins cover the common cases):

```yaml
review:
  default: standard
  profiles:
    none:     []
    quick:    [{ engine: claude, model: sonnet }]
    standard: [{ engine: claude, model: opus }, { engine: codex }]
    deep:     [{ engine: claude, model: sonnet }, { engine: claude, model: opus }, { engine: codex }]
```

## Engines — host-aware dispatch

A pass names an `engine`; how that engine is invoked depends on the **host** PASIV is running under. Detect the host once: `$CLAUDECODE` set → **Claude Code**; `$CODEX_*` (e.g. `$CODEX_SANDBOX`) set → **Codex**; else fall back to whichever CLI is on `PATH`.

| `engine` | under Claude Code | under Codex |
|----------|-------------------|-------------|
| `claude` | **Task subagent** at `model` — in-process, native | shell **`claude -p`** with brief+diff — external reviewer |
| `codex` | **`mcp__my-codex-mcp__codex`** MCP (CLI fallback: `codex exec`) | **native** — Codex reviews directly (it is the running agent) |

The brief and the severity rules are identical across transports — only delivery changes. So **one profile runs both directions**: under Codex, `engine: claude` makes Claude the reviewer; under Claude Code, `engine: codex` makes Codex the reviewer.

## Skip path

If the resolved profile is `none`/empty, or `WORKFLOW_REVIEW` is false → display "Code review skipped", mark the review task completed (if from /kick), return.

## Run (per pass, in order)

If from /kick, mark the review task `in_progress`. Reviews are **cascading** — fresh diff before each pass so it sees prior fixes:

```bash
BASE_SHA=$(git rev-parse main); HEAD_SHA=$(git rev-parse HEAD); git diff main
```

Build the review **brief** once, then deliver it via the pass's engine adapter (Engines table):

```
Independent code review of the diff below (BASE <BASE_SHA> → HEAD <HEAD_SHA>).
What it should do: <issue title / acceptance criteria>.
Look for: correctness bugs, security (injection/auth/XSS/secrets), missing error handling,
test gaps, and over-engineering (code that stdlib/native/an existing helper already covers).
Classify each finding: blocker | important | nit. Return findings only — no preamble.
```

- **claude transport** — subagent (Claude Code) or `claude -p "<brief>\n\n<diff>"` (Codex): pass the brief + diff.
- **codex transport** — MCP `codex` (Claude Code) with `code`=diff / `prompt`=brief / `context`="pass N of <profile>"; or native review (Codex). Codex MCP/CLI times out on large inputs — chunk a big diff.

**After each pass:** fix every **blocker** and **important** finding (TDD — failing test first if missing), then:

**Use Skill tool:** `git-ops` with args: `commit "fix: address <engine> review findings"`

Note nits, don't block on them. Push back (with evidence) if a finding is wrong. Proceed to the next pass.

## Return

**From `/kick`:** mark the review task `completed`, check off the issue's acceptance criteria (**Skill:** `task-ops` `check-off-criteria $IDENTIFIER`), and end with:

```
>>> REVIEW COMPLETE — proceed to verification (Step 6) <<<
```

**Standalone:** print a findings summary grouped by severity (blocker / important / nit) with `file:line`, and what was fixed vs noted.
