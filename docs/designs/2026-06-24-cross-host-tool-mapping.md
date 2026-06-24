# PASIV Cross-Host Tool Mapping

> Design doc. Status: **proposed, not implemented.** For a future session.
> Scope: what it takes to run the **full** PASIV pipeline (not just review) under
> Codex and other AGENTS.md hosts. Phase 3 already made `review` host-aware; this
> captures the rest so it isn't lost. Precedent: superpowers
> `references/{codex,copilot,gemini}-tools.md`, ponytail `docs/agent-portability.md`.

## Why

PASIV's skills name Claude-Code-native mechanisms directly (the `Skill` tool, `Task` subagent dispatch, the native task manager, `AskUserQuestion`). To run end-to-end under Codex (or Copilot/Gemini), each needs a host equivalent or a documented fallback. The review engine adapters (phase 3) are the pattern; this generalizes it.

## Host detection (already used by `review`)

`$CLAUDECODE` set → **Claude Code**; `$CODEX_*` (e.g. `$CODEX_SANDBOX`) set → **Codex**; else fall back to whichever CLI is on `PATH`. Detect once per session.

## The mapping

| PASIV mechanism | Claude Code | Codex | Fallback / note |
|---|---|---|---|
| Sub-skill invocation | `Skill` tool | Codex skills / `@skill` / prompt-include | If no skill mechanism: inline the skill body. |
| Subagent dispatch (`execute` GREEN, `review` claude pass) | `Task` tool + `model` | `codex exec` subprocess, or Codex sub-task; `claude -p` for the claude engine | Context-isolation needs a real subprocess. Inline fallback works but loses the token/standard-context win. |
| **Native tasks** (TaskCreate/Update/List/Get, blockedBy) | native task manager | **none** | Biggest gap — see below. |
| User prompts | `AskUserQuestion` | plain-text question / Codex equivalent | Multi-select degrades to a numbered prompt. |
| Codex review engine | `mcp__my-codex-mcp__codex` | native | **Done** — handled by review's phase-3 adapters. |
| Model selection | `model:` frontmatter + dispatch `model` | Codex model flags | Tier→model map per host. |
| File/shell (Read/Write/Edit/Bash/Glob/Grep) | native | native (same/similar) | ~1:1, portable. |
| Hooks (PreCompact, …) | CC hook events | Codex hook events differ | Ship per-host hook configs. (ponytail omits Gemini `hooks.json` because event names differ.) |
| 1M context flag | `CLAUDE_CODE_DISABLE_1M_CONTEXT` | n/a | CC-specific; Codex has its own context model. |

## Hardest part: native tasks

The execution layer (TaskCreate/Update/List + `blockedBy`) is Claude-Code-only. Under Codex, two options:

1. **Backend-as-execution-view** — use the configured backend (beans/local) as BOTH the durable store and the live task view. beans already has `--ready` / dependency semantics, so it covers `blockedBy`. *Recommended.*
2. **`<plan>.tasks.json`** — the coordinator reads/writes a plan-adjacent JSON (superpowers' pattern). More moving parts.

Either way, `plan`/`execute`/`kick` would call a task shim instead of naming the native tools.

## Recommended architecture

A thin **host-shim** each skill calls instead of naming CC tools directly — detect host once, then route:

```
dispatch(role, model, prompt)   # Task subagent | codex exec | claude -p
task_create / update / list     # native tasks | backend | .tasks.json
ask(question, options)          # AskUserQuestion | numbered prompt
invoke_skill(name, args)        # Skill tool | @skill | inline
```

Mirrors review's engine adapters, generalized to the four CC-native mechanisms.

## Effort / sequencing

- **Done:** host detection, review adapters, file/shell (already portable).
- **Medium:** dispatch shim, ask shim, per-host hook configs.
- **Large:** native-task → backend-as-execution-view (touches `plan`/`execute`/`kick`).

Suggested order: dispatch shim → task shim → ask shim → hooks → per-host distribution.

## Distribution

PASIV ships today as a Claude Code plugin (`.claude-plugin/`). Full Codex support also needs a `.codex-plugin/` manifest; PASIV already has `AGENTS.md` for the instruction layer. See ponytail/superpowers multi-host manifests for the shape.

## Out of scope for the first pass

Copilot/Gemini hosts — design the shim so they slot in, but Codex is the only second host worth wiring first (it's where the Claude-as-reviewer inversion already pays off via phase 3).
