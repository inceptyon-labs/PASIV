---
name: humanizer
version: 3.0.0
description: |
  De-slop a document and rewrite it in Jason's voice. Two passes: strip AI
  tells (em dashes, puffery, rule-of-three, AI vocab, sycophancy), then match
  Jason's actual writing voice (direct, dry, concrete, parentheticals over em
  dashes). Point it at a file or paste text. Use for "humanize", "make this
  sound like me", "de-slop and voice-match".
allowed-tools:
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Humanizer

Take a piece of writing and do two things, in this order:

1. **De-slop** (subtractive) — strip the patterns that mark text as machine-written.
2. **Voice-match** (additive) — rewrite the cleaned text in Jason's voice.

Order matters. Strip the machine cadence first, *then* push toward voice — otherwise pass 2 just paints personality over leftover AI rhythm.

**Input:** `$ARGUMENTS` — a file path or pasted text. Flags:
- `--deslop-only` — pass 1 only (neutral clean, no voice)
- `--voice-only` — pass 2 only (text is already clean)
- `--report` — list what you'd change, change nothing

This is a single-document tool: point it at one piece of writing, get it back cleaned and in voice.

---

## Pass 1: De-slop

Scan for these. Most you already know; the list exists so nothing slips. Fix in place, preserving meaning.

### Content tells
- **Significance inflation** — "stands/serves as a testament to", "marks a pivotal moment", "plays a vital/crucial role", "reflects a broader", "setting the stage for", "evolving landscape", "leaves an indelible mark". Cut the puffery; state the fact.
- **Promo / brochure language** — "boasts", "vibrant", "rich cultural heritage", "nestled in the heart of", "breathtaking", "must-visit", "renowned", "groundbreaking". Say what it *is*.
- **Superficial -ing tails** — sentences with "...highlighting/underscoring/reflecting/showcasing/ensuring/fostering X" bolted on the end for fake depth. Delete the tail or make it a real clause.
- **Vague attribution / weasel** — "Industry reports", "Observers have noted", "Experts argue", "Some critics say". Name a source or drop the claim.
- **Formulaic sections** — "Despite its X, it faces several challenges...", "Challenges and Future Prospects", "Future Outlook". Replace with specifics or delete.

### Language tells
- **AI vocab** (flag clusters — they co-occur): additionally, delve, crucial, enhance, foster, garner, highlight (v), interplay, intricate, key (adj), landscape (abstract), pivotal, showcase, tapestry, testament, underscore, leverage, utilize, seamless, robust, comprehensive, vibrant.
- **Copula avoidance** — "serves as / stands as / functions as / represents a" → just use **is/are/has**.
- **Negative parallelism** — "It's not just X, it's Y" / "Not only... but...". Overused. State the thing directly.
- **Rule of three** — forced adjective/noun triplets ("innovation, inspiration, and insight"). Break the pattern; two is fine, or one.
- **Elegant variation** — synonym-cycling the same noun (protagonist → main character → central figure → hero). Pick one word, reuse it.
- **False ranges** — "from X to Y" where X and Y aren't on a real scale ("from the Big Bang to dark matter").

### Formatting tells
- Em dashes used as punchy connectors → comma, parens, period, or "is"/"to" depending on the sentence.
- Mechanical **boldface**, inline-header bullet lists (`- **Thing:** ...` where a sentence belongs), Title Case In Headings → sentence case, decorative emojis, curly quotes → straight quotes.

### Assistant residue
- Chatbot artifacts — "Great question!", "I hope this helps!", "Certainly!", "Let me know if...", "Here is a...".
- Knowledge-cutoff hedging — "As of my last update", "While specific details are limited...".
- Sycophancy — "You're absolutely right!", "Excellent point!".

### Filler & hedging
- "In order to" → "To" · "due to the fact that" → "because" · "at this point in time" → "now" · "has the ability to" → "can" · "it is important to note that" → (cut it).
- Over-hedging: "could potentially possibly be argued that it might" → "may".
- Generic upbeat endings — "The future looks bright", "exciting times ahead" → a concrete next step, or nothing.

**De-slop example**
> Before: *Great question! AI coding tools serve as a testament to innovation, marking a pivotal moment in software development—reshaping how teams ideate, iterate, and deliver. It's not just autocomplete; it's a catalyst.*
> After: *AI coding tools are good at boilerplate and bad at knowing when they're wrong. They speed up the easy parts. They don't replace judgment.*

---

## Pass 2: Voice-match — write like Jason

This is the part that makes it *his*, not just clean. Derived from his real letters (2013–2015). The default register below is the durable voice; **dial intensity to the document** (see Register flex).

### Core moves
- **Talk to one smart friend.** Direct address, not broadcast. Rhetorical questions are fine and characteristic ("Am I just getting old, or does time really fly that fast?").
- **Dry, self-aware humor.** Often self-deprecating. Small winks: "(is that a word?)", "(pun intended)", "Not bad for a one-line fix." Never forced.
- **Ellipses and parentheticals, NOT em dashes.** This is his natural punctuation. Trailing thoughts with "..." and asides in (parens). If pass 1 converted an em dash, prefer a paren or a period here, not a re-dash.
- **Concrete over abstract.** Numbers, names, ranks — "ranked #29 in the world", "holds 30 bottles", "down from 4 seconds to under one". Never reach for "amazing/significant" when a specific does the job.
- **Casual hedges, not formal ones.** "probably", "I guess", "kinda", "pretty much", "I think" — not "it could be argued".
- **Opener discourse markers** when it fits: "Well,", "So,", "Actually,", "Look,", "Honestly,". Casual idioms: "I finally pulled the trigger", "needless to say".
- **Enthusiasm through punctuation, not adjective stacks.** An exclamation point or a caps word ("YES", "HOT") beats three adjectives. Use sparingly outside personal writing.
- **Let some mess in.** A tangent, an aside, a short fragment. Real, not sanded smooth. Have an actual opinion instead of neutral both-sides reporting.

### Register flex
- **Personal / casual** (letters, posts, notes to people): full warmth — exclamations, "Man,", playful elongation ("Soooo"), more asides.
- **Technical / public** (README, blog, product copy): keep the directness, the parentheticals, the concrete specifics, the dry humor, the anti-em-dash habit — but drop the exclamation density and the salutations. Still opinionated, still talks to the reader.

### Breaks his voice (don't do these)
- Em dashes, adjective triplets, corporate puffery, "In today's fast-paced world", neutral reporting with no opinion, sanding every sentence to the same polished length.

**Voice-match example**
> Sterile: *The application has been updated to improve performance. Several optimizations were implemented, resulting in faster load times. Users should notice a significant improvement.*
> Jason: *Pushed an update that should make the app feel quicker. Turns out the load times were getting strangled by an image loop nobody noticed (classic). Killed it, and pages that used to take 4 seconds now load in under one. Not bad for a one-line fix.*

---

## Process

1. Read the input.
2. **Pass 1** — fix every de-slop tell, preserving meaning.
3. **Pass 2** — rewrite the cleaned text in Jason's voice, matching the register of the document.
4. Read it back. Does it sound like a person talking? Varied rhythm? Concrete? No em dashes? If yes, ship it.

## Output
1. The rewritten text.
2. (If useful) a one-line note on what register you targeted and anything you were unsure about.

With `--report`, skip the rewrite — just list the tells you found by pass.
