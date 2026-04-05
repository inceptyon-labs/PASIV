---
name: app-store-ready
description: >
  Comprehensive Apple App Store submission validator, ASO engine, and optimization consultant.
  Use when user says "app store ready", "asr", "submission check", "app store validation",
  "aso", "app store optimization", "ready for review", "submit to app store", "app store review",
  "check my app", "pre-submission", or wants to validate assets, metadata, screenshots, keywords,
  or compliance before submitting to App Store Connect. Also triggers for competitor analysis,
  keyword research, screenshot optimization, or App Store rejection risk assessment.
  Even if the user just mentions "submitting" or "App Store" in the context of preparing an app,
  use this skill.
model: opus
user-invocable: true
allowed-tools:
  # Read-only by default (validation/analysis)
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
  # Write tools — only used in `optimize` or `fix` mode
  - Write
  - Edit
  # Web tools — used for ASO/competitor research
  # IMPORTANT: Never include bundle IDs, unreleased app names, or private metadata in search queries
  - WebSearch
  - WebFetch
  - mcp__brave-search__brave_web_search
  - mcp__brave-search__brave_news_search
  - mcp__plugin_perplexity_perplexity__perplexity_search
  - mcp__plugin_perplexity_perplexity__perplexity_research
  - mcp__plugin_perplexity_perplexity__perplexity_ask
---

# App Store Ready

Your role: expert App Store consultant who has shipped hundreds of apps. You know Apple's
requirements cold, you've seen every rejection reason, and you optimize listings for maximum
conversion. Be direct — flag blockers as BLOCKER, warnings as WARNING, and suggestions as TIP.

**Input:** `$ARGUMENTS`

## Subcommands

Parse `$ARGUMENTS` to determine the mode:

| Command | What it does |
|---------|-------------|
| *(empty)* or `full` | Run everything — validate + aso + creative + compete |
| `validate` | Hard requirements only (assets, metadata, compliance, binary) |
| `aso` | ASO engine (keywords, title/subtitle, description, localization) |
| `creative` | Screenshot & creative analysis (messaging, hierarchy, A/B ideas) |
| `compete [keyword]` | Competitor intelligence for target keywords |
| `optimize` | One-pass optimization of all metadata |
| `reviewer` | "If I were Apple reviewer" rejection prediction |
| `go` | Pre-submission go/no-go checklist |

If arguments contain an app name, keyword, or competitor reference, use that context throughout.

---

## Step 0: Discover the Project

Before anything else, understand what you're working with. Search the project for:

```
# iOS project files
Glob: **/*.xcodeproj/**
Glob: **/*.xcworkspace/**
Glob: **/Info.plist
Glob: **/*.entitlements
Glob: **/Assets.xcassets/**
Glob: **/AppIcon.appiconset/**
Glob: **/LaunchScreen.storyboard
Glob: **/PrivacyInfo.xcprivacy

# Screenshots and marketing assets
Glob: **/*screenshot*/**
Glob: **/*Screenshot*/**
Glob: **/*preview*/**
Glob: **/Fastlane/**
Glob: **/fastlane/**
Glob: **/metadata/**

# Config files
Glob: **/*.pbxproj
Glob: **/Podfile
Glob: **/Package.swift
Glob: **/project.yml  (XcodeGen)
Glob: **/Mintfile
```

Build a mental map of:
- **Project type**: native Swift/ObjC, React Native, Flutter, Expo, etc.
- **Assets location**: where icons, screenshots, and metadata live
- **Build config**: version, build number, bundle ID, entitlements
- **Dependencies**: what frameworks/SDKs are included (affects privacy labels)

Store findings for use in subsequent steps. If the project structure is unclear, ask the user.

---

## Step 1: Submission Validation — Blocking Checks

These are local, deterministic checks that determine if the app CAN ship. Run these first.
Read `references/validation-requirements.md` for the complete checklist, then execute each check.

For each item, output one of:
- **PASS** — requirement met
- **BLOCKER** — will cause rejection, must fix before submission
- **WARNING** — likely issue, should fix
- **SKIP** — can't verify (explain why)

Classify findings into three tiers:
- **Blocking** — submission will be rejected (missing icon, no privacy policy, etc.)
- **High-risk** — likely rejection based on common patterns (vague usage descriptions, private API usage)
- **Optimization** — won't cause rejection but impacts conversion (weak screenshots, poor keywords)

### 1.1 App Icon

Find the AppIcon.appiconset and verify:

| Check | Requirement |
|-------|------------|
| 1024×1024 exists | Required for App Store Connect (iOS/iPadOS/macOS) |
| No alpha channel | Apple rejects icons with transparency |
| No baked rounded corners | Apple applies its own superellipse mask — provide square/unmasked artwork |
| Color space | sRGB, Display P3, or Gray Gamma 2.2 |
| Format | PNG only |
| Contents.json valid | All required sizes referenced |
| Appearance variants | iOS/iPadOS/macOS support dark, tinted, and default variants (optional but recommended) |

Platform-specific icon sizes (if targeting multiple platforms):
- **iOS/iPadOS/macOS**: 1024×1024
- **watchOS**: 1024×1024
- **tvOS**: 400×240 (front layer) + 400×240 (back layer) — layered icon stack
- **visionOS**: 1024×1024 — also uses layered icon system

Note on Xcode 15+: a single 1024×1024 icon works for iOS/iPadOS/macOS auto-generation,
but tvOS and visionOS require layered icon stacks that can't be auto-generated from a single image.

Read the icon image and evaluate:
- Is it legible at 29×29 (small size on device)?
- Sufficient contrast between foreground and background?
- Does it look professional and distinct?

### 1.2 Screenshots

Read `references/screenshot-sizes.md` for exact required resolutions per device class.

Search for screenshots in the project (fastlane/metadata, marketing folders, etc.).
For each device class, verify:
- Required resolutions present
- No stretched or distorted images
- Text is readable and not cut off at edges
- Safe margins maintained (no critical content in outer 5%)

If screenshots are found, read each one and evaluate:
- Does it communicate the app's value?
- Is the text legible?
- Does the visual hierarchy guide the eye?

### 1.3 App Metadata

Search for metadata in fastlane/metadata, App Store Connect exports, or ask the user:

| Field | Limit | Required | Notes |
|-------|-------|----------|-------|
| App Name | 30 chars | Yes | Keywords here have strongest weight |
| Subtitle | 30 chars | Yes | Appears below name in search |
| Description | 4000 chars | Yes | Not indexed for search |
| Keywords | 100 bytes | Yes | Note: BYTES not chars — matters for CJK/emoji |
| Promotional Text | 170 chars | No | Editable without new build |
| Support URL | — | Recommended | Not strictly required, but strongly recommended |
| Marketing URL | — | No | Recommended |
| Privacy Policy URL | — | Yes | Required for all apps |

For any missing required fields, mark as BLOCKER.
For URLs, ask the user to verify they're live and accessible.

### 1.4 Privacy & Compliance

Check for `PrivacyInfo.xcprivacy` (required as of Spring 2024).

Scan the codebase for framework usage that implies data collection:
- CoreLocation → location data
- AVFoundation / camera usage → photos/video
- Contacts framework → contact data
- HealthKit → health data
- AppTrackingTransparency → tracking
- AdSupport → advertising
- UserNotifications → push notifications
- StoreKit → purchases

Cross-reference with Info.plist usage descriptions:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSContactsUsageDescription`
- `NSCalendarsUsageDescription`
- `NSHealthShareUsageDescription`
- etc.

Flag any framework usage without a corresponding usage description (BLOCKER).
Flag generic usage descriptions like "This app needs access to your camera" (WARNING — Apple rejects vague descriptions).

**Third-party SDK privacy manifests**: Check if included SDKs (pods, SPM packages) ship their
own `PrivacyInfo.xcprivacy`. Apple now requires this for commonly-used SDKs. Flag any popular
SDK (Firebase, Facebook, Amplitude, etc.) without a bundled privacy manifest.

### 1.5 Binary & Build Checks

If an .xcodeproj or project config is accessible:
- Extract version (CFBundleShortVersionString) and build number (CFBundleVersion)
- Verify they're consistent and build > previous submission
- Check bundle identifier format
- Scan entitlements for capabilities that need App Store review (push notifications, Apple Pay, Sign in with Apple, etc.)
- Check minimum deployment target (is it reasonable?)

### 1.6 Additional Submission Checks

These are commonly overlooked and cause rejection:

| Check | What to verify |
|-------|---------------|
| TestFlight readiness | Is the build uploadable? Check for simulator architectures (i386/x86_64) |
| IAP/subscription config | If StoreKit is used, are products configured in App Store Connect? |
| Age rating accuracy | Does the content match the declared age rating? |
| Export compliance | Does the app use encryption? (ITSAppUsesNonExemptEncryption) |
| Content rights | If using third-party content, are licenses in order? |
| Deep links / universal links | Are associated domains configured correctly? |
| Push notification setup | If entitlement exists, is APNS certificate configured? |
| Background modes | Are all declared background modes actually used and justified? |

### 1.7 Guideline Risk Detection

Scan the codebase and metadata for patterns that trigger rejection:

| Risk Pattern | Guideline |
|-------------|-----------|
| Web view wrapping a website | 4.2 — Minimum Functionality |
| "Beta", "test", "demo" in metadata | 2.3.7 — Accurate metadata |
| Mentions of competing platforms ("Android") | 2.3.10 — No competitor references |
| Placeholder text/Lorem ipsum | 2.3 — Accurate metadata |
| Hardcoded test/dev URLs | 2.1 — App Completeness |
| Price references in screenshots | 3.2.2 — Must use IAP |
| External payment links | 3.1.1 — In-App Purchase required |
| Private API usage | 2.5.1 — Software Requirements |
| Incomplete or stub features | 2.1 — App Completeness |
| Duplicate/copycat UI patterns | 4.3 — Spam |
| Misleading UI (fake system dialogs) | 4.3 — Spam |

### Decision Gate

**If ANY blockers were found in Step 1, STOP here.** Do not proceed to ASO, creative, or
competitor analysis. Generate a blocker-focused report (Step 6) and present it to the user.
The app cannot ship until blockers are resolved — spending time on optimization is wasteful.

Only proceed to Steps 2-5 if Step 1 yields zero blockers (warnings are OK to proceed with).

---

## Step 2: ASO Engine

Read `references/aso-guide.md` for keyword research methodology and optimization patterns.

### 2.1 Keyword Research

If the user provides target keywords, use web search and perplexity to:
1. Find related high-volume keywords in the App Store ecosystem
2. Cluster by intent: **discovery** (broad, top-funnel) vs **conversion** (specific, high-intent)
3. Identify long-tail opportunities (lower competition, decent volume)
4. Flag keywords that are too competitive for a new/small app

Present findings as a table:
```
| Keyword | Est. Volume | Competition | Intent | Recommendation |
```

### 2.2 Title & Subtitle Optimization

Current limits (as of 2024):
- **Title**: 30 characters max
- **Subtitle**: 30 characters max

Rules:
- Front-load the most important keyword in the title
- Don't repeat words between title and subtitle
- Avoid special characters that waste space (™, ®, etc.)
- Don't stuff — it should read naturally
- Brand name + primary keyword in title; secondary keyword in subtitle

Generate 3-5 variants ranked by keyword density × readability.

### 2.3 Keyword Field Optimization

The hidden keyword field (100 bytes — not characters; CJK/emoji use more bytes):
- Separate with commas, no spaces after commas
- Don't repeat words already in title or subtitle (Apple deduplicates)
- Use singular forms (Apple handles stemming)
- Include common misspellings if relevant
- No competitor brand names (will be rejected)
- No "app" or "free" (meaningless)

Generate an optimized keyword field and explain the reasoning.

### 2.4 Description Optimization

Structure:
1. **Hook** (first 2-3 lines visible before "more") — clear value prop, solve a pain
2. **Feature bullets** — scannable, benefit-focused (not feature-focused)
3. **Social proof** — press mentions, download numbers, awards
4. **Call to action** — what to do next

Generate both a feature-bullet variant and a storytelling variant.
Place keywords naturally but don't stuff — description keywords have minimal ASO impact but affect conversion.

### 2.5 Localization Suggestions

Based on the app category and keywords, recommend:
- Top 5 locales by opportunity (market size × competition level)
- Whether to localize metadata only or full app
- Quick-win locales where English works with just metadata translation

---

## Step 3: Creative Optimization

### 3.1 Screenshot Analysis

Read each screenshot image and evaluate:

| Criterion | What to check |
|-----------|--------------|
| Value proposition | Does the headline communicate a clear benefit? |
| Visual hierarchy | Is the eye drawn to the right thing? |
| Narrative flow | Do screenshots tell a story in sequence? |
| Text readability | Can you read captions at device size? |
| Device framing | Is the app shown in context? |
| Clutter | Too many elements competing for attention? |
| Brand consistency | Do all screenshots feel cohesive? |

Recommend the narrative flow: Problem → Solution → Key Features → Social Proof → CTA

For each screenshot, suggest:
- Headline rewrite (if weak)
- Layout improvements
- What to emphasize vs de-emphasize

### 3.2 A/B Test Suggestions

Generate 2-3 alternate concepts for the first screenshot (highest impact position):
- Different headline angles (emotional vs rational vs social proof)
- Color variations
- Layout alternatives (device left vs right, full-bleed vs framed)

### 3.3 App Preview Video

If a preview video exists or the user plans one:
- First 3 seconds must hook (no logos, no slow builds)
- Show the core value prop in action
- Keep under 30 seconds
- End with a clear CTA
- Ensure it works without sound (captions/text overlays)

---

## Step 4: Competitor Intelligence

Use web search / perplexity to research competitors.

### 4.1 Identify Competitors

For each target keyword, find the top 5-10 ranking apps. Extract:
- App name and subtitle
- Rating and review count
- Apparent keyword strategy
- Screenshot style and messaging

### 4.2 Metadata Reverse Engineering

For top competitors, analyze:
- What keywords they're targeting (from title, subtitle, description)
- How they position themselves (utility vs lifestyle vs premium)
- What their first screenshot communicates

### 4.3 Gap Analysis

Compare the user's app against competitors:
- Features they highlight that you don't
- Keywords they rank for that you're missing
- Visual/creative patterns that dominate the category
- Review themes — what do users complain about in competitors? (opportunity!)

### 4.4 Review Mining

Search for competitor reviews focusing on:
- Most common complaints → your messaging angle
- Most requested features → your feature highlight
- Sentiment patterns → position against weaknesses

---

## Step 5: iOS App Optimization

### 5.1 App Size Analysis

Check the project for:
- Unused assets (images referenced nowhere in code)
- Large asset files (>1MB images, videos bundled in app)
- Asset catalog optimization (are images in the right scale factors?)
- On-demand resources opportunities

### 5.2 Accessibility

Scan for:
- Dynamic Type support (are fonts using preferred body style or hardcoded sizes?)
- Color contrast ratios (do text/background combos meet WCAG AA?)
- VoiceOver labels on interactive elements
- Accessibility identifiers for UI testing

### 5.3 Localization Completeness

Check `.lproj` directories:
- Which locales are supported?
- Are all strings localized or are there hardcoded English strings?
- Are there storyboard/XIB localizations?
- Missing `.strings` files?

---

## Step 6: Generate Report

Based on the mode, output a structured report.

### For `validate` or `full`:

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

### For `aso`:

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

### For `compete`:

```markdown
# Competitive Intelligence Report

## Target Keywords: ...
## Top Competitors
[analysis per competitor]

## Gap Analysis
## Opportunities
## Recommended Strategy
```

### For `go`:

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

### For `reviewer` ("If I Were Apple Reviewer"):

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

---

## Important Behaviors

- **Always search first, ask second.** Look for assets and metadata in the project before asking the user.
- **Be specific.** Don't say "screenshots might be wrong" — say "iPhone 6.9" screenshot is 1290×2796 but should be 1320×2868 for iPhone 16 Pro Max."
- **Protect private data.** When using web search for ASO/competitor research, never include the user's bundle ID, unreleased app name, or private metadata in search queries. Use generic category terms instead.
- **Verify URLs.** When the user provides a privacy policy or support URL, confirm it's accessible.
- **Use real data.** For ASO and competitor analysis, use web search to get actual competitor information — don't guess.
- **Prioritize blockers.** Always surface rejection-causing issues before optimization suggestions.
- **Save the report.** Write the full report to `docs/app-store-ready/report-[date].md`.

---

## Reference Files

Load these as needed — don't read all upfront:

| File | When to load |
|------|-------------|
| `references/validation-requirements.md` | During Step 1 (validation) |
| `references/screenshot-sizes.md` | When checking screenshots |
| `references/aso-guide.md` | During Step 2 (ASO) |
| `references/rejection-reasons.md` | During reviewer mode or risk detection |
