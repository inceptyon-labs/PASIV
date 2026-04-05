# App Store Validation Requirements

Complete checklist of Apple's hard requirements for App Store submission.

## Table of Contents
1. [App Icon Requirements](#app-icon-requirements)
2. [Screenshot Requirements](#screenshot-requirements)
3. [Metadata Requirements](#metadata-requirements)
4. [Privacy Requirements](#privacy-requirements)
5. [Binary Requirements](#binary-requirements)
6. [Required Capabilities](#required-capabilities)

---

## App Icon Requirements

### Required Icon (App Store Connect)
- **Size**: 1024×1024 pixels exactly (for iOS/iPadOS/macOS)
- **Format**: PNG
- **Color space**: sRGB, Display P3, or Gray Gamma 2.2
- **No alpha channel** (transparency) — Apple will reject
- **No rounded corners** — Apple applies its own superellipse mask. Provide square/unmasked artwork.
- **No layers or effects** that suggest interactivity (glass, shine)
- Apple specifies pixel dimensions — DPI/PPI is not a submission requirement

### Platform-Specific Icon Sizes

| Platform | Size | Notes |
|----------|------|-------|
| iOS/iPadOS/macOS | 1024×1024 | Standard single-layer icon |
| watchOS | 1024×1024 | Circular mask applied by system |
| tvOS | 400×240 per layer | Layered icon stack (front + back) — cannot auto-generate |
| visionOS | 1024×1024 | Layered icon system — cannot auto-generate from single image |

### Appearance Variants (iOS/iPadOS/macOS)
Apple supports automatic icon appearance variants:
- **Default** — standard light appearance
- **Dark** — shown in dark mode
- **Tinted** — shown when user enables tinted icons
The system can generate missing variants, but providing custom variants looks better.

### App Icon Set (in Xcode)
As of Xcode 15+, a single 1024×1024 icon is sufficient for iOS/iPadOS/macOS — Xcode auto-generates
all sizes. tvOS and visionOS require layered icon stacks that must be provided separately.
For legacy projects, the full icon set includes:

| Size | Scale | Use |
|------|-------|-----|
| 20×20 | 2x, 3x | Notifications |
| 29×29 | 2x, 3x | Settings |
| 38×38 | 2x, 3x | Home Screen (small) |
| 40×40 | 2x, 3x | Spotlight |
| 60×60 | 2x, 3x | Home Screen |
| 64×64 | 2x, 3x | Home Screen (large) |
| 68×68 | 2x | Home Screen (iPad) |
| 76×76 | 2x | Home Screen (iPad) |
| 83.5×83.5 | 2x | Home Screen (iPad Pro) |
| 1024×1024 | 1x | App Store |

### Icon Quality Checks
- Legible at 29×29 (smallest display size)
- High contrast between foreground and background
- Recognizable silhouette shape
- Not too similar to Apple's own icons or well-known apps
- No photos (photographs don't scale well to small sizes)
- Brand mark is centered and not cropped by corner radius

---

## Screenshot Requirements

See `screenshot-sizes.md` for exact dimensions per device class.

### General Rules
- **Minimum 1 screenshot per device class** you support
- **Maximum 10 screenshots** per device class
- Format: PNG or JPEG
- Screenshots must reflect actual app experience
- No misleading content, fake notifications, or status bar manipulation
- Can include text overlays and device frames
- First 3 screenshots appear in search results — most important

### Required Device Classes
You must provide screenshots for each device class your app supports:
- iPhone 6.9" (required if supporting current iPhones — primary display bucket)
- iPhone 6.5" (fallback accepted if 6.9" not provided; also accepts 1284×2778)
- iPhone 5.5" (legacy, for older models)
- iPad 13" (required if supporting iPad — primary iPad bucket)
- iPad 11" (covers standard iPads; also accepts 1488×2266, 1640×2360, 1668×2420)

Note: Apple now groups screenshots by display bucket, not exact device. The 6.9" bucket is
primary for iPhone; the 13" bucket is primary for iPad. See screenshot-sizes.md for all
accepted dimensions per bucket.

### Content Rules
- Must show actual app functionality
- No "Coming Soon" features
- No prices (unless using IAP and showing via StoreKit)
- No "Free" or "Sale" badges
- No competitor mentions
- No Apple hardware renders except official device frames

---

## Metadata Requirements

### Character Limits

| Field | Max Length | Required | Notes |
|-------|-----------|----------|-------|
| App Name | 30 chars | Yes | Keywords here have strong weight |
| Subtitle | 30 chars | Yes | Appears below name in search |
| Description | 4000 chars | Yes | Not indexed for search |
| Promotional Text | 170 chars | No | Editable without new build |
| Keywords | 100 bytes | Yes | Comma-separated, no spaces. Note: BYTES not chars — CJK/emoji use more |
| What's New | 4000 chars | Yes (updates) | Required for each update |
| Support URL | — | Recommended | Not strictly required by Apple, but strongly recommended |
| Marketing URL | — | No | Recommended |
| Privacy Policy URL | — | Yes | Required for all apps |

### Metadata Content Rules
- **No keyword stuffing** in title or subtitle
- **No special characters** solely for attention (★, ♥, etc.)
- **No competitor names** anywhere in metadata
- **No misleading claims** ("best", "#1" without substantiation)
- **No pricing information** in metadata (managed by App Store)
- **Category selection** must match primary function
- **Age rating** must be accurate based on content
- **Copyright** field must be current year + company name

---

## Privacy Requirements

### Privacy Nutrition Labels (App Privacy on App Store)
Required for all apps. Must declare:
- **Data Linked to You**: data connected to your identity
- **Data Used to Track You**: data used for cross-app tracking
- **Data Not Linked to You**: anonymized/aggregate data

Categories: Contact Info, Health & Fitness, Financial Info, Location, Sensitive Info,
Contacts, User Content, Browsing History, Search History, Identifiers, Purchases,
Usage Data, Diagnostics, Other Data

### PrivacyInfo.xcprivacy (Required since Spring 2024)
Must declare:
- **Privacy tracking domains** (domains used for tracking)
- **Required reason APIs** (why you use certain system APIs)
- **Privacy nutrition label types** matching App Store Connect declarations
- **Tracking declaration** (do you track users across apps/websites)

### Required Reason APIs (must declare purpose)
- File timestamp APIs (`NSFileCreationDate`, etc.)
- System boot time APIs
- Disk space APIs
- User defaults APIs
- Active keyboard APIs

### Third-Party SDK Privacy Manifests
Apple now requires commonly-used third-party SDKs to include their own `PrivacyInfo.xcprivacy`.
Check that major SDKs bundled in the app (Firebase, Facebook SDK, Amplitude, Adjust, AppsFlyer,
Google Analytics, etc.) include their privacy manifests. If a required SDK is missing its manifest,
Apple will reject the build during upload processing.

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
NSCalendarsUsageDescription
NSRemindersUsageDescription
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

### Version and Build
- `CFBundleShortVersionString` — marketing version (e.g., "1.2.3")
- `CFBundleVersion` — build number (must increment for each upload)
- Both must be set and consistent across targets

### Minimum Deployment Target
- Apple recommends supporting at least the last 2 major iOS versions
- Apps targeting very old versions may face extra scrutiny

### Architectures
- Must include arm64
- Must NOT include i386 or x86_64 for App Store (simulator archs)

### Entitlements
These capabilities require extra review or agreements:
- Apple Pay → needs Apple Pay merchant agreement
- Push Notifications → must have APNS certificate
- Sign in with Apple → required if you offer social login
- HealthKit → requires detailed review of health data usage
- HomeKit → MFi compliance may be needed
- Background Modes → must justify each mode used

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
| Age rating | Content must match the declared rating in App Store Connect |
| TestFlight upload | Build must not contain simulator architectures (i386/x86_64) |
| Associated domains | If using universal links, apple-app-site-association must be hosted correctly |
| IAP configuration | If StoreKit is used, products must exist in App Store Connect |
| Background modes | All declared modes must be actively used and justified |
| Push notifications | If entitlement exists, APNS certificate must be configured |
| Content rights | Third-party content requires proper licensing |

---

## Required Capabilities

### If you use social login
- **Sign in with Apple** is REQUIRED as an option (Guideline 4.8)
- Must be presented at least equally prominently as other options

### If you have subscriptions
- Must use StoreKit for all digital purchases
- Subscription terms must be visible before purchase
- Must have a way to manage/cancel subscriptions
- Must show subscription price and duration clearly

### If you have user-generated content
- Must have content filtering/reporting mechanism
- Must have a way to block users
- Must comply with CSAM requirements

### If you collect personal data
- Must have a privacy policy accessible from the app
- Must comply with applicable privacy laws (GDPR, CCPA, etc.)
- Must not share data without consent
