# Review Tiers

## Tier Table

| Tier | Name | Models | Cost | When to Use |
|------|------|--------|------|-------------|
| 1 | S | Sonnet | $ | Typos, config, trivial fixes |
| 2 | O | Opus | $$ | Simple features, clear scope |
| 3 | SC | Sonnet → Codex | $$ | Moderate changes, budget-conscious |
| 4 | OC | Opus → Codex | $$$ | Complex features, quality focus |
| 5 | SOC | Sonnet → Opus → Codex | $$$$ | Security-critical, large refactors |

All multi-pass reviews are **cascading** — each pass reviews cumulative changes including previous fixes.

## Recommendation Matrix

| Size | Default | If Security Files Detected |
|------|---------|----------------------------|
| `size:XS` | S | O |
| `size:S` | O | SC |
| `size:M` | SC | OC |
| `size:L` | OC | SOC |
| `size:XL` | SOC | SOC |

## Security File Patterns

Files matching these patterns trigger the security column:

```
auth|crypto|payment|token|secret|password|session|oauth|jwt|key|credential
```

## Standalone Review Commands

| Command | Tier |
|---------|------|
| `/s-review` | S (Sonnet) |
| `/o-review` | O (Opus) |
| `/sc-review` | SC (Sonnet → Codex) |
| `/oc-review` | OC (Opus → Codex) |
| `/soc-review` | SOC (Sonnet → Opus → Codex) |
| `/codex-review` | Standalone Codex |
