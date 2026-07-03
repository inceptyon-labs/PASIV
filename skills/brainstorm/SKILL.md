---
name: brainstorm
description: Socratic design refinement before coding. Use for vague ideas or half-baked plans needing stress-testing. Outputs a validated design doc.
model: opus
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
---

# Brainstorm

Refine ideas into validated designs through Socratic dialogue.

**Input:** $ARGUMENTS (optional path to existing document to refine)

---

## Phase 1: Understand the Starting Point

### If document provided (`/brainstorm spec.md`):

1. Read the document
2. Summarize what you understand (2-3 sentences)
3. Identify:
   - Gaps (what's missing?)
   - Assumptions (what's implied but not stated?)
   - Ambiguities (what could be interpreted multiple ways?)
   - Risks (what could go wrong?)

### If starting fresh (`/brainstorm`):

1. Ask: "What are you trying to build or solve?"
2. Listen to the response
3. Summarize what you heard (2-3 sentences)
4. Confirm: "Did I understand that correctly?"

---

## Phase 2: Socratic Dialogue

**One question at a time.** Do not overwhelm with multiple questions.

**Three rules (the grill-me interview):**
- **Recommend an answer to every question** — state the option you'd pick and why. The user confirms or redirects; they don't generate from scratch. Keeps momentum.
- **Codebase-first** — if a question is answerable by reading the code, read it instead of spending the user's turn.
- **Walk the decision tree** — resolve dependencies one at a time; later questions build on earlier answers. Stop when core purpose, constraints, success criteria, and scope are nailed.

Mix three question types: **clarifying** (fill gaps), **challenging** (stress-test assumptions — failure modes, 10x scale, simplest useful version), **scoping** (in/out of v1, what defers).

### Preferred Format

Use multiple-choice when possible:

```
How should authentication work?

A) Session-based (server stores state)
B) JWT tokens (stateless)
C) OAuth with external provider
D) Other
```

Open-ended when choices aren't clear:
- "What existing systems does this need to integrate with?"

### Continue Until

- Core purpose is clear
- Key constraints are identified
- Success criteria are defined
- Major edge cases are considered
- Scope boundaries are established

**Typically 5-10 questions. Stop when you have enough to propose approaches.**

---

## Phase 3: Explore Approaches

Present 2-3 different approaches. For each: `## Approach X: [Name]` with a 1-2 sentence summary, pros, cons, and "best for". Mark your pick `(Recommended)`, list it first, and explain why.

**Ask:** "Which approach resonates, or would you like to explore a hybrid?"

---

## Phase 4: Present the Design

Once an approach is selected, present the design in **200-300 word chunks**.

### Structure

```
## 1. Overview
[What we're building and why]

→ "Does this capture the goal? Any adjustments?"

## 2. Architecture
[Components and how they connect]

→ "Does this structure make sense?"

## 3. Data Model
[Key entities and relationships]

→ "Anything missing from the data model?"

## 4. Key Flows
[Primary user/system flows]

→ "Do these flows cover the main cases?"

## 5. Edge Cases & Error Handling
[What could go wrong and how we handle it]

→ "Any other edge cases to consider?"

## 6. Out of Scope (v1)
[What we're explicitly deferring]

→ "Agree with these deferrals?"
```

**Validate each section before moving to the next.**

---

## Phase 5: Document the Design

After all sections are validated, compile into a design document.

### Output Location

```
docs/designs/YYYY-MM-DD-<feature-name>.md
```

### Document Format

```markdown
# [Feature Name] Design

**Date:** YYYY-MM-DD
**Status:** Validated

## Summary
[2-3 sentence overview]

## Goals
- [goal 1]
- [goal 2]

## Non-Goals (Out of Scope)
- [explicitly deferred item]

## Architecture
[from Phase 4]

## Data Model
[from Phase 4]

## Key Flows
[from Phase 4]

## Edge Cases
[from Phase 4]

## Open Questions
[any unresolved items - should be minimal]

## Key Decisions
[Decisions resolved during brainstorming, quotable — these seed the plan's `User decisions (already made)` header so `/kick`'s plan step doesn't re-ask]
- [decision]: [what + why]

## Next Steps
- [ ] Create issues with `/backlog docs/designs/YYYY-MM-DD-<feature-name>.md`
- [ ] Or create manually with `/parent` or `/issue`
```

---

## Phase 6: Offer Next Steps

After saving the design:

```
Design saved to: docs/designs/YYYY-MM-DD-<feature-name>.md

Ready to create implementation issues?

Options:
1. `/backlog docs/designs/...` - Create Epic → Feature → Task hierarchy
2. `/parent <feature>` - Create single Feature with Tasks
3. `/issue <task>` - Create individual Tasks
4. Not yet - I'll review the design first
```

---

## Principles

- **YAGNI** — remove features not essential for v1, challenge "nice to haves", prefer simple over flexible.
- **Document decisions** — capture the *why*, not just the *what*; record trade-offs and what was explicitly deferred.
