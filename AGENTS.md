# PASIV

> Tool-agnostic project guidance. Read by any AGENTS.md-compatible agent.

## Invariants

- Skills find their scripts at runtime with `find ~/.claude -name <script> -path "*pasiv*/scripts/*"`, so the install directory name must contain `pasiv`. Never hardcode an absolute script path in a skill.
- `extras/skills/` ships in a public repo. Private hosts, IPs and service details stay out of it; `uranus-deploy` keeps its private values in a gitignored `.env` next to its SKILL.md.
- New workflow gates or steps ship as an opt-in `.pasiv.yml` toggle (default off) plus a `/pasiv init` question, like `workflow.ui_verify` and `verify.command`.
- `docs/reference/labels.md` and `docs/reference/review-profiles.md` are canonical, but skills carry runtime copies: the label color table in `skills/issue-ops/SKILL.md`, the security patterns in `skills/plan/SKILL.md` and `skills/kick/SKILL.md`. Change them together.

## Workflows

- Don't bump versions by hand. `.github/workflows/version-bump.yml` bumps the patch in `.claude-plugin/plugin.json` and `marketplace.json` on every push to `main` and pushes its own commit, so `git pull --rebase` before the next push. It bumps only the core `pasiv` entry. `pasiv-extras` has no `version` field on purpose, so users get its changes on every commit; Claude Code only updates a versioned plugin when the version string changes.

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
