---
name: using-pasiv
description: Skill awareness guide injected at session start. NOT user-invocable.
user-invocable: false
---

# Using PASIV Skills

This is injected at session start. It is NOT a user-invocable skill.

## Core Principle

**Before taking action on any development task, check if a PASIV skill applies.**

If a skill applies to your task, you must use it. This is not optional.

## CRITICAL: Do NOT Use EnterPlanMode

**PASIV skills have their own planning built in. Do NOT use the `EnterPlanMode` tool when executing PASIV skills.**

- `/kick` has Step 2 (Create Plan + Select Review Depth) - this IS the planning phase
- `/brainstorm` IS a planning/design skill
- `/backlog` creates structured work from plans

Using `EnterPlanMode` during a PASIV skill derails the workflow. The skill instructions ARE the plan.

**When to use EnterPlanMode:** Only for ad-hoc work that doesn't fit any PASIV skill (rare).

## Available Skills

### Ideation & Planning
| Skill | When to Use |
|-------|-------------|
| `/brainstorm` | User has an idea but unclear requirements. Refine through Socratic dialogue. |
| `/brainstorm doc.md` | User has a half-baked plan/spec. Stress-test and refine it. |

### Issue Creation
| Skill | When to Use |
|-------|-------------|
| `/issue` | Create a single Task |
| `/parent` | Create a Feature with Task sub-issues |
| `/backlog` | Create Epic → Feature → Task hierarchy from spec |

### Implementation
| Skill | When to Use |
|-------|-------------|
| `/kick 42` | Implement a specific issue (plan → TDD → review → merge) |
| `/kick next` | Work on highest priority open issue |

### Code Review (standalone)
| Skill | When to Use |
|-------|-------------|
| `/s-review` | S (Sonnet) - trivial changes |
| `/o-review` | O (Opus) - simple features |
| `/sc-review` | SC (Sonnet → Codex) - moderate, budget |
| `/oc-review` | OC (Opus → Codex) - complex, quality |
| `/soc-review` | SOC (Sonnet → Opus → Codex) - security-critical |
| `/codex-review` | Standalone Codex review |

## Workflow Patterns

**New idea, unclear scope:**
```
/brainstorm → design.md → /backlog design.md → /kick next
```

**Clear requirements:**
```
/backlog spec.md → /kick next
```

**Single task:**
```
/issue add feature X → /kick 42
```

**Existing half-baked plan:**
```
/brainstorm existing-plan.md → refined design → /backlog → /kick
```

## Methodology Skills (Internal)

These are used by `/kick` internally, not invoked directly:

- `tdd` - Test-Driven Development (RED → GREEN → REFACTOR)
- `verification` - Pre-merge verification gate
- `systematic-debugging` - Root cause analysis when tests fail

## Red Flags - You're Bypassing the System

Stop and reconsider if you find yourself:

- **Using `EnterPlanMode` during a PASIV skill** - the skill IS the plan
- Writing code without checking for applicable skills
- Treating a request as "too simple" for skills
- Skipping brainstorming when requirements are unclear
- Creating issues without using `/issue`, `/parent`, or `/backlog`
- Implementing without `/kick`

## Decision Flow

```
User request arrives
    ↓
Is this about refining an idea? → /brainstorm
    ↓
Is this about creating issues? → /issue, /parent, or /backlog
    ↓
Is this about implementing an issue? → /kick
    ↓
Is this a standalone review? → /s-review, /o-review, /sc-review, /oc-review, /soc-review
    ↓
None apply? → Proceed normally
```
