# Review Profiles

A review **profile** is an ordered list of passes; each pass is an `engine` plus (for claude) a `model`. The `review` skill resolves a profile name to a pass chain and runs the passes **cascading** — each pass sees prior fixes.

## Built-in profiles

| Profile | Passes | When |
|---------|--------|------|
| `none` | — | skip review |
| `quick` | claude:sonnet | trivial changes |
| `standard` | claude:opus → codex | most changes (default) |
| `deep` | claude:opus → codex → claude:opus | security-critical / large refactors — final pass re-checks cumulative fixes |
| `codex` | codex | codex-only |

Sonnet is never paired with another pass — same-family findings are a subset of opus; diversity comes from crossing engines.

## Recommendation rule (size + security)

`plan` (and `kick`'s parent flow) recommend: XS/S → `quick` · M → `standard` · L/XL → `deep`. A security-pattern match bumps one level (`quick`→`standard`, `standard`→`deep`) and tags `[security]`.

Security patterns (canonical — `plan` Step 5 and `kick`'s parent flow carry runtime copies, keep in sync):

```
auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private|key
```

## `.pasiv.yml` override (optional — built-ins cover the common cases)

```yaml
review:
  default: standard
  profiles:
    none:     []
    quick:    [{ engine: claude, model: sonnet }]
    standard: [{ engine: claude, model: opus }, { engine: codex }]
    deep:     [{ engine: claude, model: opus }, { engine: codex }, { engine: claude, model: opus }]
```

## Engines — host-aware

| `engine` | under Claude Code | under Codex |
|----------|-------------------|-------------|
| `claude` | Task subagent at `model` | `claude -p` → Claude-as-reviewer |
| `codex` | `codex` MCP | native (Codex is the agent) |

So the same profile runs both directions. Host detected via `$CLAUDECODE` / `$CODEX_*`.

## Standalone

`/review [profile]` — e.g. `/review deep`, `/review codex`. Default profile from `.pasiv.yml` `review.default`, else `standard`.
