# Changelog

All notable changes to this project will be documented in this file.

## [2.0.83] - 2026-11-21

Summary of everything since 1.2.0. CI bumps the patch version on every push to `main`, so there are no per-release entries; `git log` has the detail.

### Added
- Rebrand to PASIV with Inception lore; Epic → Feature → Task hierarchy, sibling context between tasks
- `/start` renamed to `/kick`; native task tracking; baseline test run and verification gate with Haiku → Opus escalation
- Pluggable task backends (GitHub, beans, local markdown; local is the default), session handoffs, project-local `.pasiv.yml`
- `/brainstorm`, `/reflect`, hooks (PreCompact handoff reminder, `kick-guard`, plan-approval guard, Stop-hook state machine for turn discipline)
- Opt-in workflow toggles: plan approval, TDD, review, verification, UI verify, smoke command, coordinator model, token report, auto-reflect; `/pasiv init` update mode
- Parallelism: background baseline, composite context fetch, RED-ahead, parallel verification, worktree-isolated implementers, `fast` review profile
- `pasiv-extras` plugin: repo-scan, repo-ready, repo-tidy, app-store-ready, de-vibe, humanizer, fable-audit, agents-md, codex-image, design-pipeline, acp, acpd, uranus-deploy

### Changed
- `/kick` went from a 1,180-line monolith to a thin router over `plan` / `execute` / `review` / `finish` step-skills; Opus writes RED tests, a fresh Sonnet subagent does GREEN
- Six review skills collapsed into one profile-driven, host-aware `/review` (`quick` / `standard` / `fast` / `deep` / `codex`)
- Config reading and verification moved from prose to deterministic scripts (`read-config.sh`, `verify-checks.sh`)

### Removed
- `tdd` skill (folded into `execute`) and the six per-tier review skills (folded into `/review`)
- `nano-banana` image skill (replaced by `codex-image`)

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
