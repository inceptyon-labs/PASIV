# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-01-17

### Added
- GitHub Projects auto-integration for `/issue`, `/epic`, and `/backlog`
- Auto-creates project named after repo if none exists
- Prompts user when other projects exist (choose existing or create new)
- `/backlog` outputs suggested implementation order based on:
  - Layer dependencies (db → infra → backend → frontend)
  - Epic parent-child relationships
  - Explicit "Depends on #N" references

## [1.0.0] - 2026-01-16

### Added
- Initial release
- `/issue` - Create sized and labeled issues
- `/epic` - Create epics with subtasks
- `/backlog` - Parse spec files into issues
- `/start` - Full implementation flow (plan → implement → review → merge)
- `/review` - 3-model review pipeline (Sonnet → Opus → Codex)
- `/codex-review` - Deep Codex-only review
