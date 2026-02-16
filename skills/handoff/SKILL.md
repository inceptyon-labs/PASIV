---
name: handoff
description: Write structured session handoff. Use when ending a session, before compaction, or when switching work types.
model: sonnet
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
user-invocable: true
---

# Write Session Handoff

Write a structured handoff file to preserve context for the next session.

## Steps

1. **Determine the topic**: Use the current issue title, feature name, or ask the user if unclear.

2. **Determine the target project**: The handoff file goes in the **target project** (the project being worked on), not in the PASIV plugin directory.

3. **Create directory if needed**:
```bash
mkdir -p docs/handoffs/archive
```

4. **Gather context** by reviewing:
   - Recent git log and diff
   - Open issue details (if working on one)
   - Files modified in this session
   - Decisions made during conversation

5. **Write the handoff file** to `docs/handoffs/handoff-YYYY-MM-DD-{topic-slug}.md` using the template below.

6. **Report**: Display the file path and a brief summary of what was captured.

## Template

```markdown
# Session Handoff: {topic}
Date: {YYYY-MM-DD HH:MM}
Issue: #{number} - {title} (if applicable)

## What Was Done
- {Bullet list of completed work}

## Exact Numbers & Metrics
- {Copy exactly as discovered — test counts, line counts, performance numbers}

## Decisions Made
| Decision | Why | Alternatives Considered |
|----------|-----|------------------------|
| {what}   | {rationale} | {what was rejected and why} |

## Conditional Logic Established
- IF {condition} THEN {behavior}
- IF {condition} BUT {exception} THEN {alternate}

## Files Changed
| File | Purpose |
|------|---------|
| {path} | {what and why} |

## Open Questions
- UNCLEAR: {thing that needs clarification}
- ASSUMED: {assumption made, needs validation}
- MISSING: {information not yet available}

## What NOT to Re-Read
- {Files already processed and summarized above}

## Next Steps (ordered)
1. {First thing to do next session}
2. {Second thing}

## Files to Load Next Session
- {Explicit list of files the next session should read}
```

## Notes

- Omit sections that have no content (e.g., skip "Conditional Logic Established" if none applies).
- Be specific with file paths — relative to project root.
- "Exact Numbers & Metrics" should be copy-pasted, not paraphrased.
- "What NOT to Re-Read" saves the next session from re-processing large files already summarized.
