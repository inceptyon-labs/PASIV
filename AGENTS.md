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

## Architecture diagram

`docs/architecture.json` is the Archify spec for the system overview
(plugin runtime components, the /kick primary path, the developer-machine and
plugin trust boundaries, Codex and GitHub), with file:line sources pinned to
a commit. If a change adds, removes, or rewires a top-level component,
external service, trust boundary, or the deploy shape, update the spec after
committing it: re-pin `meta.repository.revision` to that commit, fix the
affected nodes, edges, and sources, re-render with the `archify` skill
(`finalize ... --repo-root .`), and commit the spec. Internal refactors and
shifted line numbers don't need it. Rendered HTML goes in `.archify/`
(gitignored).
