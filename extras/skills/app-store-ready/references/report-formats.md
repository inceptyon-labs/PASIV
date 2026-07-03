# Report Formats

Output skeletons per mode. Load only the section for the current mode.

## Submission Report

Modes: `validate`, `full`.

```markdown
# App Store Submission Report
## Generated: [date]

## Summary
- Blockers: X
- Warnings: Y
- Passes: Z
- Overall: GO / NO-GO

## Blockers (Must Fix)
1. [BLOCKER] ...

## Warnings (Should Fix)
1. [WARNING] ...

## Passes
1. [PASS] ...

## Recommendations
- Priority 1: ...
- Priority 2: ...
```

## ASO Report

Modes: `aso`, `optimize` (optimize appends the list of files edited).

```markdown
# ASO Optimization Report

## Current Metadata
- Title: ...
- Subtitle: ...
- Keywords: ...

## Keyword Research
[table]

## Optimized Metadata
### Option A (keyword-focused)
### Option B (brand-focused)
### Option C (balanced)

## Keyword Field
[optimized field with reasoning]

## Description
[optimized description]
```

## Competitive Intelligence

Mode: `compete`.

```markdown
# Competitive Intelligence Report

## Target Keywords: ...
## Top Competitors
[analysis per competitor]

## Gap Analysis
## Opportunities
## Recommended Strategy
```

## Go/No-Go Checklist

Mode: `go`.

```markdown
# Pre-Submission Go/No-Go Checklist

## Hard Requirements
- [ ] Icon: 1024×1024, no alpha ✅/❌
- [ ] Screenshots: all device classes ✅/❌
- [ ] Privacy policy URL: live ✅/❌
- [ ] Support URL: live ✅/❌
[... full checklist]

## Verdict: GO / NO-GO
## If NO-GO, fix these first:
1. ...
```

## Review Risk Assessment

Mode: `reviewer` ("If I Were Apple Reviewer").

```markdown
# Apple Review Risk Assessment

## Likely Outcome: APPROVE / REJECT / RISKY

## Potential Rejection Reasons
1. [Risk Level: HIGH/MED/LOW] ...
   - Guideline: X.X.X
   - Evidence: ...
   - Fix: ...

## What a Reviewer Will Check First
1. ...

## Recommended Changes Before Submission
1. ...
```
