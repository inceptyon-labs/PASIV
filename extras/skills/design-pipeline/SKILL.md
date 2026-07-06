---
name: design-pipeline
description: >-
  Guided end-to-end design workflow that turns a PRD/spec into a finished,
  non-generic UI. Use for "run the design pipeline", "design from my PRD/spec",
  "start a new design", "help me pick a design system", or when the user points
  at a spec and wants the full brief → visual options → design system → build →
  refine → anti-slop-gate sequence. Orchestrates impeccable, Codex CLI image
  generation, and ui-ux-pro-max when installed, with inline fallbacks when not.
  Checkpoint-driven: pauses for the human on every taste decision.
user-invocable: true
---

# Design Pipeline (orchestrator)

You are running a **guided, checkpoint-driven** design workflow. Sequence the
phases in order, doing the mechanical work at each step but **stopping at every
taste decision and waiting for the human**. Never guess a subjective choice the
user should make. Speed is not the goal; the user staying in control of what
the design looks like is the goal.

## Hard rules (do not violate)

1. **See before you specify.** Generate visual options as *images* before
   writing any production code. The user reacts to concrete options; you do not
   decide the direction for them.
2. **Cheap before expensive.** Images → tokens → code → polish → gate. Never
   write app code until a direction is locked and a design system exists.
3. **One source of truth.** All work reads from `PRODUCT.md` (the brief) and
   `DESIGN.md` (the system) at the project root. Create them early via the
   impeccable flows; keep them authoritative.
4. **Anti-slop is a gate, not a hope.** Capture anti-references in Phase 0 and
   run the deterministic detector in Phase 5. Do not rely on "the model has taste."
5. **Stop at every 🛑 CHECKPOINT.** Present what you have, ask the one question,
   then wait for an explicit answer (use AskUserQuestion where it fits). Do not
   roll past a checkpoint on your own.

## Step 0 — Detect available tooling (first, one line to the user)

Run one glob/ls pass to see what's installed (plugin cache lives under
`~/.claude/plugins/cache/`):

| Capability | Preferred | Detect by | Fallback (inline, below) |
|---|---|---|---|
| Brief + design docs | `impeccable` skill (`init`, `document`) | `~/.claude/plugins/cache/impeccable/impeccable/*/skills/impeccable/SKILL.md` | write `PRODUCT.md`/`DESIGN.md` yourself, §Fallback formats |
| Still art direction | Taste Skill `imagegen-frontend-web` (web) / `imagegen-frontend-mobile` (mobile) | `~/.agents/skills/imagegen-frontend-{web,mobile}/SKILL.md` exists on disk (NOT in your skills list — read the file directly) | your own direction prompts |
| Still rendering | **Codex CLI native image gen** | `codex features list \| grep image_generation` shows `true` | HTML/CSS options sheet, §Fallback stills |
| Image→code build | Taste `image-to-code` via Codex | `~/.agents/skills/image-to-code/SKILL.md` exists | impeccable `craft` |
| Palette/type ideation | `ui-ux-pro-max` | its skills appear in your available-skills list | your own judgment + impeccable's design guidance |
| Build + refine | `impeccable` (`craft`, `polish`, `typeset`, `colorize`, `animate`, `layout`, `bolder`, `quieter`, `live`) | same as above | implement yourself, tokens-only |
| Anti-slop gate | impeccable `detect.mjs` | `.../skills/impeccable/scripts/detect.mjs` in the same plugin dir | §Fallback slop checklist |

If image generation fails mid-run, switch to the fallback instead of retrying
or stalling.

Tell the user in **one line** what you found and which phases fall back. Then begin.

## Phase 0 — Brief

Read the user's PRD/spec. Then produce `PRODUCT.md`:

- **impeccable installed:** invoke the impeccable skill with the `init`
  sub-command; give it the spec as context. It interviews (register, users,
  brand personality, **anti-references**) and writes `PRODUCT.md` in the format
  every later impeccable command reads. Don't duplicate its questions.
- **Fallback:** write `PRODUCT.md` per §Fallback formats. If the spec is thin,
  ask up to 3 targeted questions — no more.

Establish the **target platform** here too — web, mobile (iOS/Android/Flutter),
or both — from the spec or its tech stack; if genuinely unclear, it counts as
one of your 3 questions. Record it in `PRODUCT.md`; it routes Phases 1 and 3.

Anti-references are mandatory either way: name the specific slop to avoid
(e.g. "purple-gradient SaaS hero", "cream/beige editorial default",
"emoji-bullet feature grid", "generic shadcn dashboard").

🛑 **CHECKPOINT A:** show `PRODUCT.md`, get approval before generating anything.

## Phase 1 — See options (images, no code)

Generate **3–5 art-directed reference stills of the product's most important
screen**, across *distinct named directions*. Pick directions that fit the
brief — e.g. minimalist/editorial, soft/expensive, brutalist/Swiss, dense
cockpit, warm analog — plus your best judgment. If `ui-ux-pro-max` is
installed, pull palette + font-pairing ideas from it to seed each direction's
prompt; keep the directions genuinely far apart.

**Art direction:** Read the Taste Skill matching the platform from Phase 0 —
`~/.agents/skills/imagegen-frontend-web/SKILL.md` for web,
`~/.agents/skills/imagegen-frontend-mobile/SKILL.md` for mobile — and apply
its rules when writing each direction's prompt (web: composition variety,
hero-scale variety, no default left-text/right-image reflex; mobile: app-native
hierarchy, readable text, subtle premium phone-mockup framing, controlled
palette). "Both" platforms → direction stills on the primary surface first;
re-render the chosen direction on the other platform before Phase 2. For
direction exploration, one still of the key screen per direction is enough —
the full multi-screen/per-section treatment kicks in later if the user wants
a complete comp of the chosen direction.

**Rendering:** one still per direction, each as its own call (they can run in
parallel background Bash):
`codex exec --skip-git-repo-check "Use your image generation tool to create
one image and save it to ./<direction>.png — <prompt>. Do nothing else."`
Call the CLI directly — not through a codex MCP wrapper (text-only, times out
on large prompts). Prompt with: product name, the screen's real content from
the spec, the direction's palette/type/layout intent per the art-direction
rules, and the platform framing — web: "flat UI screenshot, no device frame,
no watermark, landscape"; mobile: "app screen in a subtle premium phone
mockup, content is the focus, no watermark, portrait".
- **Fallback:** build one throwaway static HTML **options sheet** — all
  directions as labeled panels in a single file (inline CSS, real spec content,
  no JS) — and send/screenshot it for review. One file, one look, easy
  side-by-side. Mark it disposable — reference stills, not code to keep.

🛑 **CHECKPOINT B:** present the stills labeled 1–N with a one-line rationale
each; ask the user to pick one or describe a hybrid. **Do not proceed until
they choose.** This is the most important stop in the pipeline.

## Phase 2 — System

From the chosen still, derive a complete design system: color scale (OKLCH),
type scale + font pairing, spacing, radii, shadows, component conventions.
Write it to `DESIGN.md` — via impeccable `document` conventions if installed
(it follows the DESIGN.md format spec), else §Fallback formats. Verify the
tokens actually match the picked image (pull the dominant colors from the
still and compare); flag any drift instead of hiding it.

🛑 **CHECKPOINT C:** show the system as a token sheet (swatches + type ramp,
a small HTML sheet is fine) and get approval before building.

## Phase 3 — Build

Implement the real UI to match the still + `DESIGN.md`, **one screen/section
at a time**, using only system tokens — via impeccable `craft` when installed
(it reads PRODUCT.md/DESIGN.md itself), else directly. Alternative when the
user prefers Codex to build: run Codex with the Taste `image-to-code` skill
against the chosen still (`codex exec` pointing at the still + DESIGN.md).
**Mobile targets:** impeccable and `image-to-code` are web-only — implement
directly in the project's stack, translating `DESIGN.md` tokens into the
native theme layer (Flutter `ThemeData`/theme extensions, SwiftUI
Color/Font assets) first, then screens against the still.
Pause after the first section so the user can confirm the translation looks
right, then continue.

## Phase 4 — Refine

Use impeccable's direction commands (`typeset`, `colorize`, `animate`,
`layout`, `polish`, `bolder`, `quieter`, and `live` for in-browser variants).
For any subjective element, offer 2–3 variants and let the user pick. Iterate
until they're happy. Without impeccable: apply the same moves yourself, one
axis per pass (type, then color, then motion), always as variants to choose from.

## Phase 5 — Gate

Run the deterministic anti-slop detector over the built files:

```
node ~/.claude/plugins/cache/impeccable/impeccable/*/skills/impeccable/scripts/detect.mjs --json <files-or-dir>
```

The detector is deterministic but **narrow** — it will miss tells like emoji
bullets, arbitrary z-index, or the purple-gradient palette itself. Always
*also* walk §Fallback slop checklist against the code and a screenshot; the
detector complements the checklist, it does not replace it. Report violations
plainly, fix them, re-run until clean.

🛑 **CHECKPOINT D:** present the clean report before declaring done. Offer to
wire the detector into a pre-merge check (impeccable has `/impeccable hooks on`
for exactly this).

## Existing project? (redesign mode)

If the user points at an existing codebase rather than a new spec, switch to
**audit-first**: run impeccable `audit`/`critique`, then `polish` — inherit the
current tokens/components, don't overwrite. Skip Phases 1–2 unless the brand is
changing, and jump to Phases 4–5.

## Fallback formats

**PRODUCT.md** (root): `# <Name>` · `## What it is` (2–3 sentences) ·
`## Platform` (web / mobile / both, and the stack) ·
`## Users & context` (who, where, ambient light, mood) · `## Register`
(`brand` — design IS the product, or `product` — design SERVES it) ·
`## Brand personality` (3–5 adjectives + references) · `## Anti-references`
(named slop to avoid) · `## Design principles` (3–5 bullets).

**DESIGN.md** (root): `## Color` (OKLCH tokens: bg, surface, ink, muted,
accent, semantic; light+dark if applicable) · `## Typography` (families,
type scale, weights, line-heights) · `## Spacing & radii` (scales) ·
`## Components` (conventions per component) · `## Motion` (durations, easing,
reduced-motion stance).

## Fallback slop checklist (always walked in Phase 5; sole gate when detect.mjs is unavailable)

Fail the gate on any of: purple/indigo→pink gradient as primary identity;
cream/beige/sand near-white body bg as "warmth"; two similar sans-serifs
paired; gradient text on headings; uniform card grids where cards aren't the
right affordance; identical entrance animation on every section; emoji as
bullets/icons; `z-index: 999+`; body text contrast < 4.5:1; letter-spacing
< -0.04em on display type; hero type > 6rem; no `prefers-reduced-motion`
handling when motion exists.

## Style of interaction

Keep checkpoint messages short — show the artifact, ask the one question, wait.
Don't narrate the framework back to the user. When you hand off to another
skill, say which skill is doing the work in one line so the user can follow.
