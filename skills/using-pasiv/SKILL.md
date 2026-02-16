---
name: using-pasiv
description: Skill awareness guide injected at session start. NOT user-invocable.
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
| `/s-review` | S (Sonnet) — trivial changes |
| `/o-review` | O (Opus) — simple features |
| `/sc-review` | SC (Sonnet → Codex) — moderate, budget |
| `/oc-review` | OC (Opus → Codex) — complex, quality |
| `/soc-review` | SOC (Sonnet → Opus → Codex) — security-critical |
| `/codex-review` | Standalone Codex review |

### Context Management
| Skill | When to Use |
|-------|-------------|
| `/handoff` | End of session, before switching tasks, or when prompted by PreCompact |

### Security
| Skill | When to Use |
|-------|-------------|
| `/repo-scan` | Scan a repo for vulnerabilities, obfuscated code, malware, secrets |

### Setup
| Skill | When to Use |
|-------|-------------|
| `/pasiv init` | Configure task backend (GitHub, Beans, or local markdown) |

## Task Backend

PASIV supports pluggable task backends configured via `.pasiv.yml` in target project root. Default: github (backward compatible). Run `/pasiv init` to configure.

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
Is this a standalone review? → /s-review .. /soc-review
    ↓
Is this about scanning a repo? → /repo-scan
    ↓
End of session or context filling up? → /handoff
    ↓
None apply? → Proceed normally
```
