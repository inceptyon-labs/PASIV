# PASIV Streamline — CC-Native, Lean-Context, Pluggable Reviews

> Design doc. Status: **proposed**. Author trigger: comparison against the community
> `pcvelz/superpowers` fork. Supersedes the direction in
> `docs/plans/2025-01-19-superpowers-integration.md` where they overlap.

## Goals

1. **Streamline** — fewer skills, less duplicated surface.
2. **CC-native** — lean on native Task tools, subagent dispatch, worktree isolation.
3. **Fewer tokens / faster** — stop accumulating everything in one orchestrator context.
4. **Get off metered 1M** — make the workflow run on standard 200k so Sonnet workers stay on subscription.
5. **Pluggable reviews** — swap review depth per project, and run engine-agnostic (Claude-as-reviewer even under a Codex host).

## Principles

- **Lean orchestrator.** `kick` holds the plan + short per-task summaries. Nothing noisy (diffs, test logs, review passes) lives in its context.
- **Isolation via subagents.** The noisy work runs in a fresh subagent window and returns a summary. Ephemeral context ≠ orchestrator context.
- **Config over skills.** Review depth is data in `.pasiv.yml`, not six hardcoded skills.
- **Engine adapters.** "Who reviews" is an adapter choice, so the same profile works Claude-native or Codex-native.
- **Keep our edge.** Codex cross-model review, beans, de-vibe / repo-ready / app-store-ready, handoff, theming — untouched.

---

## 1. Skill boundaries — decompose `kick`

Today `kick` is **1,180 lines** loaded in full on every invocation, including 6 review-tier branches and the autonomous parent flow that mostly don't fire. Split into a thin orchestrator that invokes step-skills on demand.

| Today | Target | Notes |
|-------|--------|-------|
| `kick` (1180 ln, everything inline) | `kick` (thin router, ~150 ln) | Detect backend, load handoff, sequence steps |
| (inline in kick) | `plan` | Plan + native `TaskCreate` from tasks |
| `tdd` (inline GREEN) | `execute` | Dispatch implementer subagent per task |
| s/o/sc/oc/soc/codex-review (6 skills) | `review` (1 skill + adapters) | Reads profile from `.pasiv.yml` |
| (inline in kick) | `verify` | Verification gate (unchanged logic) |
| (inline in kick) | `finish` | Merge / handoff / close |
| `issue-ops`, `project-ops` | **deleted** | GitHub-only; not used |

Net: ~31 skills → ~24, and a simple `/kick` loads ~150 lines instead of ~1180.

---

## 2. Standard-context dispatch model

### The 1M problem (why this matters)

The 1M window is a **session-level beta** (`claude-opus-4-8[1m]`), negotiated at connect time. It can't be passed per-message or stripped per-dispatch. A subagent dispatched from a 1M-Opus parent **inherits the 1M tier but not the `/extra-usage` entitlement** for its model — so a `model: sonnet` worker fails with `Extra usage is required for 1M context` or meters outside subscription. Anthropic has this filed and closed **not-planned**, so there is no per-subagent opt-out. It's all-or-nothing per session.

**This already bites the current plugin:** `tdd` declares `model: sonnet` and runs under an Opus-1M parent.

### The fix — run the whole workflow on standard 200k

Decomposition (§1) keeps the orchestrator lean enough that it never needs 1M. So launch the PASIV session with the disable flag and everything — orchestrator + every subagent — runs standard 200k, on subscription.

**Flag:** `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` (removes 1M variants from the picker for that session only; does not touch the global default).

**Option A — launch alias** (recommended; PASIV runs across many repos):

```bash
# ~/.zshrc
alias kick='CLAUDE_CODE_DISABLE_1M_CONTEXT=1 claude'
```

**Option B — per-project local settings** (when specific repos always use the flow). Personal, gitignored, overrides the user default in that repo only:

```jsonc
// .claude/settings.local.json
{ "env": { "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1" } }
```

Cascade: managed → CLI args → `settings.local.json` → `settings.json` → `~/.claude`.

> Hard constraint: this must be set **at launch**. A skill or hook cannot flip it mid-session (same reason the beta can't be stripped per-dispatch). `/pasiv init` should print both options; `using-pasiv` should mention the alias.

### Test quality under subagent dispatch

Keep the split-model TDD that makes our tests good — **just move only GREEN off-context**:

- **RED stays in the orchestrator** (Opus, full design context) — it authors the failing tests = the spec.
- **GREEN dispatches to a subagent** (Sonnet, fresh window) — "make these specific failing tests pass." The failing test *is* the complete spec, so the worker needs only the test file + target source + verify command. Minimal context, isolated noise, preserved test quality.
- Reviews dispatch to subagents too (keeps the Codex cascade).

---

## 3. Pluggable reviews

### `.pasiv.yml` — review profiles (data, not skills)

```yaml
review:
  default: standard
  profiles:
    none:     []                                                    # skip review
    quick:    [{ engine: claude, model: sonnet }]
    standard: [{ engine: claude, model: opus }, { engine: codex }]
    deep:     [{ engine: claude, model: sonnet }, { engine: claude, model: opus }, { engine: codex }]
```

A project that doesn't use our tiers defines its own profiles (or `none`). The `review` skill reads the named profile and runs its passes in order. Old S/O/SC/OC/SOC map onto profiles for back-compat.

### Engine adapter interface

Each pass names an `engine`. An adapter is a thin shim:

```
review(engine, model?, diffRange, prompt, severityThreshold) -> findings[]
  findings[] = { severity: blocker|important|nit, file, line, note }
```

Host detection picks the invocation mechanism, which is what enables the Codex-inversion goal:

| engine | host = Claude Code | host = Codex |
|--------|--------------------|--------------|
| `claude` | dispatch Agent subagent at `model` (native, free) | shell to `claude` CLI / MCP (external reviewer) |
| `codex` | call codex MCP (external, current path) | native |

Same profile, both directions — only which engine is "native vs external" flips. (Mirrors how superpowers maps tool names per host in `references/{codex,copilot}-tools.md`.)

Decoupling `review` from `kick` also lets any workflow call it standalone.

---

## 4. Worktrees — a flag, not a workflow

Worktrees buy isolation **for concurrent writers only**. Sequential `/kick` (test + source iterated together) gets nothing from them but overhead. The CC-native mechanism is the Agent tool's `isolation: "worktree"` (auto-created, auto-cleaned), used per dispatch.

| Situation | Use |
|-----------|-----|
| Sequential tasks (default `/kick`) | plain branch, no worktree |
| Parallel implementers on **disjoint `files`** | `isolation: worktree` per dispatch |
| Keep `main` checkout live during a long autonomous run | one worktree for the run |

Keep the branch model; reach for worktrees only when bounded-parallel dispatch is on.

---

## 5. Backend

Beans is local, flat-file, version-controlled, dependency-aware (`beans list --ready`) — already the thing superpowers reimplements with native tasks. So: **keep beans; delete the GitHub-only skills** (`issue-ops`, `project-ops`). `kick` continues hydrating beans → native `TaskCreate` for in-session visibility (durable store = beans, execution view = native tasks). Local backend stays as the zero-dep option.

---

## 6. Docs & README impact (apply alongside implementation)

These describe **unbuilt** behavior, so they ship *with* the code, not before:

- `README.md` — collapse the Review-Tiers table into the profile model; drop `issue-ops`/`project-ops` from Plugin Structure & Model Optimization; update the `/kick` step list (subagent dispatch); add a "Running on standard context" note pointing at the alias.
- `CLAUDE.md` / `AGENTS.md` — update the Commands table and Plugin Structure tree; replace the 6 review-skill rows with `review`.
- `docs/reference/review-tiers.md` — rewrite around profiles + adapters.
- `docs/reference/model-optimization.md` — **done now** (1M-context note is true today; see that file).
- `using-pasiv` / `pasiv-init` — mention the launch alias.

---

## 7. Tracking upstream Superpowers

Manual, read-only diff — no auto-pull. `scripts/superpowers-diff.sh` clones the chosen fork into a gitignored cache and reports what changed since the SHA you last marked reviewed.

```bash
scripts/superpowers-diff.sh           # commits + changed skills since last seen
scripts/superpowers-diff.sh --skills  # upstream skills vs ours (gap list)
scripts/superpowers-diff.sh --seen    # mark current tip as reviewed
REPO=obra/superpowers scripts/superpowers-diff.sh   # diff the original instead
```

Run it when you want to triage; pull in only what fits.

---

## 8. Pattern adoptions (researched)

Sources: `pcvelz/superpowers` (writing-plans, requesting-code-review), `mattpocock/skills` (grilling, handoff). Take the sharp bits; skip the team machinery.

### `plan` step-skill ← superpowers `writing-plans`

- **No-Placeholders rule** — "TBD", "add error handling", "write tests for the above", "similar to Task N" are *plan failures*. Every code step shows the actual code.
- **Task block** — Goal / Files (exact create/modify/test paths) / Acceptance Criteria (checkboxes) / Verify (exact command → expected output) / Steps (real code).
- **Self-review checklist** (self, not a subagent): spec-coverage, placeholder-scan, type-consistency.
- **Plan header `User decisions (already made)`** — quotable, so execution never re-asks.
- **Embed `json:metadata` in the task description** (files / AC / verifyCommand / modelTier) — TaskGet doesn't return the metadata *param*, so embed it in the description; this is what the GREEN and review subagents parse.
- Skip: the user-gate tagging machinery (gate-detection steps) — team enforcement, non-goal.

### `review` step-skill ← superpowers `requesting-code-review`

Confirms the §3 engine-adapter shape. Adopt:
- Dispatch reviewer with **crafted context + SHA range** (`BASE_SHA`/`HEAD_SHA`), never session history.
- **Severity taxonomy** blocker / important / nit (their Critical/Important/Minor) — already the adapter `findings` contract.
- A reusable reviewer **prompt template** per engine (their `code-reviewer.md`).
- Act-on-feedback: fix blocker + important before proceeding; push back with evidence if the reviewer is wrong.

### `grilling` ← mattpocock — placed by intensity, not in one skill

Substance lives in mattpocock's `grilling` (its `grill-me` is just a user-invoked trigger). Split across the pipeline by how hard it questions:

- **`brainstorm` (full interview):** relentless, one-at-a-time, walk the decision tree resolving dependencies; **recommend an answer to every question**; **codebase-first** (if a question is answerable by reading code, read it). This is the design-hardening surface. Capture each resolved decision into the `plan` header's `User decisions (already made)` → brainstorm feeds plan feeds execution; nothing re-asked.
- **`backlog` (gap pre-flight only):** take just the **recommend-an-answer** rule. Today backlog reports spec gaps in Step 7 — *after* issues are created. Move that earlier: before decomposing, surface the few real ambiguities **with recommended defaults** ("spec doesn't specify X; assuming Y unless you say otherwise") so a thin spec doesn't decompose into vague tasks. Keep it fast — a pre-flight, not a full interview (that's brainstorm's job; duplicating it here is bloat).
- **`plan` (light, provenance-aware):** recommend-an-answer + the superpowers self-review checklist to harden task boundaries / underspecified steps. Gate the questioning on provenance so settled designs aren't re-litigated:
  - Issue traces to brainstorm/backlog (decisions present in the `User decisions (already made)` header) → **don't re-ask**; plan + ladder + self-review only.
  - Bare one-off issue (`/issue` → `/kick`, no recorded decisions) → run the recommend-an-answer gap pass before generating tasks — the only place ambiguity gets caught.
  - Respect `WORKFLOW_PLAN_APPROVAL`: **on** → surface gaps at the approval gate; **off** (autonomous) → resolve with *noted defaults*, never stall.

No new skill — these are rules folded into `brainstorm`, `backlog`, and `plan`. The `User decisions (already made)` header is the dedup mechanism: question once, at the right altitude, never twice.

### `handoff` ← mattpocock `handoff`

Keep PASIV's `docs/handoffs/` location (version-controlled — do **not** adopt their OS-temp location). Adopt:
- **DRY: reference artifacts by path/URL, don't duplicate** plans/diffs/issues — direct token win.
- **"Suggested skills" section** — tell the next session which skills to invoke.
- **Redact secrets/PII.**
- Optional **focus arg** — "what's the next session for" tailors the doc.

### `plan` + `execute` ← ponytail (principle, not the plugin)

Inject the over-engineering ladder as a pre-write reflex. Do **not** install the ponytail plugin — its modes/hooks/statusline/extra commands are bloat, and `de-vibe` + `tdd` + `tenet-complexity`/`tenet-solid` already cover the adjacent ground.

Take:
- **The ladder** (~8 lines) into the `plan` task-shaping step and the implementer/GREEN dispatch prompt: need it at all? (YAGNI) → reuse in-codebase → stdlib → native platform → installed dep → one line → minimum that works.
- **Guardrails verbatim** — never lazy about: trust-boundary validation, data-loss handling, security, a11y, or understanding the problem first. Minimal ≠ unsafe.
- **Optional: the `ponytail:` comment** for a deliberate shortcut that names its ceiling + upgrade path (high-signal intent — survives `de-vibe`).

Skip: the plugin, intensity modes, `/ponytail-audit|debt|gain|help`.

Why it fits: it's the project's own "no unrequested abstractions / no in-case scaffolding" value, codified and benchmarked (−54% LOC, −22% tokens, −27% time on a real agentic run) — advancing the exact reduce-tokens/faster goals at the one place code gets written. Complements `de-vibe` (slop code vs slop prose).

### teach — out of scope

A stateful multi-session learning workspace; orthogonal to handoff/brainstorm. Candidate for a separate future skill, not this plan.

---

## Sequencing

1. **Decompose `kick` + GREEN-subagent dispatch + standard-context launch** — unlocks the rest; hits tokens/speed/1M at once. New `plan` skill adopts §8 writing-plans patterns; `plan` + implementer dispatch inject the §8 ponytail ladder.
2. **Review profiles in `.pasiv.yml`** — collapse 6 skills → `review`, adopting §8 requesting-code-review patterns.
3. **Engine adapters** — Codex-inversion.
4. **Delete `issue-ops`/`project-ops`**; docs/README sweep.
5. **`brainstorm` + `handoff` sharpening** (§8) — independent, low-risk, do anytime.
6. **Optional:** model-routing hook (lifted from superpowers), bounded-parallel + worktree flag.

## Non-goals

- Adopting superpowers' user-gate enforcement or brainstorm websocket server (team machinery, overkill solo).
- Migrating onto the superpowers base (would mean rebuilding beans/Codex/product skills/theming for negative gain).
- Auto-syncing upstream.

## Open questions

- Does `verify` stay inline or also dispatch? (Lean toward inline — it's short and already escalates.)
- Back-compat: keep `/s-review`…`/soc-review` as thin aliases onto profiles, or hard-cut?
