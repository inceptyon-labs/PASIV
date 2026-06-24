---
name: plan
description: Turn an issue into an approved, well-specified implementation plan and native tasks. Internal — called by /kick. Adopts writing-plans rigor, the ponytail ladder, and provenance-aware gap-checking.
model: opus
user-invocable: false
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Skill
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# Plan

Produce a plan a fresh implementer can execute with zero prior context, then create native tasks that carry it. Inputs from `/kick`: `$IDENTIFIER`, issue details, the parsed `WORKFLOW_*` config, and any loaded handoff.

## Step 1: Understand before planning

Read the issue and the code the change actually touches. Trace the real flow end to end. Map which files get created/modified and the single responsibility of each — decomposition gets locked here.

Lazy about the solution, never about reading. Do not skip comprehension to ship a small diff — the smallest change in the wrong place is a second bug.

## Step 2: Provenance-aware gap check

Where did this issue come from?

- **Traces to brainstorm/backlog** — the issue body or loaded handoff records decisions (a "User decisions" section, a design-doc link, or backlog parentage). The WHAT is settled. **Do not re-ask.** Plan from the record.
- **Bare one-off** (`/issue` → `/kick`, no recorded decisions) — the only place ambiguity gets caught before code. Surface the real gaps, each with a recommended default:

  > "The issue doesn't specify X. I'll assume Y unless you say otherwise."

  Recommend an answer to every gap; the user confirms or redirects in one pass. If a gap is answerable by reading the code, read it — don't ask.

Respect `WORKFLOW_PLAN_APPROVAL`: when **off** (autonomous), resolve every gap with a noted default and proceed — never stall. When **on**, gaps surface at the approval gate (Step 5).

## Step 3: Climb the ladder (don't over-plan)

Before specifying any task, stop at the first rung that holds:

1. **Does this need to exist?** Speculative → cut it, say so. (YAGNI)
2. **Already in this codebase?** Reuse it — don't re-implement what's a few files over.
3. **Stdlib does it?** Use it.
4. **Native platform feature?** `<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.
5. **Installed dependency?** Use it. Never add one for what a few lines do.
6. **One line?** One line.
7. **Only then:** the minimum that works.

Never simplify away: trust-boundary validation, data-loss handling, security, accessibility, or anything explicitly requested. Minimal ≠ unsafe.

## Step 4: Write the plan

Header:

```markdown
# [Issue title] — Implementation Plan

**Goal:** [one sentence]
**Approach:** [2-3 sentences]
**User decisions (already made):** [one line per decision, quotable; "none" if none]
```

Then one block per task:

````markdown
### Task N: [Component]

**Goal:** [one sentence — what this task produces]

**Files:**
- Create: `exact/path.ts`
- Modify: `exact/path.ts:120-145`
- Test: `tests/exact/path.test.ts`

**Acceptance Criteria:**
- [ ] [concrete, testable criterion]

**Verify:** `exact command` → expected output

**Steps:** [the real actions; show the code where a step writes code]
````

**Granularity** — each task is independently verifiable, touches one concern, earns its own commit. TDD cycles happen WITHIN a task (RED/GREEN/REFACTOR are execution detail), not as separate tasks.

**No placeholders** — these are *plan failures*, never write them: "TBD", "add error handling", "handle edge cases", "write tests for the above" (without the test code), "similar to Task N" (repeat it — tasks may be read out of order). Every code step shows the code.

Save to `docs/plans/YYYY-MM-DD-<issue-slug>.md`.

## Step 5: Approval + review tier

Recommend a review tier from size + security signal:

```bash
SECURITY_PATTERNS="auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private|key"
```

| Size | Default | If a planned file matches SECURITY_PATTERNS |
|------|---------|----------------------------------------------|
| XS | S | O [security] |
| S  | O | SC [security] |
| M  | SC | OC [security] |
| L  | OC | SOC [security] |
| XL | SOC | SOC [security] |

(Tiers are the current S/O/SC/OC/SOC chains; phase 2 turns these into `.pasiv.yml` review profiles.)

**If `PLAN_PREAPPROVED` is set** (autonomous parent flow) — skip every question, use the `REVIEW_TIER` the router already set, display the plan briefly, go to Step 6.

**If `WORKFLOW_PLAN_APPROVAL` is true** — AskUserQuestion, two questions:
1. "Approve this implementation plan?" → Approve / Revise / Cancel
2. "What review tier?" → S / O / SC / OC / SOC (mark the recommended one "(Recommended)", flag "[security]" where applicable)

Store `REVIEW_TIER`. Approve → Step 6. Revise → ask, update plan, re-ask. Cancel → stop, explain.

**If `WORKFLOW_PLAN_APPROVAL` is false** — auto-approve, use the recommended tier, display it. If `WORKFLOW_REVIEW` is also false, set `REVIEW_TIER = "SKIP"`. Continue.

## Step 6: Create native tasks

For each plan task, `TaskCreate` with the **full** Goal/Files/Acceptance Criteria/Verify block in the description — not a summary. The implementer subagent reads this via `TaskGet`; the plan doc is not a fallback. End each description with an embedded metadata fence so it survives `TaskGet`:

````
```json:metadata
{"files": ["src/x.ts","tests/x.test.ts"], "verifyCommand": "npm test x", "acceptanceCriteria": ["criterion 1"]}
```
````

Then create a **Review** task (`Review: [REVIEW_TIER]`) and a **Verification Gate** task. Set dependencies: each step blocks the next; review blockedBy all steps; verification blockedBy review. Run `TaskList` to show the structure.

## Step 7: Self-review (yourself, not a subagent)

1. **Coverage** — every issue requirement maps to a task? List gaps, add tasks.
2. **Placeholder scan** — hunt the red flags from Step 4; fix inline.
3. **Type consistency** — names/signatures used in later tasks match what earlier tasks define.

Fix and move on. No re-review.

## Return

End your response with the continuation marker the caller depends on:

```
>>> PLAN COMPLETE — proceed to execute (Step 3) <<<
```
