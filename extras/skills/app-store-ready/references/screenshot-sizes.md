# App Store Screenshot Size Requirements

Last verified: 2025. Always cross-check with Apple's current documentation as requirements evolve.
Source: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications

## iPhone Screenshots

Apple groups screenshots by display bucket. Multiple resolutions are accepted per bucket.

| Display Bucket | Accepted Resolutions (Portrait W×H) | Device Examples |
|---------------|--------------------------------------|-----------------|
| 6.9" | 1320×2868 | iPhone 16 Pro Max |
| 6.7" | 1290×2796 | iPhone 16 Plus, 15 Plus, 15 Pro Max, 14 Pro Max |
| 6.5" | 1242×2688, 1284×2778 | iPhone 14 Plus, 13 Pro Max, 12 Pro Max, 11 Pro Max, XS Max |
| 6.1" (Super Retina) | 1179×2556 | iPhone 16 Pro, 15 Pro, 14 Pro |
| 6.1" (Liquid Retina) | 1170×2532 | iPhone 14, 13, 12 |
| 5.8" | 1125×2436 | iPhone X, XS, 11 Pro |
| 5.5" | 1242×2208 | iPhone 8 Plus, 7 Plus, 6s Plus |
| 5.4" | 1080×2340 | iPhone 13 mini, 12 mini |
| 4.7" | 750×1334 | iPhone SE (3rd gen), 8, 7 |
| 4" | 640×1136 | iPhone SE (1st gen) |

Landscape dimensions are the portrait dimensions swapped (H×W).

### What You Actually Need to Provide

Apple's primary display bucket is now **6.9"** (or 6.7" if 6.9" not provided). The system
scales for smaller sizes within the same generation.

1. **6.9" screenshots** (1320×2868) — primary bucket for current iPhones
   - If not provided, Apple falls back to 6.7" (1290×2796), then 6.5"
2. **5.5" screenshots** (1242×2208) — covers legacy models
   - Falls back to: 5.4", 4.7", 4"

### Pro Tip
Providing native screenshots for 6.9" and 6.5" separately (rather than relying on scaling)
looks sharper and converts better, since the aspect ratios differ slightly.

---

## iPad Screenshots

| Display Size | Device Examples | Portrait (W×H) | Landscape (W×H) |
|-------------|----------------|-----------------|------------------|
| 13" | iPad Pro 12.9" (M4, 6th gen) | 2048×2732 | 2732×2048 |
| 12.9" | iPad Pro 12.9" (3rd-5th gen) | 2048×2732 | 2732×2048 |
| 11" | iPad Pro 11", iPad Air (M1+) | 1668×2388 | 2388×1668 |
| 10.9" | iPad Air (5th gen), iPad (10th gen) | 1640×2360 | 2360×1640 |
| 10.5" | iPad Air (3rd gen), iPad Pro 10.5" | 1668×2224 | 2224×1668 |
| 10.2" | iPad (9th gen, 8th gen) | 1620×2160 | 2160×1620 |
| 9.7" | iPad (6th gen and earlier) | 1536×2048 | 2048×1536 |
| 8.3" | iPad mini (6th gen) | 1488×2266 | 2266×1488 |
| 7.9" | iPad mini (5th gen) | 1536×2048 | 2048×1536 |

### What You Actually Need to Provide

1. **13" / 12.9" iPad Pro** (2048×2732) — primary iPad bucket, covers all large iPads
2. **11" iPad** — multiple accepted resolutions:
   - 1668×2388 (iPad Pro 11")
   - 1488×2266 (iPad mini 6th gen)
   - 1640×2360 (iPad Air 5th gen, iPad 10th gen)
   - 1668×2420 (also accepted for 11" class)

---

## Apple Watch Screenshots

| Display Size | Device Examples | Size (W×H) |
|-------------|----------------|-------------|
| 49mm | Apple Watch Ultra 2 | 410×502 |
| 45mm | Apple Watch Series 9 (45mm) | 396×484 |
| 44mm | Apple Watch Series 6/SE (44mm) | 368×448 |
| 41mm | Apple Watch Series 9 (41mm) | 352×430 |
| 40mm | Apple Watch Series 6/SE (40mm) | 324×394 |

---

## Apple TV Screenshots

| Size (W×H) |
|-------------|
| 1920×1080 |
| 3840×2160 (4K) |

---

## Mac Screenshots

| Size | Notes |
|------|-------|
| 1280×800 minimum | For Mac App Store |
| 2880×1800 | Retina MacBook Pro |
| Up to 3840×2160 | Max supported |

---

## App Preview Videos

| Device Class | Resolution | Duration |
|-------------|-----------|----------|
| iPhone 6.7" | 1290×2796 | 15-30 sec |
| iPhone 6.5" | 1242×2688 | 15-30 sec |
| iPhone 5.5" | 1242×2208 | 15-30 sec |
| iPad Pro 12.9" | 2048×2732 | 15-30 sec |
| iPad Pro 11" | 1668×2388 | 15-30 sec |

- **Format**: H.264, AAC audio
- **FPS**: 30 fps
- **Max file size**: 500 MB
- Up to 3 preview videos per locale

---

## General Rules

1. **Minimum screenshots**: 1 per supported device class
2. **Maximum screenshots**: 10 per device class per locale
3. **Formats**: PNG or JPEG (PNG recommended for quality)
4. **Status bar**: Apple may reject if status bar shows inappropriate content
5. **Safe margins**: Keep critical text/elements away from edges (~5% margin)
6. **Orientation**: Must match your app's supported orientations
7. **First 3 matter most**: These appear in search results — lead with your strongest
