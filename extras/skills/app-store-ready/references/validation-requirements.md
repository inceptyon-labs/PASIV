# App Store Validation Requirements

Complete checklist of Apple's hard requirements for App Store submission.

Last verified: 2026-11-21 against developer.apple.com (App Review Guidelines dated October 16,
2026; Upcoming Requirements; App Store Connect reference pages). Apple changes these often —
when a date below has passed or a check looks off, re-check
https://developer.apple.com/news/upcoming-requirements/ before flagging a BLOCKER.

## Table of Contents
1. [App Icon Requirements](#app-icon-requirements)
2. [Screenshot Requirements](#screenshot-requirements)
3. [Metadata Requirements](#metadata-requirements)
4. [Privacy Requirements](#privacy-requirements)
5. [Binary Requirements](#binary-requirements)
6. [Additional Submission Checks](#additional-submission-checks)
7. [Required Capabilities](#required-capabilities)
8. [iPhone Duo Readiness](#iphone-duo-readiness)

---

## App Icon Requirements

### Formats (iOS, iPadOS, macOS, watchOS)
Two accepted formats:
- **Icon Composer file (`.icon`)** — layered icon (background + one or more foreground layers)
  exported from Icon Composer (ships with Xcode 26+). Apple's preferred format: it controls how
  Liquid Glass (specular highlights, refraction, translucency) applies per layer and how color
  applies across appearance variants.
- **Non-layered bitmap (PNG) in `AppIcon.appiconset`** — still accepted. The system tries to
  segment it into foreground/background layers; text and thin lines won't get Liquid Glass effects.

tvOS and visionOS icons are image stacks in the asset catalog (not Icon Composer).

### Specifications (HIG)

| Platform | Layout size | Shape after system mask | Layers | Appearances |
|----------|-------------|------------------------|--------|-------------|
| iOS, iPadOS, macOS | 1024×1024 px, square | Rounded rectangle | Layered | Default, dark, clear light, clear dark, tinted light, tinted dark |
| watchOS | 1088×1088 px, square | Circle | Layered | — |
| visionOS | 1024×1024 px, square | Circle | Background + 1–2 layers (max 3) | — |
| tvOS | 800×480 px, landscape | Rounded rectangle | 2–5 layers (parallax) | — |

### Checks
- **App Store icon present** — iOS: 1024pt image well in `AppIcon`; macOS: "App Store - 2x" well;
  tvOS: "App Icon - App Store" stack; or a `.icon` file set as the app icon.
- **Square, unmasked artwork** — no baked rounded corners or circles. Pre-masked layers break
  specular highlights and leave jagged edges.
- **No alpha on the default (light) 1024 PNG** — App Store Connect rejects transparency there.
  Exception: Xcode's dark variant is supplied with a transparent background, and the tinted
  variant as grayscale.
- **Color space**: sRGB, Gray Gamma 2.2, or Display P3 (P3 not on visionOS).
- **No custom glass/shine/drop-shadow/bevel effects** — the system applies these dynamically.
- **Contents.json valid** — all referenced files exist. A single 1024×1024 "Single Size" icon is
  enough for iOS/iPadOS/watchOS; macOS needs every size unless using a `.icon` file.
- **Alternate app icons** (iOS/iPadOS) need their own dark, clear, and tinted variants and are
  subject to App Review.
- **No other developer's icon, brand, or product name** in your icon (4.1(c)).
- **No Apple hardware replicas** in the icon.

### Appearance Variants
Users can choose default, dark, clear, or tinted Home Screen icons. The system generates any
variant you don't provide; custom variants look better. Keep core features identical across
variants. Missing variants → TIP, not a blocker.

### Icon Quality Checks
- Legible at small sizes (Settings, Spotlight, notifications)
- High contrast between foreground and background
- Recognizable silhouette; prefer illustrations over photos
- Text only when essential to the brand
- Key content centered (corners and circular masks crop the edges)
- watchOS: avoid a pure black background

---

## Screenshot Requirements

See `screenshot-sizes.md` for exact dimensions per device class.

### General Rules
- **1–10 screenshots** per device size, per locale
- Format: `.jpeg`, `.jpg`, or `.png` — **no alpha channel or transparency**
- **More than half of the screenshots for each device must show the app in use** (2.3.3). Splash
  screens, login pages, title art, and marketing slides may fill the rest.
- No misleading UI, fake notifications, or interfaces the app doesn't have (2.3.1, 2.3.3)
- Text and image overlays and device frames are allowed if the app UI isn't crowded out
- Icons, screenshots, and previews must suit a **4+ audience** even if the app is rated higher (2.3.8)
- No prices, terms, or unrelated descriptions (2.3.7); no other platforms' names/icons — including
  in a status bar (2.3.10)

### Required Device Sizes (App Store Connect)
- **iPhone:** at least one screenshot for **iPhone with Dynamic Island (medium display)** —
  1206×2622 or 1179×2556 portrait. If neither Dynamic Island (large) nor Face ID (large)
  screenshots are provided, those sizes become required too, so in practice upload a
  Dynamic Island (large) set (1320×2868) plus Dynamic Island (medium).
- **iPad (if the app runs on iPad):** at least one **13" display** screenshot (2064×2752 or 2048×2732).
- **iPhone Duo — required by this skill for every app that runs on iPhone** (1398×2034 outer,
  2007×2853 inner, or landscape). Apple requires them **starting April 2027** for apps built with
  the iOS 27.1 SDK or later. Until then the BLOCKER is skill policy, so label it that way.
  Providing them adds an "optimized for iPhone Duo" badge. They must show the app as it actually
  runs on Duo — see § iPhone Duo Readiness.
- **Mac / Apple TV / Apple Vision Pro / Apple Watch:** required for apps on those platforms.

Smaller sizes fall back to scaled versions of larger buckets — see the fallback chain in
`screenshot-sizes.md`.

---

## Metadata Requirements

### Fields

| Field | Max Length | Required | Notes |
|-------|-----------|----------|-------|
| App Name | 2–30 chars | Yes | Strongest keyword weight. Only changeable with a new version once submitted |
| Subtitle | 30 chars | No | Strong keyword weight. No unverifiable claims or references to other apps (2.3.7) |
| Description | 4000 chars | Yes | Not used for search ranking; drives conversion |
| Promotional Text | 170 chars | No | Editable any time without a new submission |
| Keywords | 100 **bytes** | Yes | Comma-separated; each keyword > 2 chars; no other app or company names; don't repeat app/company name. CJK/emoji use more bytes |
| What's New | 4000 chars | Yes (updates) | Not available on the first version. Must describe significant changes (2.3.12) |
| Support URL | — | Yes | Must lead to real contact info (1.5) |
| Marketing URL | — | No | |
| Privacy Policy URL | — | Yes (iOS, macOS) | tvOS requires privacy policy text instead |
| Copyright | — | Yes | Year the rights were obtained + owner (e.g. "2024 Example, Inc."), not necessarily the current year |
| App Review Notes | 4000 bytes | Effectively yes | Specific description of new features (2.3.1(a)) and a demo account if login exists (2.1(a)) |
| Accessibility URL | — | No | Part of Accessibility Nutrition Labels |
| Age Rating | — | Yes | Questionnaire, see Additional Submission Checks |
| DSA trader status | — | Yes | Required to distribute in the EU |

### Metadata Content Rules
- **No keyword stuffing**, trademarked terms, popular app names, or pricing in metadata (2.3.7)
- **No special characters** solely for attention (★, ♥, etc.)
- **No other platforms or alternative app marketplaces** named in app or metadata (2.3.10)
- **No unverifiable claims** ("best", "#1") in subtitle or creative assets (2.3.7, 2.3.14)
- **"For Kids" / "For Children"** reserved for the Kids Category (2.3.8)
- **IAP disclosure** — description, screenshots, and previews must say which items need extra purchases (2.3.2)
- **Category** must match primary function
- **Creative assets** (product page header, search result asset) — about the app or brand,
  4+ appropriate, no specific or discounted pricing, no misleading references to other apps (2.3.14)

---

## Privacy Requirements

### App Privacy (Privacy Nutrition Labels in App Store Connect)
Required for all apps. Must declare:
- **Data Linked to You**: data connected to your identity
- **Data Used to Track You**: data used for cross-app tracking
- **Data Not Linked to You**: anonymized/aggregate data

Categories: Contact Info, Health & Fitness, Financial Info, Location, Sensitive Info,
Contacts, User Content, Browsing History, Search History, Identifiers, Purchases,
Usage Data, Diagnostics, Other Data

### PrivacyInfo.xcprivacy (enforced since May 1, 2024)
Must declare:
- **NSPrivacyTracking** and **NSPrivacyTrackingDomains**
- **NSPrivacyCollectedDataTypes** matching the App Store Connect declarations
- **NSPrivacyAccessedAPITypes** — an approved reason for each required-reason API category used

App Store Connect rejects uploads that use a required-reason API without a declared reason.
Each executable or dynamic library that uses one needs its own manifest in its bundle.

### Required Reason API Categories
| `NSPrivacyAccessedAPIType` | Examples |
|----------------------------|----------|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `creationDate`, `modificationDate`, `stat`, `getattrlist` |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `systemUptime`, `mach_absolute_time` |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `volumeAvailableCapacityKey`, `statfs` |
| `NSPrivacyAccessedAPICategoryActiveKeyboards` | `activeInputModes` |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `UserDefaults` |

### Third-Party SDK Privacy Manifests and Signatures
Apps that add an SDK from Apple's commonly-used list must include that SDK's privacy manifest,
and a valid signature when it's a binary dependency. This covers any version of a listed SDK and
SDKs that repackage one. List: https://developer.apple.com/support/third-party-SDK-requirements/
— includes Firebase*, FBSDK*, GoogleSignIn, Alamofire, AFNetworking, Kingfisher, SDWebImage,
Lottie, OneSignal*, RealmSwift, Flutter, hermes, Capacitor, Cordova, UnityFramework, and common
Flutter plugins (path_provider, shared_preferences_ios, url_launcher, image_picker_ios, etc.).

### Data Sharing and AI (5.1.2(i))
- Disclose where personal data is shared with third parties, **including third-party AI**, and
  get **explicit permission** before sharing. An app that sends user content or personal data to
  an external LLM API (OpenAI, Anthropic, Gemini, etc.) needs an in-app disclosure + consent step.
- Tracking requires App Tracking Transparency permission.
- The app may not require push notifications, location, or tracking to unlock functionality or rewards.

### Permission Usage Descriptions (Info.plist)
Every permission your app requests MUST have a usage description string that:
- Explains specifically WHY the app needs this permission
- Is written in natural language the user can understand
- Is NOT generic (e.g., "needs camera access" → rejected)
- IS specific (e.g., "Take photos to add to your recipe collection")

Common required descriptions:
```
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
NSMicrophoneUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSContactsUsageDescription
NSCalendarsFullAccessUsageDescription
NSCalendarsWriteOnlyAccessUsageDescription
NSRemindersFullAccessUsageDescription
NSMotionUsageDescription
NSSpeechRecognitionUsageDescription
NSFaceIDUsageDescription
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription
NSBluetoothAlwaysUsageDescription
NSLocalNetworkUsageDescription
NSUserTrackingUsageDescription
```

---

## Binary Requirements

### Build SDK and Xcode (upload requirements)
- **Since April 28, 2026:** apps must be built with **Xcode 26 or later** using the iOS 26,
  iPadOS 26, tvOS 26, visionOS 26, or watchOS 26 SDK. Older SDK → BLOCKER (upload rejected).
- **Starting April 2027:** iOS/iPadOS apps must be built with the **iOS 27 / iPadOS 27 SDK**
  (Xcode 27); same for tvOS 27, visionOS 27, watchOS 27. Flag as WARNING when the project still
  uses Xcode 26 and submission is near or after that date.
- watchOS apps must include 64-bit (arm64) support (since April 2026).

How to check: `xcodebuild -version`; `SDKROOT` / `LastUpgradeCheck` in `project.pbxproj`;
`DTXcode` / `DTSDKName` in a built app's Info.plist; Flutter/RN builds inherit the local Xcode.

### Minimum Deployment Target
- **Since September 9, 2026:** iOS and iPadOS apps uploaded must **target iOS 13 or later**.
  `IPHONEOS_DEPLOYMENT_TARGET` < 13.0 → BLOCKER.
- Supporting roughly the last 2–3 major iOS versions is typical; lower targets increase test burden.
- macOS 26 is the last release supporting Intel Macs; macOS 27 is Apple silicon only. Mac apps
  can ship arm64-only (TIP).

### Version and Build
- `CFBundleShortVersionString` — marketing version (e.g., "1.2.3")
- `CFBundleVersion` — build number (must increment for each upload)
- Both must be set and consistent across targets (app + extensions)

### Architectures
- Must include arm64
- Must NOT include simulator slices (i386, x86_64 for iOS) in App Store builds

### Entitlements
These capabilities require extra review or agreements:
- Apple Pay → Apple Pay merchant ID and agreement
- Push Notifications → APNs auth key or certificate configured
- Sign in with Apple → Services ID; Republic of Korea developers must register a server-to-server
  notification endpoint (since January 1, 2026)
- HealthKit → detailed review of health data usage
- HomeKit → MFi compliance may be needed
- StoreKit External Purchase / External Link Account entitlements → regional, must be approved
- Background Modes → must justify each mode used (2.5.4)

### Code Signing
- Must use distribution certificate (not development)
- Provisioning profile must match bundle ID
- Team ID must be consistent

---

## Additional Submission Checks

These are commonly overlooked and cause rejection or upload failure:

| Check | What to verify |
|-------|---------------|
| Export compliance | `ITSAppUsesNonExemptEncryption` in Info.plist — declare if app uses encryption |
| Age rating questionnaire | Answered with the current question set (see below) |
| Demo account / review notes | Working demo credentials with the backend live if there's a login (2.1(a)); IAP visible to the reviewer or explained (2.1(b)) |
| Hidden features | No dormant, undocumented, or remotely-unlocked functionality, and no obfuscation to hide features (2.5.19) |
| TestFlight upload | Build must not contain simulator architectures |
| Associated domains | If using universal links, apple-app-site-association must be hosted correctly |
| IAP configuration | If StoreKit is used, products must exist in App Store Connect and be submitted with the version |
| Background modes | All declared modes must be actively used and justified |
| Push notifications | APNs configured if entitlement exists; no marketing spam via push or Live Activities (4.5.3) |
| EU distribution | Digital Services Act trader status provided — apps without it are removed from the EU App Store |
| Content rights | Third-party content requires proper licensing |
| Accessibility Nutrition Labels | Voluntary for now; Apple says they will become required for new apps and updates (no date yet) → TIP |

### Age Rating (current system)
- Tiers: **4+, 9+, 13+, 16+, 18+** (Unrated apps can't be published on the App Store).
  Regional scales exist for Australia, Brazil, Republic of Korea, and Vietnam.
- Questionnaire sections: In-App Controls (parental controls, age assurance), Capabilities
  (unrestricted web access, user-generated content, social media, messaging and chat, shared
  location, advertising), Mature Themes (incl. dating and relationships), Medical or Wellness,
  Sexuality or Nudity, Violence, Chance-Based Activities (gambling, simulated gambling, contests,
  loot boxes).
- **Social media capability** answers are required for new apps and updates since September 2026.
- **Shared Location** and **Dating and Relationships** declarations: in App Store Connect from
  November 16, 2026; required on the next update and for **all apps by January 12, 2027**.
  Dating and Relationships (including virtual romantic/sexual companions) → minimum **18+**.
- Brazil: loot boxes → 18+; Shared Location → A16; Dating and Relationships → A18.

### Age Assurance Laws
If the app is distributed in these regions and has account-based features, minors, or
significant updates, check for **Declared Age Range API** integration:
- **Texas (SB 2420):** in effect for new Texas Apple Accounts since June 4, 2026 — age
  assurance and parental consent for minors; use the Declared Age Range API, the Significant
  Change API (PermissionKit) for significant updates, and the consent-revocation App Store
  server notification.
- **Utah** (new accounts from May 6, 2026) and **Louisiana** (from July 1, 2026): age categories
  shared via the Declared Age Range API; same tool set.
- **Australia, Brazil, Singapore:** App Store blocks 18+ downloads for unconfirmed adults (since
  February 24, 2026); developers may have their own age-confirmation duties. Australia: certain
  social media platforms must prevent under-16 accounts (since December 10, 2025).
- Creator-content apps (1.2.1(a)) and mini-app/game/emulator hosts (4.7.5) need an age
  restriction mechanism based on verified or declared age.

---

## Required Capabilities

### If you use third-party or social login (Guideline 4.8 — Login Services)
If Google, Facebook, X, LinkedIn, Amazon, WeChat, etc. login sets up or authenticates the user's
primary account, also offer an **equivalent login option** that:
- limits data collection to name and email,
- lets users keep their email private, and
- doesn't collect interactions for advertising without consent.

Sign in with Apple meets this, but any service with those properties does. Not required when the
app uses only your own account system, is an education/enterprise/business app using existing
org accounts, uses government/industry e-ID, or is a client for a specific third-party service
(mail, social) whose account it accesses directly.

### If you have subscriptions (3.1.2)
- Must use StoreKit for digital purchases (except storefront exceptions under 3.1.1(a) / 3.1.3)
- Period of at least 7 days, available on all of the user's devices
- Describe what the user gets before asking them to subscribe (3.1.2(c)); price and duration clear
- No bait-and-switch or misleading subscription flows (removal + possible program termination)
- Must have a way to manage/cancel subscriptions

### External purchase links (3.1.1(a), 3.1.3)
- **United States storefront:** buttons, external links, and calls to action to other purchase
  methods are allowed without an entitlement.
- **Other storefronts:** links require an approved StoreKit External Purchase Link Entitlement in
  the storefronts where Apple offers one (check Apple's entitlement docs for the current list);
  otherwise no buttons, links, or calls to action toward non-IAP purchasing.
- **EU:** since October 1, 2026, apps may offer alternative payment options alongside IAP under
  Apple's single EU business terms. **Japan:** alternative payments allowed from iOS 26.2.
- Reader apps may use the External Link Account Entitlement (3.1.3(a)).

### If you have user-generated content (1.2)
- Filtering of objectionable material, including nonconsensual intimate imagery (incl. AI-generated)
- Report mechanism with timely responses, and the ability to block abusive users
- Published contact information
- Random or anonymous chat, "hot-or-not" voting, and Chatroulette-style apps don't belong on the store
- AI content-generation apps are covered by the same rules
- Must comply with CSAM requirements

### If you support account creation (Guideline 5.1.1(v))
- **Account deletion is REQUIRED** — apps that support account creation must also offer account deletion
- Deletion must be **in-app** — not just via email/phone (unless highly-regulated industry)
- Only temporarily deactivating or disabling an account is **insufficient** — must be permanent deletion
- If users must visit a website to finish deletion, include a **direct link** to that page
- May include a confirmation step to prevent accidental deletion
- Must delete all user data associated with the account (local + server-side + cloud)
- Apple may request a **screen recording** demonstrating the full account deletion flow
- Don't require login if the app has no significant account-based features

### If you collect personal data
- Must have a privacy policy accessible from the app
- Must comply with applicable privacy laws (GDPR, CCPA, etc.)
- Must not share data (including with third-party AI) without disclosure and explicit consent

### Regulated fields (5.1.1(ix))
Banking, financial services, healthcare, gambling, legal cannabis, air travel, and **crypto
exchanges** must be submitted by the legal entity providing the service, not an individual developer.

---

## iPhone Duo Readiness

iPhone Duo (on sale October 23, 2026) is a foldable: a compact outer display (1398×2034) and a
large inner display (2007×2853, about 1.45:1). Apps resize when it folds, unfolds, half-folds,
or rotates. Bars can move to the side of the screen as a vertical column. A fold region and the
front cameras are "reserved regions" that content must avoid.
Sources: developer.apple.com/iphone-duo/prepare/, "Preparing your app for iPhone Duo"
(Technology Overviews), HIG "Designing for iPhone Duo", TN3187.

Skip this section if the app doesn't run on iPhone (`TARGETED_DEVICE_FAMILY` without `1`).

### 1. SDK tier

| Built with | Behavior on iPhone Duo | Severity |
|-----------|------------------------|----------|
| Xcode 26 / iOS 26 SDK or earlier | Inner display: app centered with empty space around it. Outer: content beside the status bar and camera | BLOCKER (skill policy) |
| Xcode 27 / iOS 27 SDK | Fills most of the inner display, still avoids the right-edge status bar | BLOCKER (skill policy) — not "optimized" |
| Xcode 27.1 / iOS 27.1 SDK or later | Full display, toolbars and tab bars vertical below the status bar. Apple calls this optimized | PASS — then check bar content adapts to vertical bars |

How to tell: `xcodebuild -version` locally; CI pins (`.xcode-version`, GitHub Actions
`xcode-version:`, `xcode-select` in scripts, Xcode Cloud workflow); `DTXcode`/`DTSDKName` in a
built app's Info.plist. Flutter, React Native, and Unity inherit whichever Xcode builds them.

### 2. UIScene life cycle
TN3187: "In the next major release following iOS 26, UIScene lifecycle will be required when
building with the latest SDK; otherwise, your app won't launch." Adopting the scene life cycle
is required; supporting multiple scenes isn't.
- Pass: SwiftUI `App` entry point, or `UIApplicationSceneManifest` in Info.plist with a scene delegate.
- Building with the iOS 27 SDK or later without either → BLOCKER. With the iOS 26 SDK → WARNING
  (the move to Xcode 27 is mandatory in April 2027).

### 3. Layout pattern scan
Grep app source (skip `Pods/`, `.build/`, `DerivedData/`, vendored SDKs). Report each hit as
WARNING with file:line and the fix.

| Pattern (grep) | Problem on Duo | Fix Apple recommends |
|---------------|----------------|----------------------|
| `UIScreen.main` (`.bounds`, `.scale`, `.nativeBounds`) | App size changes on fold/unfold and doesn't match the screen | `view.bounds` / `window.bounds`; SwiftUI `GeometryReader` / `onGeometryChange`; `traitCollection.displayScale` / `@Environment(\.displayScale)` |
| `UIWindow(frame:` | Window not tied to a scene | `UIWindow(windowScene:)` |
| Stored `UIScreen` properties | Screen changes between displays | Read it when needed: `view.window?.windowScene?.screen` |
| Size read once in `viewDidLoad`/`viewIsAppearing`/`init` | A fold resizes the app mid-session | Do layout in `layoutSubviews`/`viewDidLayoutSubviews`; size-change work in `viewWillTransition(to:with:)` |
| `UIDevice.current.orientation`, `statusBarOrientation`, `interfaceOrientation` (incl. `effectiveGeometry.interfaceOrientation`) used for layout | Device orientation doesn't say what shape the app is | Compare width vs height of `view.bounds` / `superview.bounds` / `GeometryReader` size |
| `userInterfaceIdiom == .phone` / `.pad` driving layout | iPhone apps can now have any size-class combination | Choose layout by size class or available space |
| `horizontalSizeClass == .regular` treated as "iPad", or iPhone assumed compact | Regular width now happens on iPhone (inner display) | Treat regular width as "more space", not "iPad"; the inner display should look like the iPad layout |
| Hardcoded sizes (`== 844`, `== 852`, `== 926`, `== 932`, `== 956`, lists of known iPhone heights) | Won't match Duo's displays | Remove; use available space |
| `.scaleAspectFill`, `.aspectRatio(contentMode: .fill)` on hero media | Wider displays crop important content | Pick fill vs fit by aspect ratio or size class, or set a focal point |
| `UIToolbar(`, `UINavigationBar(`, `UITabBar(` built by hand; SwiftUI custom bar views instead of `.toolbar` | System can't present the bar vertically | Set items on a view controller in a navigation controller; SwiftUI `.toolbar` on `NavigationStack`/`NavigationSplitView` |
| Toolbar items with a title but no icon, or a custom view | Not shown in vertical bars | Give items both an icon and a title; use `visibilityPriority` / overflow menu for low-priority items |
| `UISupportedInterfaceOrientations` portrait-only (or `SystemChrome.setPreferredOrientations` / RN orientation lock) | Apple lists fixed orientations as a cause of broken layouts | Support rotation; games may lock one orientation but must fill the screen in every pose |

TIPs (not warnings):
- Custom side-by-side or overlay layouts → consider `ArrangementView` / `UIArrangementViewController`.
- Custom views that could sit under the fold or the inner camera → use `ReservedRegion`
  (SwiftUI `GeometryProxy.reservedRegions`, UIKit `UIView.reservedRegions(kind:options:)`).
- Grids → an even column count divides cleanly at the fold.
- Camera capture (AVFoundation) → the app can move between displays mid-capture and the active
  camera can flip direction; see "Choosing a camera by the direction it faces".
- Hero/background images under vertical bars → `backgroundExtensionEffect()` / `UIBackgroundExtensionView`.

Cross-platform apps: apply the same ideas to the framework's equivalents (Flutter
`MediaQuery` orientation or fixed sizes driving layout, RN `Dimensions.get('screen')`, Unity
fixed resolution). Confirm the framework version supports building with Xcode 27.1.

### 4. Testing (manual — always list as remaining)
- iPhone Duo simulator in Xcode 27.1 (best for the full native experience). Check with
  `xcrun simctl list devicetypes | grep -i duo`.
- Device Hub resizable iOS simulator.
- iPhone Mirroring on macOS 27, resized to extreme sizes in both directions.
- Poses to walk through: closed (outer), fully open, half-folded like a book, rotated in each.
  Check every screen, sheet, and popover for clipped, stretched, or fold-straddling controls,
  and that state carries over when moving between displays.

### Verdict
- **OPTIMIZED** — built with the iOS 27.1 SDK+, scene life cycle, no WARNING-level pattern hits,
  Duo screenshots present.
- **RUNS BUT NOT OPTIMIZED** — older SDK, no layout red flags.
- **BROKEN LAYOUT RISK** — pattern hits that will clip or misplace content once resizing is enabled.
