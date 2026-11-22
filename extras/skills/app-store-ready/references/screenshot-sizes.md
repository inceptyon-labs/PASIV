# App Store Screenshot, Preview, and Creative Asset Sizes

Last verified: 2026-11-21. Apple renames buckets and adds devices every fall — cross-check before
flagging a size as wrong.
Sources:
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications

## Required Sizes

- **iPhone:** at least one screenshot for **iPhone with Dynamic Island (medium display)**.
  Face ID (large) is required when Dynamic Island (large) isn't provided. Practical minimum:
  one Dynamic Island (large) set (1320×2868) + one Dynamic Island (medium) set (1206×2622).
- **iPad (if the app runs on iPad):** at least one **13" display** screenshot.
- **iPhone Duo:** **required by this skill** for every app that runs on iPhone. Apple requires
  them starting April 2027 for apps built with the iOS 27.1 SDK or later.
- **Mac, Apple TV, Apple Vision Pro, Apple Watch:** required for apps on those platforms.

If the UI is the same across sizes, upload only the highest required resolution; App Store
Connect scales down for smaller sizes.

## iPhone Screenshots

Apple names iPhone buckets by display type, not inches. Landscape = portrait dimensions swapped.

| Bucket | Accepted portrait sizes | Devices | Falls back to (if missing) |
|--------|------------------------|---------|----------------------------|
| iPhone Duo — **required (skill policy)** | 1398×2034 (outer), 2007×2853 (inner) | iPhone Duo | — (Apple requires from April 2027) |
| Dynamic Island (large) | 1260×2736, 1290×2796, 1320×2868 | iPhone Air, 18 Pro Max, 17 Pro Max, 16 Pro Max, 16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max | Face ID (large) |
| Face ID (large) | 1284×2778, 1242×2688 | iPhone 14 Plus, 13/12/11 Pro Max, 11, XS Max, XR | Dynamic Island (large) |
| Dynamic Island (medium) — **required** | 1179×2556, 1206×2622 | iPhone 18 Pro, 17 Pro, 17, 16 Pro, 16, 15 Pro, 15, 14 Pro | Face ID (large) |
| Face ID (medium) | 1170×2532, 1125×2436, 1080×2340 | iPhone 17e, 16e, 14, 13 (Pro/mini), 12 (Pro/mini), 11 Pro, XS, X | Dynamic Island (medium) |
| Home Button (large) | 1242×2208 | iPhone 8 Plus, 7 Plus, 6S Plus, 6 Plus | Face ID (medium) |
| Home Button (medium) | 750×1334 | iPhone SE (2nd/3rd gen), 8, 7, 6S, 6 | Home Button (large) |
| Home Button (4") | 640×1096 (no status bar), 640×1136 | iPhone SE (1st gen), 5S, 5C, 5 | Home Button (medium) |
| Home Button (3.5") | 640×920 (no status bar), 640×960 | iPhone 4S, 4 | Home Button (4") |

Old inch names map as: 6.9"/6.7" → Dynamic Island (large); 6.5" → Face ID (large);
6.1"/6.3" Pro → Dynamic Island (medium); 5.5" → Home Button (large).

---

## iPad Screenshots

| Display | Accepted portrait sizes | Devices | Falls back to |
|---------|------------------------|---------|---------------|
| 13" — **required if app runs on iPad** | 2064×2752, 2048×2732 | iPad Pro (M5, M4, 6th–3rd, 1st gen), iPad Air (M4, M3, M2) | — |
| 12.9" | 2048×2732 | iPad Pro (2nd gen) | 13" |
| 11" | 1488×2266, 1512×2316, 1668×2420, 1668×2388, 1640×2360 | iPad Pro (M5, M4, 4th–1st gen), iPad Air (M4–M2, 5th/4th gen), iPad (A16, 10th gen), iPad mini (A20 Pro, A17 Pro, 6th gen) | 13" |
| 10.5" | 1668×2224 | iPad Pro 10.5", iPad Air (3rd gen), iPad (9th–7th gen) | 12.9" |
| 9.7" | 1536×2008, 1536×2048, 768×1004, 768×1024 | Older iPad, iPad Air/Air 2, iPad mini 2–5 | 10.5" |

Landscape = swapped.

---

## Apple Watch Screenshots

One size, used consistently across all localizations:

| Size | Devices |
|------|---------|
| 422×514 | Ultra 4, Ultra 3 |
| 410×502 | Ultra 2, Ultra |
| 416×496 | Series 12, 11, 10 |
| 396×484 | Series 9, 8, 7 |
| 368×448 | Series 6, 5, 4, SE 3, SE 2, SE |
| 312×390 | Series 3, 2, 1 |

---

## Mac, Apple TV, Apple Vision Pro

| Platform | Accepted sizes |
|----------|---------------|
| Mac | 16:10 only — 1280×800, 1440×900, 2560×1600, or 2880×1800 |
| Apple TV | 1920×1080 or 3840×2160 |
| Apple Vision Pro | 3840×2160 |

---

## App Preview Videos

Accepted resolutions are fixed per bucket, not the device's native resolution.

| Device class | Accepted resolution (portrait / landscape) |
|-------------|-------------------------------------------|
| iPhone Duo, Dynamic Island (large/medium), Face ID (large/medium) | 886×1920 / 1920×886 |
| iPhone Home Button (large), Home Button (4") | 1080×1920 / 1920×1080 |
| iPhone Home Button (medium) | 750×1334 / 1334×750 |
| iPhone Home Button (3.5") | Not supported |
| iPad 13", 11", 10.5" | 1200×1600 / 1600×1200 |
| iPad 12.9" (2nd gen) | 1200×1600 or 900×1200 (and landscape) |
| iPad 9.7" | 900×1200 / 1200×900 |
| Mac, Apple TV | 1920×1080 (landscape only) |
| Apple Vision Pro | 3840×2160 (landscape only) |

- **Optional**; up to **3 per device size per language**
- **Length**: 15–30 seconds; **max file size**: 500 MB; **max 30 fps**
- **Formats**: H.264 (.mov, .m4v, .mp4; 10–12 Mbps, up to High Profile Level 4.0) or ProRes 422 HQ (.mov)
- **Audio**: stereo, 256 kbps AAC (or PCM for ProRes), 44.1 or 48 kHz, all tracks enabled
- Previews always play before screenshots; a preview in a different aspect ratio from the
  screenshots goes in the "A Closer Look" section
- Default poster frame is at 5 seconds; processing takes up to 24 hours
- Not available for iMessage apps

---

## Creative Assets (product page header, search results)

New in fall 2026. Optional image/video assets that complement screenshots; managed in the
App Store Connect Asset Library and checked with the product page preview tool. Must follow 2.3.14
(app/brand-related, 4+ appropriate, no specific or discounted pricing, no unverifiable claims).

| Placement | Aspect | Image size | Art safe area | Image formats |
|-----------|--------|-----------|---------------|---------------|
| Product page header | 21:9 | 3840×1646 | 1646×661 at (1097, 493) | .png |
| Search results | 3:2 | 1920×1280 min – 3840×2560 max | max 2168×1030 at (836, 765) | .jpeg, .jpg, .png |
| Universal (both placements) | 16:9 | 5244×2950 | 1402×962 at (1921, 660) | .png |

- No alpha channels or transparency
- **Video**: same aspect/resolution as the image placement, 30 or 60 fps, 5–30 seconds,
  .mov/.m4v/.mp4. Muted by default and loops (search results can't be unmuted)
- Keep key art inside the safe area; atmospheric background can fill the rest

---

## General Rules

1. **Count**: 1–10 screenshots per device size per locale
2. **Formats**: .jpeg, .jpg, or .png, no alpha channel
3. **App in use**: more than half of each device's screenshots must show the app in use (2.3.3)
4. **Status bar**: no third-party platform references (2.3.10)
5. **Safe margins**: keep critical text away from edges (~5%) — a design practice, not an Apple rule
6. **Orientation**: must match your app's supported orientations
7. **First 3 matter most**: they can appear in search results — lead with the strongest
