# ASO (App Store Optimization) Guide

## How App Store Search Works

Apple's search algorithm considers these factors (in rough order of weight):

1. **App Name** — highest keyword weight
2. **Subtitle** — strong keyword weight
3. **Keyword Field** — strong keyword weight (hidden, 100 bytes)
4. **In-App Purchases** — moderate weight (IAP titles are indexed)
5. **Developer Name** — some weight
6. **Description** — NOT indexed for search (but matters for conversion)
7. **Category** — affects browse rankings
8. **Ratings & Reviews** — affects ranking position
9. **Downloads & Velocity** — strongest ranking signal overall

## Keyword Research Methodology

### Step 1: Seed Keywords
Start with obvious terms the user would search:
- What does your app do? (verb-based: "track", "edit", "plan")
- What problem does it solve? (pain-based: "budget", "focus", "sleep")
- What category is it in? (category: "fitness", "recipe", "journal")

### Step 2: Expand
For each seed keyword, find:
- **Synonyms**: "workout" → "exercise", "training", "fitness"
- **Long-tail**: "workout" → "workout planner", "home workout", "gym tracker"
- **Adjacent**: "workout" → "calories", "steps", "health"
- **Misspellings**: common typos that people search for

### Step 3: Evaluate
For each keyword candidate, assess:
- **Volume**: How often is it searched? (use App Annie, Sensor Tower, or web search for estimates)
- **Competition**: How many quality apps target this term?
- **Relevance**: Does it genuinely describe your app?
- **Intent**: Is the searcher looking for an app like yours?

### Step 4: Cluster by Intent

| Intent Type | Example | Strategy |
|------------|---------|----------|
| Discovery | "best apps for..." | Broad awareness |
| Category | "fitness tracker" | Mid-funnel |
| Feature | "calorie counter" | Specific feature match |
| Brand | "MyFitnessPal" | Competitor targeting (careful!) |
| Problem | "lose weight" | Pain-point targeting |
| Conversion | "download workout app" | High intent |

### Step 5: Prioritize
Use a scoring matrix:

```
Score = (Relevance × 3) + (Volume × 2) + ((10 - Competition) × 1)
```

Each factor rated 1-10. Prioritize keywords scoring 40+.

---

## Title Optimization

### Best Practices
- **Format**: `Brand Name - Primary Keyword Phrase`
- **Or**: `Primary Keyword - Brand Name`
- **Max**: 30 characters

The choice depends on brand strength:
- **Known brand**: `Spotify - Music & Podcasts` (brand first)
- **Unknown brand**: `Sleep Sounds - White Noise` (keyword first)

### What to Avoid
- All caps (looks spammy)
- Special characters for decoration
- Keyword stuffing ("Sleep Sounds White Noise Relax Calm")
- Generic words ("App", "The", "Best")
- Competitor names (will be rejected)

---

## Subtitle Optimization

### Best Practices
- Complement the title — don't repeat words
- Include your second most important keyword phrase
- Should read naturally as a pair with the title
- **Max**: 30 characters

### Good Examples
- Title: "Headspace" → Subtitle: "Meditation & Sleep"
- Title: "Notion - Notes & Docs" → Subtitle: "Organize Your Work & Life"

### Bad Examples
- Title: "Sleep App" → Subtitle: "Sleep Sounds Sleep Aid" (repetitive)
- Title: "MyApp" → Subtitle: "The Best App Ever Made" (wasted keywords)

---

## Keyword Field Optimization

### Rules
- 100 bytes max (not characters — CJK characters use 3 bytes each in UTF-8, emoji use 4)
- Comma-separated, NO spaces after commas
- Singular form only (Apple handles plurals)
- Don't repeat words from title or subtitle
- Don't use "app" or "free"
- Don't use competitor brand names
- Consider misspellings if commonly searched
- Use word combinations: "home,workout" makes both "home workout" and individual terms searchable

### Optimization Technique
1. List ALL remaining keywords after title/subtitle allocation
2. Remove any words already in title or subtitle
3. Remove duplicates and plurals (keep singular)
4. Remove low-value words ("the", "and", "for", "best", "app")
5. Sort by priority (highest value first, in case you hit the limit)
6. Join with commas, no spaces: `keyword1,keyword2,keyword3`
7. Verify total is ≤100 bytes (use UTF-8 byte count, not character count)

### Combination Strategy
Apple combines words across fields. If your title has "workout" and your keywords have "home",
the search "home workout" will match. Plan your keyword distribution to maximize combinations.

---

## Description Optimization

The description does NOT affect search ranking but DOES affect conversion.

### Structure (4000 chars max)

```
[HOOK — First 2-3 lines visible before "more"]
Clear value proposition. What pain does this solve?
Why should someone download this RIGHT NOW?

[FEATURES — Scannable bullets]
● Feature 1 — Benefit explanation
● Feature 2 — Benefit explanation
● Feature 3 — Benefit explanation

[SOCIAL PROOF]
"Quote from press or user review" — Source
★★★★★ "User testimonial" — Username

Featured in [Publication]
[X]M+ downloads

[SUBSCRIPTION INFO — if applicable]
Pricing details, free trial info, cancellation policy

[CLOSING CTA]
Download now and [achieve the benefit].
```

### Writing Tips
- Lead with benefits, not features
- Use short paragraphs (2-3 lines max)
- Include natural keyword mentions (they don't help search but help conversion)
- Address objections ("No account required", "Works offline")
- Be specific ("Track 300+ exercises" not "Track many exercises")

---

## Localization Strategy

### High-Opportunity Locales (by App Store revenue)

| Rank | Locale | Notes |
|------|--------|-------|
| 1 | en-US | Default, highest volume |
| 2 | zh-Hans | China (separate store dynamics) |
| 3 | ja | Japan (high ARPU) |
| 4 | ko | South Korea |
| 5 | de | Germany |
| 6 | fr | France |
| 7 | en-GB | UK (often overlooked, easy win) |
| 8 | es-MX | Latin America |
| 9 | pt-BR | Brazil |
| 10 | it | Italy |

### Quick Wins
- **en-GB, en-AU, en-CA**: Just copy en-US metadata with British spelling adjustments
- **es-MX**: Covers most of Latin America
- **pt-BR**: Covers Brazil (large market)
- **Metadata-only localization**: Translate title, subtitle, keywords, description — no code changes needed

### Localization Tips
- Don't just translate — localize keywords for each market
- A "calorie counter" in English might rank better as "régime" in French
- Use native speakers or professional translators (machine translation hurts conversion)
- Localize screenshots — even just the text overlays makes a big difference
