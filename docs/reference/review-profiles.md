# Review Profiles

A review **profile** is an ordered list of passes; each pass is an `engine` plus (for claude) a `model`. The `review` skill resolves a profile name to a pass chain and runs the passes **cascading** — each pass sees prior fixes. Replaces the old fixed S/O/SC/OC/SOC tiers.

## Built-in profiles

| Profile | Passes | When |
|---------|--------|------|
| `none` | — | skip review |
| `quick` | claude:sonnet | trivial changes |
| `standard` | claude:opus → codex | most changes (default) |
| `deep` | claude:sonnet → claude:opus → codex | security-critical / large refactors |

## Legacy aliases (back-compat)

The old tier letters are recognized profile names: `S`→`quick`, `O`→[claude:opus], `SC`→[claude:sonnet, codex], `OC`→`standard`, `SOC`→`deep`, `codex`→[codex].

## Recommendation matrix (size + security)

`plan` recommends a profile from issue size and whether planned files match the security pattern:

| Size | Default | If security files |
|------|---------|-------------------|
| `size:XS` | S (quick) | O `[security]` |
| `size:S` | O | SC `[security]` |
| `size:M` | SC | OC (standard) `[security]` |
| `size:L` | OC (standard) | SOC (deep) `[security]` |
| `size:XL` | SOC (deep) | SOC (deep) `[security]` |

Security patterns: `auth|crypto|payment|token|secret|password|session|oauth|jwt|key|credential`

## `.pasiv.yml` override (optional — built-ins cover the common cases)

```yaml
review:
  default: standard
  profiles:
    none:     []
    quick:    [{ engine: claude, model: sonnet }]
    standard: [{ engine: claude, model: opus }, { engine: codex }]
    deep:     [{ engine: claude, model: sonnet }, { engine: claude, model: opus }, { engine: codex }]
```

## Engines — host-aware

| `engine` | under Claude Code | under Codex |
|----------|-------------------|-------------|
| `claude` | Task subagent at `model` | `claude -p` → Claude-as-reviewer |
| `codex` | `codex` MCP | native (Codex is the agent) |

So the same profile runs both directions. Host detected via `$CLAUDECODE` / `$CODEX_*`.

## Standalone

`/review [profile]` — e.g. `/review deep`, `/review codex`, or legacy `/review SOC`. Default profile from `.pasiv.yml` `review.default`, else `standard`.
