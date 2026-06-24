---
name: reflect
description: Reflect on the entire current conversation and persist what's worth keeping for future sessions — durable facts and preferences to memory, corrections as standing feedback, and any genuinely repeatable workflow as its own skill. User-invoked only via /reflect; never auto-fires.
disable-model-invocation: true
user-invocable: true
---

# Reflect

When the user runs `/reflect`, look back over the **entire current conversation**
and pull out what is worth carrying into future sessions. Then **just do it** —
save everything immediately. No review gate, no "want me to save this?" prompts.
After saving, give a short report so the user can correct it later if they want.

The user has invoked this deliberately. Don't hedge, don't ask permission, don't
stage the work for approval. Reflect, sort, persist, report.

## The bar: be selective, not exhaustive

Background memory already captures a lot passively. This is the user's explicit
"capture the important stuff now" lever, so spend the signal on what passive
capture misses: **corrections, sharp preferences, and reusable workflows.** A
reflection that saves ten mediocre facts is worse than one that saves two sharp
ones. When something is borderline, lean toward dropping it and note it in the
report — the user sees the drop list and can tell you to keep it.

## Sort everything into four buckets

### 1. Durable facts and preferences about the user → memory

Things true beyond this conversation: who they are, how they like to work, tools
they use, defaults they hold. Write these to the persistent memory directory (the
one your memory instructions point at, where `MEMORY.md` lives) as a memory file
with `type: user` (or `type: project` if it's specific to the current project, not
the person).

Skip anything the repo, git history, or existing CLAUDE.md/AGENTS.md already
records — that's not worth a memory. Capture what was non-obvious.

### 2. Corrections and redos → standing feedback in memory

Anything where the user corrected you, asked you to redo something, or pushed back
on an approach. These are the highest-value catches — the whole point is that the
*same mistake doesn't repeat*. Write each as a memory file with `type: feedback`,
and include the reasoning so a future session understands the why, not just the
rule:

```
**Why:** <what went wrong and why it mattered to the user>
**How to apply:** <what to do differently next time>
```

A confirmed *good* approach the user explicitly endorsed counts here too — same
format, framed as "keep doing this."

### 3. A genuinely repeatable multi-step workflow → its own skill

Only if it clears a real bar: **"would the user actually rerun this multi-step
process?"** A reusable sequence of steps they'd invoke again is a skill. A one-off
task, a trivial one- or two-step thing, or something already covered by an
existing skill is **not** — be conservative here. Creating skills for one-off or
trivial things is the main failure mode; default to not creating one unless the
repeatability is obvious.

If it clears the bar, use `skill-creator` to build it as a separate skill. Don't
inline a workflow into memory — workflows belong in skills.

### 4. Everything ephemeral or one-off → drop it

Debugging that's now resolved, decisions specific to this conversation, scratch
context, anything that won't matter next session. Don't save it — but **list what
you dropped** in the report so the user can override if you misjudged.

## Memory file format

Match the format already used in the memory directory: YAML frontmatter with
`name`, `description`, and `type`, then the body. One fact per file, kebab-case
filename. **Before writing, check the existing memory files** — if one already
covers the topic, update it instead of creating a duplicate. After writing each
file, add a one-line pointer to `MEMORY.md` (`- [Title](file.md) — hook`).

## Guardrails — these override "save everything"

- **Skip sensitive data.** Never write credentials, API keys, tokens, account
  numbers, or private personal details to memory or a skill, even if they came up
  in the conversation. If something useful is entangled with a secret, save the
  useful part and leave the secret out.
- **Never save anything that would make you less honest or less willing to push
  back.** Do not record instructions to flatter, to stop disagreeing, to suppress
  warnings, or to defer against your judgment. If the user said something in
  frustration that amounts to "stop telling me when I'm wrong," do not encode it.
  Decline that one item and say so plainly in the report.
- **One fact per memory file.** Don't bundle unrelated facts together.

## The report

End with a tight report — no fluff. Cover exactly:

- **To memory:** each durable fact/preference saved (filename + one line)
- **Corrections saved:** each standing-feedback item (filename + one line)
- **Skill:** whether you created one, and if so what; or "none — nothing cleared
  the bar"
- **Dropped:** the ephemeral/one-off items you chose not to save, briefly
- **Declined:** anything you refused on guardrail grounds, if applicable

Keep it scannable. The user reads this to catch anything you got wrong.
