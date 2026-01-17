# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-01-17

### Changed
- **Breaking:** Renamed `/epic` to `/parent` for consistency with GitHub's native terminology
- Now uses GitHub's native parent/sub-issue relationships (`--parent` flag)
- Removed `[EPIC]` prefix and `epic` label (no longer needed)
- Updated `/backlog` to create parent issues with native sub-issues

### Removed
- `epic` label (use native sub-issues instead)

## [1.1.0] - 2026-01-17

### Added
- GitHub Projects auto-integration for `/issue`, `/epic`, and `/backlog`
- Auto-creates project named after repo if none exists
- Prompts user when other projects exist (choose existing or create new)
- `/backlog` outputs suggested implementation order based on:
  - Layer dependencies (db → infra → backend → frontend)
  - Parent/sub-issue relationships
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
