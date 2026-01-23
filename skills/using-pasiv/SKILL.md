# Using PASIV Skills

This is injected at session start. It is NOT a user-invocable skill.

## Core Principle

**Before taking action on any development task, check if a PASIV skill applies.**

If a skill applies to your task, you must use it. This is not optional.

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
| `/start 42` | Implement a specific issue (plan → TDD → review → merge) |
| `/start next` | Work on highest priority open issue |

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
/brainstorm → design.md → /backlog design.md → /start next
```

**Clear requirements:**
```
/backlog spec.md → /start next
```

**Single task:**
```
/issue add feature X → /start 42
```

**Existing half-baked plan:**
```
/brainstorm existing-plan.md → refined design → /backlog → /start
```

## Methodology Skills (Internal)

These are used by `/start` internally, not invoked directly:

- `tdd` - Test-Driven Development (RED → GREEN → REFACTOR)
- `verification` - Pre-merge verification gate
- `systematic-debugging` - Root cause analysis when tests fail

## Red Flags - You're Bypassing the System

Stop and reconsider if you find yourself:

- Writing code without checking for applicable skills
- Treating a request as "too simple" for skills
- Skipping brainstorming when requirements are unclear
- Creating issues without using `/issue`, `/parent`, or `/backlog`
- Implementing without `/start`

## Decision Flow

```
User request arrives
    ↓
Is this about refining an idea? → /brainstorm
    ↓
Is this about creating issues? → /issue, /parent, or /backlog
    ↓
Is this about implementing an issue? → /start
    ↓
Is this a standalone review? → /s-review, /o-review, /sc-review, /oc-review, /soc-review
    ↓
None apply? → Proceed normally
```
