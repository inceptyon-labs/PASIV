---
name: brainstorm
description: Socratic design refinement before coding. Use when user has a vague idea, unclear requirements, or a half-baked plan that needs stress-testing. Outputs a validated design document.
model: opus
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

### Question Types

**Clarifying questions** - Fill in gaps:
- "Who will use this?"
- "What triggers this flow?"
- "What does success look like?"

**Challenging questions** - Stress-test assumptions:
- "What happens if X fails?"
- "How would this work with 10x the data?"
- "What's the simplest version that would be useful?"

**Scoping questions** - Define boundaries:
- "Is X in scope or out of scope?"
- "Do we need Y for the first version?"
- "What can we defer to later?"

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

Present 2-3 different approaches with trade-offs.

**Format:**

```
## Approach A: [Name] (Recommended)

**Summary:** [1-2 sentences]

**Pros:**
- [benefit]
- [benefit]

**Cons:**
- [drawback]
- [drawback]

**Best for:** [when to choose this]

---

## Approach B: [Name]

[same format]

---

## Approach C: [Name] (if applicable)

[same format]
```

**Always lead with your recommendation** and explain why.

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

### YAGNI (You Aren't Gonna Need It)
- Remove features that aren't essential for v1
- Challenge "nice to haves"
- Prefer simple over flexible

### One Question at a Time
- Don't overwhelm with multiple questions
- Let the user fully answer before moving on
- Build understanding incrementally

### Lead with Recommendations
- Don't just present options neutrally
- State which approach you'd choose and why
- User can always disagree

### Validate Incrementally
- Don't dump a 2000-word design
- Present in chunks, get feedback
- Adjust before moving on

### Document Decisions
- Capture the "why" not just the "what"
- Note what was explicitly deferred
- Record key trade-off decisions
