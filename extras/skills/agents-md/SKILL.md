---
name: agents-md
description: Scaffold or audit a project's AGENTS.md/CLAUDE.md following Jason's convention (single tool-agnostic AGENTS.md, one-line CLAUDE.md pointer, only non-derivable facts, every reference verified on disk). Use whenever the user starts a new project and needs agent instructions, says "set up agents.md", "init claude.md", "create a CLAUDE.md", "audit my agents file", "is my CLAUDE.md any good", or when a repo is found with no AGENTS.md, a bloated one, or divergent CLAUDE.md/AGENTS.md duplicates. Prefer this over the generic /init command in Jason's repos.
---

# agents-md — scaffold and audit project agent files

The convention below was distilled from an audit of 8 active repos (2026-07).
The failures it prevents were all real: a 33KB CLAUDE.md with two documents
concatenated and four dead paths (unwyned), instructions mandating commands
that don't exist (`bun run format`, `cargo tarpaulin` in tars), an entire
fictional game engine documented as the tech stack (Flame in foodymerge),
byte-identical boilerplate copy-pasted across three repos (mise/gargantua),
and a file where the useful rules were siloed in CLAUDE.md while Codex got
only boilerplate (casework).

## The convention

**Structure.** One tool-agnostic `AGENTS.md` holds everything. `CLAUDE.md` is
exactly one line: `@AGENTS.md`. Add a `# Claude-specific additions` section
below the import ONLY for content that genuinely applies to no other tool
(LSP usage, Claude Code plugin wiring). If you can't name why a line is
Claude-only, it goes in AGENTS.md. Never let the two files diverge into
parallel versions of the same topics — that's how tars ended up with a
contradiction between its own two files.

**Budget.** Target 2–5KB. The file is loaded into every session; every line
competes with the actual task for attention. mise/AGENTS.md (4.9KB, fully
verified, zero fluff) is the gold standard — read it if unsure what good
looks like: `/Users/Jason/Development/mise/AGENTS.md`.

**Include — only facts an agent cannot derive and will get wrong without:**
- Build/test commands *with their gotchas*, not bare commands. "No `swift
  test` — use xcodebuild with the MiseTests scheme" earns its place; a
  command an agent would find in package.json does not.
- Invariants that have bitten before or will: "never `@testable import` —
  duplicate-symbol crash", "route through `LicenseGate.shared`, don't
  `#if`-gate call sites", "chains.json is canon, code constants are fallback".
- Non-obvious workflows: migration is local-first, rules backflow to the
  upstream repo before editing bundled copies, regen requires `--force-jit`.
- Project vocabulary when it drives naming in code or UI copy.
- Infra specifics an agent can't discover (self-hosted service IPs, deploy
  targets) — but only what this project needs beyond the global config.

**Exclude — each of these was found rotting in a real repo:**
- File trees and directory layouts. Derivable with `ls`, and they rot fastest:
  foodymerge's tree was ~40% wrong, unwyned's pointed at three directories
  that no longer exist.
- Stack tables and version numbers. pubspec/package.json/Cargo.toml is the
  source of truth; tars's table documented 3 of its 4 crates.
- Anything the README already says (mission, overview, usage). pasiv's
  CLAUDE.md was ~80% condensed README. Agent files describe how to *work on*
  the project, not how to *use* it. README stays the source of truth for
  "what is this".
- Anything the global config already says: commit conventions, working
  style, stack preferences, generic engineering principles (SOLID/DRY/TDD
  sermons). It's all in `~/memex/AGENTS.md` already.
- Skill lists and harness behavior. The harness injects available skills
  every session; PASIV's skills encode their own protocol. The 1267-byte
  PASIV boilerplate block found copy-pasted in mise/gargantua/casework adds
  nothing — do not scaffold it into new projects.
- Aspirational architecture. Document what the code does today, not the
  plan. foodymerge's file described a Flame engine that was never built.

**The verification rule — the single highest-value habit.** Every command,
path, scheme, script, and symbol named in the file must be verified against
disk at write time. A stale instruction is worse than no instruction: an
agent will follow it confidently into a wall. This is why file trees and
version tables are banned — they're unverifiable promises about the future.

## Mode 1: Scaffold (new or missing)

1. Read the README if present, the manifest(s) (package.json, pubspec.yaml,
   Cargo.toml, project.yml, Makefile…), and skim the top-level layout.
2. Extract the non-derivable facts: run the test command to confirm it works
   if it's cheap; note gotchas from CI config, scripts/, and any existing
   docs. If the repo is young and has no gotchas yet, write a *short* file —
   5 lines of true content beat 50 lines of padding. The file grows when
   something bites.
3. Write `AGENTS.md` using the template below. Verify every reference before
   writing it.
4. Write `CLAUDE.md` containing exactly `@AGENTS.md`.
5. If there's no README, say so — the global convention expects one as the
   source of truth — and offer to stub it. Don't silently absorb README
   content into AGENTS.md.

### Template

```markdown
# <project> — agent notes

<One line: what this is, only if there is no README to say it.>

## Build & test
<Commands WITH gotchas. Omit anything that works exactly as the manifest
implies.>

## Invariants
<Rules that prevent real breakage. One line each, with the consequence:
"X — otherwise Y".>

## Workflows
<Only the non-obvious ones: migrations, codegen, release, sync.>
```

Omit any empty section. Do not add sections for identity, style, commits,
or stack — global config owns those.

## Mode 2: Audit (existing files)

Run the checks in this order, then apply the fixes in the same pass —
audit-only when the user explicitly asked for a report. For files over ~6KB,
present the findings as a section-by-section keep/trim/cut table with
evidence; that table is the audit's output format, produced after the checks
and before editing.

1. **Secrets** — flag any credential, connection string, or API key in the
   file. Replace with a placeholder plus a pointer to where the real value
   lives (`.dev.vars`, server-side `.env`, secret manager), and tell the
   user removal doesn't scrub git history — a committed secret needs
   rotating. This is not hypothetical: live database passwords were found
   committed in two of the first nine repos checked.
2. **Staleness** — extract every backtick-quoted path, command, script, and
   symbol; verify each exists (`ls`, `test -f`, manifest scripts, grep) AND
   says what the file claims. A wrong port, a list covering half of what's
   on disk, or two lines in the file contradicting each other are all
   staleness even though everything named exists. This is the highest-yield
   check: every audited repo with a file over 5KB had it.
3. **Structure** — is CLAUDE.md a one-line `@AGENTS.md` pointer? If the two
   files both have content, diff the topics; parallel coverage means
   divergence is already underway. Consolidate into AGENTS.md.
4. **Redundancy** — flag any line that restates the README, the global
   config, a manifest, or a directory listing. The test: "would an agent
   without this line do anything differently?" If no, cut it. Process
   rituals referencing a file that's empty or long-stale (a SESSION.md
   nobody writes) are dead process — cut them too.
5. **Inversion** — project-specific rules belong in the tool-agnostic
   AGENTS.md, not siloed in CLAUDE.md where only Claude sees them. Common
   false-positives for "Claude-only": MCP tool notes (MCP isn't Claude-only)
   and session/memory rituals (usually dead process — see check 4).

When applying fixes: preserve verified load-bearing content exactly — the
goal is removing rot, not rewriting voice. If keeping verified content
pushes past the size budget, verified content wins; the budget bends, facts
don't. Before finishing, re-verify every reference in the rewritten file
the same way Mode 1 requires.
