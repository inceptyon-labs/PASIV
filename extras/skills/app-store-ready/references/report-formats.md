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
- iPhone Duo: OPTIMIZED / RUNS BUT NOT OPTIMIZED / BROKEN LAYOUT RISK / N/A (no iPhone)
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
- [ ] Built with a current SDK (Xcode 26+ / iOS 26 SDK; iOS 27 SDK from April 2027) ✅/❌
- [ ] Deployment target iOS 13 or later ✅/❌
- [ ] Icon: 1024×1024 (or .icon), no alpha on default ✅/❌
- [ ] Screenshots: required sizes, majority show app in use ✅/❌
- [ ] Privacy policy URL: live ✅/❌
- [ ] Support URL: live ✅/❌
- [ ] PrivacyInfo.xcprivacy + listed-SDK manifests ✅/❌
- [ ] Age rating questionnaire current ✅/❌
- [ ] Demo account in review notes (if login) ✅/❌
- [ ] Account deletion (if account creation) ✅/❌
- [ ] iPhone Duo: iOS 27.1 SDK+, scene life cycle, no layout red flags, Duo screenshots ✅/❌
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
