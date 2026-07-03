# Design System Integration

PASIV loads the project's design system whenever a `/kick` task is labeled `area:frontend` or `area:mobile`, so implementation references established tokens and patterns instead of inventing new ones.

## Resolution order

1. `.pasiv.yml`:

   ```yaml
   design:
     system: docs/design-system.md
   ```

2. No config → first existing of: `docs/design-system.md`, `design-system.md`, `DESIGN.md`, `.interface-design/system.md`.
3. Nothing found → `/kick` notes "No design system found" and continues; `/pasiv init` can set one up.

## What the doc should contain

- **Tokens** — colors, spacing scale, typography, radii/shadows
- **Patterns** — buttons, forms, cards, lists: the documented way to build each

Any format works; it's read as context, not parsed.

## During UI work

1. State design direction before component decisions
2. Use established tokens (e.g., "spacing-4 (16px)", "radius-md")
3. Follow documented patterns for similar components
4. After implementation, offer to save new reusable patterns back to the doc

## Setup

`/pasiv init` (frontend = yes) discovers an existing doc and records its path, or offers to create a starter `docs/design-system.md` with token values pulled from the codebase (Tailwind theme, CSS variables, theme files) — or lets you point at any path.

## Optional provider: interface-design

The [interface-design](https://github.com/Dammyjay93/interface-design) plugin is supported but not required. If installed, `/pasiv init` offers `/interface-design:init` as the creation method, and `/interface-design:audit src/components` can verify code against the system. Its `.interface-design/system.md` is one of the discovered locations.
