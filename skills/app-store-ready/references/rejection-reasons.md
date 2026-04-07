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

### 9. Guideline 4.8 — Sign in with Apple
**What**: Apps with third-party login that don't offer Sign in with Apple.
**Signs**:
- Google Sign-In, Facebook Login, etc. without Apple option
- Sign in with Apple button is less prominent than others
- Sign in with Apple doesn't work correctly

### 10. Guideline 1.2 — User Generated Content
**What**: App allows user content without moderation.
**Signs**:
- No content reporting mechanism
- No ability to block users
- No content moderation system
- No terms of service / acceptable use policy

### 11. Guideline 4.3 — Spam
**What**: App is a clone, duplicate, or uses misleading tactics.
**Signs**:
- Multiple similar apps from same developer
- App closely copies another app's UI/functionality
- Fake system dialogs or misleading UI elements
- SEO manipulation in metadata
- App with minimal changes resubmitted under different name

---

## Guideline Reference

### Section 1: Safety
- **1.1** Objectionable Content
- **1.2** User Generated Content — need moderation, reporting, blocking
- **1.3** Kids Category — COPPA compliance, no third-party analytics
- **1.4** Physical Harm — medical apps need disclaimers
- **1.5** Developer Information — real contact info required

### Section 2: Performance
- **2.1** App Completeness — no bugs, crashes, or placeholder content
- **2.2** Beta Testing — no "beta" apps on the store
- **2.3** Accurate Metadata — everything must match reality
- **2.4** Hardware Compatibility — must work on claimed devices
- **2.5** Software Requirements — no private APIs, must use current SDK

### Section 3: Business
- **3.1** Payments — IAP for digital goods, no external payment links
- **3.2** Other Business Issues — clear pricing, no deceptive subscriptions

### Section 4: Design
- **4.0** Design — quality bar, native feel
- **4.1** Copycats — no clones of existing apps
- **4.2** Minimum Functionality — must add genuine value
- **4.3** Spam — no duplicate apps, no SEO manipulation
- **4.5** Apple Sites and Services — proper API usage
- **4.7** HTML5 Games/Apps — must be in Safari, not native wrapper
- **4.8** Sign in with Apple — required if you have social login

### Section 5: Legal
- **5.1** Privacy — data collection, storage, sharing
- **5.2** Intellectual Property — no IP infringement
- **5.3** Gaming/Gambling — licensing required
- **5.4** VPN Apps — strict requirements
- **5.5** Developer Code of Conduct — manipulation, fraud

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
```

### Metadata Patterns to Flag

```
# In app name/subtitle/description:
"best"           → requires substantiation
"#1"             → requires third-party verification
"free"           → Apple shows price separately
"beta"           → implies incomplete
"android"        → competitor platform reference
"google"         → competitor reference
"samsung"        → competitor reference
"$", "€", "£"   → pricing should be in IAP
"subscribe at"   → potential IAP bypass
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
- [ ] Test Sign in with Apple flow (if applicable)
- [ ] Test account deletion flow end-to-end (if app supports account creation)
- [ ] Test on oldest supported iOS version
- [ ] Remove all debug/test code and logging
- [ ] Verify push notifications work
- [ ] Check background modes are justified
- [ ] Review entitlements against actual usage
