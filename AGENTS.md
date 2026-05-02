# PASIV

> Tool-agnostic project guidance. Read by any AGENTS.md-compatible agent.

## Issue Type Hierarchy

| Level | Type | Scope | Example |
|-------|------|-------|---------|
| Epic | Strategic | Multiple features, spans weeks/months | "User Authentication System" |
| Feature | Tactical | Single capability, spans days/week | "OAuth Login" |
| Task | Execution | Single work item, hours | "Create OAuth callback endpoint" |

## Task Backend


- **github** — GitHub Issues + Project boards. Best for team collaboration.
- **beans** — Flat-file `.beans/` directory. Agent-native, version-controlled. Requires `beans` CLI.
- **local** — Markdown files in `docs/tasks/`. Zero external dependencies.
