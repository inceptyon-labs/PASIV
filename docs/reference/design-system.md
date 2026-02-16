# Design System Integration

PASIV integrates with [interface-design](https://github.com/Dammyjay93/interface-design) for consistent UI implementation.

## How It Works

- When `/kick` processes an issue with `area:frontend` or `area:mobile` label, it automatically loads `.interface-design/system.md`
- The design system defines tokens (spacing, colors, typography) and patterns (buttons, cards, forms)
- Implementation must reference established tokens and follow documented patterns

## Setup (per project)

```bash
# Initialize design system in your project
/interface-design:init
```

## During UI Work

1. State design direction before component decisions
2. Use established tokens (e.g., "spacing-4 (16px)", "radius-md")
3. Follow documented patterns for similar components
4. After implementation, offer to save new reusable patterns

## Verification

```bash
# Audit code against design system
/interface-design:audit src/components
```

If no `.interface-design/system.md` exists when working on frontend issues, PASIV will suggest running `/interface-design:init`.
