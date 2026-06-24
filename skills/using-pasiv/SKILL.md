---
name: using-pasiv
description: Skill awareness and decision flow reference. NOT user-invocable.
user-invocable: false
---

# Using PASIV Skills

Internal skill reference. NOT user-invocable. Per-project PASIV rules are added to the project's CLAUDE.md by `/pasiv init`.

## Core Principle

Before taking action on any development task, check if a PASIV skill applies. If a skill applies, use it.

## Do NOT Use EnterPlanMode

PASIV skills have their own planning built in. Do not use the `EnterPlanMode` tool when executing PASIV skills.

- `/kick` has Step 2 (Create Plan + Select Review Depth) — this IS the planning phase
- `/brainstorm` IS a planning/design skill
- `/backlog` creates structured work from plans

When to use EnterPlanMode: only for ad-hoc work that does not fit any PASIV skill (rare).

## Available Skills

### Ideation & Planning
| Skill | When to Use |
|-------|-------------|
| `/brainstorm` | Unclear requirements. Refine through Socratic dialogue. |
| `/brainstorm doc.md` | Half-baked plan/spec. Stress-test and refine it. |

### Task Management
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

### Code Review
| Skill | When to Use |
|-------|-------------|
| `/review [profile]` | Review the branch diff at a chosen depth — `quick` / `standard` / `deep` / `codex`, or legacy `S`/`O`/`SC`/`OC`/`SOC`. Profiles are configurable in `.pasiv.yml`. |

### Context Management
| Skill | When to Use |
|-------|-------------|
| `/handoff` | End of session, before switching tasks, or when prompted by PreCompact |
| `/reflect` | End of session, to persist durable facts, corrections, and reusable workflows to memory (deliberate; never auto-fires) |

### Security
| Skill | When to Use |
|-------|-------------|
| `/repo-scan` | Scan a repo for vulnerabilities, obfuscated code, malware, secrets |

### Setup
| Skill | When to Use |
|-------|-------------|
| `/pasiv init` | Configure task backend (GitHub, Beans, or local markdown) |

## Task Backend

PASIV supports pluggable task backends configured via `.pasiv.yml` in target project root. Default: local (zero-dependency); github/beans are opt-in. Run `/pasiv init` to configure.

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
Is this a standalone review? → /review [profile]
    ↓
Is this about scanning a repo? → /repo-scan
    ↓
End of session or context filling up? → /handoff (resume this task)
    ↓
Session had corrections or new preferences? → /reflect (persist durable learnings)
    ↓
None apply? → Proceed normally
```
