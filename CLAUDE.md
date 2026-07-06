@AGENTS.md

---

# Claude-specific additions

## Working on this plugin

- Task backend default is **local**; `github`/`beans` are opt-in via `.pasiv.yml` (`/pasiv init`).
- Skills locate scripts at runtime via the `*pasiv*/scripts/` glob — the install dir name must contain `pasiv`; never hardcode absolute script paths in skills.
- TDD in `/kick`: coordinator writes RED tests in-context; a fresh implementer subagent does GREEN → REFACTOR → COMMIT per task. No production code without a failing test first.
- Verification gate before any merge or "done" claim: tests, build, lint, type-check must pass with fresh evidence. No "should work" claims.

Product usage → `README.md`; detailed docs → `docs/reference/`.
