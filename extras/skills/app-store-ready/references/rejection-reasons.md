# Common App Store Rejection Reasons

Based on Apple's App Store Review Guidelines and published rejection data.
Use this to proactively identify risk before submission.

## Table of Contents
1. [Top Rejection Reasons by Frequency](#top-rejection-reasons)
2. [Guideline Reference](#guideline-reference)
3. [Detection Patterns](#detection-patterns)
4. [Resolution Strategies](#resolution-strategies)

---

## Top Rejection Reasons

Apple's transparency reports group rejections by section (Performance, Design, Legal, Business,
Safety), not by individual guideline number. The list below orders common rejection *patterns*
by how frequently they appear in developer reports and forums — not an official Apple ranking:

### 1. Guideline 2.1 — App Completeness (most common)
**What**: App has bugs, crashes, placeholder content, or incomplete features.
**Signs**:
- Crashes on launch or during core flow
- "Coming Soon" labels in the UI
- Lorem ipsum or placeholder text
- Broken links or 404 pages
- Debug/test code visible to users
- Features that require a server that's not running

### 2. Guideline 4.0 — Design (Performance)
**What**: App doesn't meet quality or performance standards.
**Signs**:
- App is essentially a repackaged website (WebView wrapper)
- Very slow load times
- Non-native UI that feels clunky
- Tiny text or touch targets
- No iPad layout (if universal app)

### 3. Guideline 2.3 — Accurate Metadata
**What**: Metadata doesn't match app, or contains prohibited content.
**Signs**:
- Screenshots show features that don't exist
- Description promises functionality the app doesn't deliver
- "Beta", "test", "demo", "trial" in metadata
- Price references (Apple manages pricing)
- Competitor names mentioned
- Placeholder text in metadata fields
- Category doesn't match primary function

### 4. Guideline 5.1.1 — Data Collection and Storage (Privacy)
**What**: App collects data without proper disclosure or consent.
**Signs**:
- Missing privacy policy
- Privacy nutrition labels don't match actual data collection
- Accessing user data before showing permission prompt
- Sharing data with third parties without disclosure
- Missing NSUsageDescription strings

### 4b. Guideline 5.1.1(v) — Account Deletion Required
**What**: App supports account creation but does not offer account deletion.
**Signs**:
- Sign-in / sign-up flow exists but no "Delete Account" option in settings
- Account deletion only available via email, phone, or external website (without direct link)
- "Deactivate" or "disable" offered instead of permanent deletion
- Deletion option exists but doesn't actually remove user data
- No confirmation step showing the user what data will be deleted
**Resolution**: Add in-app account deletion that permanently removes the account and all associated data. Include a confirmation dialog. Apple may ask for a screen recording of the full flow.

### 5. Guideline 3.1.1 — In-App Purchase
**What**: Digital goods sold outside Apple's IAP system.
**Signs**:
- Links to external payment pages
- References to payment methods other than IAP
- "Subscribe on our website" messaging
- Cryptocurrency purchase flows for digital goods

### 6. Guideline 2.5.1 — Software Requirements
**What**: App uses private APIs or unsupported frameworks.
**Signs**:
- Calling undocumented Apple APIs
- Using deprecated frameworks that have been removed
- Including private frameworks
- Dynamic library loading at runtime

### 7. Guideline 4.2 — Minimum Functionality
**What**: App doesn't provide enough value.
**Signs**:
- App is just a WebView loading a website
- Single-feature app that should be a widget
- App replicates built-in iOS functionality without adding value
- App is essentially a marketing brochure

### 8. Guideline 5.1.2 — Data Use and Sharing
**What**: App shares data inappropriately.
**Signs**:
- Sending data to third-party analytics without disclosure
- Sharing location data with ad networks
- No opt-out mechanism for data sharing
- Fingerprinting (collecting device characteristics for tracking)

### 9. Guideline 4.8 — Login Services
**What**: Apps whose primary account uses third-party/social login but offer no equivalent
login that limits data to name and email, allows a private email, and doesn't track for ads
without consent. Sign in with Apple satisfies this; it isn't the only option.
**Signs**:
- Google Sign-In, Facebook Login, etc. as the only sign-in choices
- The equivalent option collects more than name and email
- Sign in with Apple (if offered) doesn't work correctly

### 9b. Guideline 5.1.2(i) — Sharing data with third-party AI
**What**: Personal data or user content sent to a third-party AI service without clear
disclosure and explicit permission.
**Signs**:
- Calls to OpenAI, Anthropic, Gemini, or similar APIs with user text, photos, or voice
- No screen naming the AI provider and asking for consent before the first send
- Privacy policy and App Privacy labels don't mention the AI provider

### 9c. Guideline 2.5.19 — Hidden Features
**What**: Hidden, dormant, or undocumented functionality, including features switched on after
approval (bait-and-switch). Grounds for removal and account termination.
**Signs**:
- Remote config or server flags that unlock features App Review never saw
- Code obfuscation hiding functionality
- App behaves differently by region, date, or account in ways not described in review notes

### 10. Guideline 1.2 — User Generated Content
**What**: App allows user content (including AI-generated content) without moderation.
**Signs**:
- No content reporting mechanism
- No ability to block users
- No filtering, including for nonconsensual intimate imagery (AI-generated too)
- Random or anonymous chat, Chatroulette-style, or "hot-or-not" features
- No published contact information
- Creator-content apps without an age restriction based on verified or declared age (1.2.1(a))

### 11. Guideline 4.3 — Spam
**What**: App is a clone, duplicate, or uses misleading tactics.
**Signs**:
- Multiple similar apps from same developer (4.3(a))
- New entry in a saturated category (dating, flashlight, sound effects, wallpaper, simple timers,
  fortune telling) without a meaningfully different experience (4.3(b)); Apple may also remove
  existing ones that aren't updated or don't attract customers
- App closely copies another app's UI/functionality, or uses another developer's icon, brand,
  or product name in its icon or name (4.1)
- Fake system dialogs or misleading UI elements
- SEO manipulation in metadata
- App with minimal changes resubmitted under different name

---

## Guideline Reference

Current as of the October 16, 2026 revision.

### Section 1: Safety
- **1.1** Objectionable Content
- **1.2** User Generated Content — filtering (incl. AI-generated NCII), reporting, blocking, contact info
- **1.2.1** Creator Content — (a) age restriction by verified or declared age
- **1.3** Kids Category — no links out or purchases outside a parental gate, no third-party analytics/ads
- **1.4** Physical Harm — medical apps need disclaimers and validated accuracy claims
- **1.5** Developer Information — real contact info via app and Support URL
- **1.6** Data Security

### Section 2: Performance
- **2.1** App Completeness — final build, no placeholders, demo account + live backend, IAP reviewable
- **2.2** Beta Testing — demos, betas, and trials belong on TestFlight
- **2.3** Accurate Metadata — everything must match reality
  - **2.3.3** Screenshots — majority must show the app in use
  - **2.3.7** Name (30 chars), keywords, subtitle — no prices, trademarks, unverifiable claims
  - **2.3.8** Icons/screenshots/previews 4+ appropriate
  - **2.3.10** No other mobile platforms or alternative marketplaces
  - **2.3.12** What's New must describe significant changes
  - **2.3.14** Creative assets — brand/app related, no pricing, no unverifiable claims (new, Oct 2026)
- **2.4** Hardware Compatibility — must work on claimed devices
- **2.5** Software Requirements — public APIs only, run on the currently shipping OS, self-contained code
  - **2.5.19** No hidden, dormant, or undocumented features (new, Oct 2026)

### Section 3: Business
- **3.1** Payments — IAP for digital goods; US storefront allows external links/CTAs; other
  storefronts need a StoreKit External Purchase Link Entitlement
- **3.2** Other Business Issues — 3.2.2 unacceptable practices (forced ratings/reviews, loans
  over 36% APR, etc.)

### Section 4: Design
- **4.0** Design — quality bar, native feel
- **4.1** Copycats — (c) no other developer's icon, brand, or product name in your icon or name
- **4.2** Minimum Functionality — must add genuine value beyond a repackaged website
- **4.3** Spam — no duplicate apps or undifferentiated entries in saturated categories
- **4.5** Apple Sites and Services — 4.5.3 no spam via push, Game Center, or Live Activities
- **4.7** Mini apps, mini games, streaming games, chatbots, plug-ins, and game emulators
- **4.8** Login Services — equivalent privacy-preserving login alongside third-party login
- **4.10** Monetizing Built-In Capabilities

### Section 5: Legal
- **5.1** Privacy — 5.1.1 collection (incl. (v) account deletion, (ix) regulated fields incl.
  crypto exchanges); 5.1.2 sharing (incl. (i) third-party AI consent); 5.1.4 Kids
- **5.2** Intellectual Property — no IP infringement
- **5.3** Gaming/Gambling — licensing required
- **5.4** VPN Apps — strict requirements
- **5.6** Developer Code of Conduct — manipulation, fraud, review/chart manipulation

---

## Detection Patterns

### Code-Level Patterns to Scan For

```swift
// RISK: Private API usage
@objc func _privateMethod()   // underscore-prefixed ObjC methods
dlopen()                       // dynamic library loading
NSClassFromString("_UIPrivate") // accessing private classes

// RISK: External payment
"stripe.com"                   // payment processor URLs
"paypal.com"
"checkout"                     // in web views
"subscribe on our website"

// RISK: Incomplete app
"TODO"                         // unfinished work
"FIXME"                        // known bugs
"lorem ipsum"                  // placeholder text
"test"                         // test data left in
"debug"                        // debug code left in
"coming soon"                  // unfinished features

// RISK: Tracking without ATT
ASIdentifierManager            // accessing IDFA
advertisingIdentifier          // without ATT prompt

// RISK: Deprecated APIs
UIWebView                     // must use WKWebView
addressBook                   // must use Contacts framework

// RISK: Third-party AI without consent (5.1.2(i))
"api.openai.com"
"api.anthropic.com"
"generativelanguage.googleapis.com"
// → confirm an in-app disclosure + explicit consent before first send

// RISK: Hidden features (2.5.19)
RemoteConfig / feature flags gating whole features App Review can't see
```

### Metadata Patterns to Flag

```
# In app name/subtitle/description:
"best"           → requires substantiation
"#1"             → requires third-party verification
"free"           → Apple shows price separately
"beta", "demo"   → implies incomplete (2.2)
"android"        → other mobile platform (2.3.10)
"google play"    → alternative marketplace reference (2.3.10)
"samsung"        → other platform reference (2.3.10)
"$", "€", "£", "% off" → pricing in metadata or creative assets (2.3.7, 2.3.14)
"subscribe at"   → IAP bypass outside the US storefront (3.1.1(a))
"for kids"       → reserved for Kids Category (2.3.8)
```

---

## Resolution Strategies

### When You Get Rejected

1. **Read the rejection reason carefully** — Apple provides the specific guideline
2. **Don't argue** — fix the issue, don't debate the reviewer
3. **Use Resolution Center** — communicate professionally
4. **Appeal only if clearly wrong** — use the App Review Board
5. **Fix everything at once** — don't fix one thing and resubmit with other issues

### Pre-Submission Checklist
Before every submission:
- [ ] Test on real device (not just simulator)
- [ ] Test all in-app purchases
- [ ] Verify all URLs (privacy policy, support, marketing)
- [ ] Check all screenshots match current app version
- [ ] Review metadata for prohibited terms
- [ ] Verify privacy labels match actual behavior
- [ ] Test the equivalent login option (Sign in with Apple or similar) if third-party login exists
- [ ] Demo account + live backend in App Review Notes
- [ ] Age rating questionnaire answered with current questions
- [ ] AI data-sharing disclosure and consent (if applicable)
- [ ] Test account deletion flow end-to-end (if app supports account creation)
- [ ] Test on oldest supported iOS version
- [ ] Remove all debug/test code and logging
- [ ] Verify push notifications work
- [ ] Check background modes are justified
- [ ] Review entitlements against actual usage
