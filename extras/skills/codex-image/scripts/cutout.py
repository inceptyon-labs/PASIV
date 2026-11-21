#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pillow",
#     "numpy",
#     "scipy",
# ]
# ///
"""
Remove a solid chroma-key background from an image and write a true RGBA PNG.

Usage:
    uv run cutout.py --input raw.png --output icon.png --chroma green
    uv run cutout.py --input raw.png --output icon.png --chroma magenta
    uv run --with rembg cutout.py --input photo.png --output cut.png --rembg
"""

import argparse
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, binary_erosion

CHROMA_COLORS = {
    "green": {"hue_center": 120, "hue_range": 25, "sat_min": 0.55, "val_min": 0.55},
    "magenta": {"hue_center": 300, "hue_range": 25, "sat_min": 0.55, "val_min": 0.55},
}


def remove_chroma_background(image: Image.Image, chroma: str) -> Image.Image:
    """Make pixels matching the chroma color transparent using an HSV mask."""
    color = CHROMA_COLORS[chroma]
    img = np.array(image.convert("RGB")).astype(np.float64)
    r, g, b = img[:, :, 0] / 255.0, img[:, :, 1] / 255.0, img[:, :, 2] / 255.0

    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    hue = np.zeros_like(delta)
    mask_r = (cmax == r) & (delta > 0)
    mask_g = (cmax == g) & (delta > 0)
    mask_b = (cmax == b) & (delta > 0)
    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6)
    hue[mask_g] = 60.0 * (((b[mask_g] - r[mask_g]) / delta[mask_g]) + 2)
    hue[mask_b] = 60.0 * (((r[mask_b] - g[mask_b]) / delta[mask_b]) + 4)

    sat = np.where(cmax > 0, delta / np.where(cmax > 0, cmax, 1), 0)
    val = cmax

    low = (color["hue_center"] - color["hue_range"]) % 360
    high = (color["hue_center"] + color["hue_range"]) % 360
    if low < high:
        hue_mask = (hue >= low) & (hue <= high)
    else:
        hue_mask = (hue >= low) | (hue <= high)

    chroma_mask = hue_mask & (sat >= color["sat_min"]) & (val >= color["val_min"])

    # Grow then shrink the opaque area to close pinholes and smooth edges.
    opaque = ~chroma_mask
    opaque = binary_dilation(opaque, iterations=2)
    opaque = binary_erosion(opaque, iterations=2)
    alpha = np.where(opaque, 255, 0).astype(np.uint8)

    return Image.fromarray(np.dstack([img.astype(np.uint8), alpha]), "RGBA")


def remove_background_rembg(image: Image.Image) -> Image.Image:
    try:
        from rembg import remove
    except ImportError:
        print("Error: rembg not available. Run with: uv run --with rembg cutout.py ...", file=sys.stderr)
        sys.exit(1)
    return remove(image)


def main() -> None:
    parser = argparse.ArgumentParser(description="Remove an image background and save an RGBA PNG.")
    parser.add_argument("--input", required=True, help="Image generated on a chroma-key background")
    parser.add_argument("--output", required=True, help="Output PNG path")
    method = parser.add_mutually_exclusive_group(required=True)
    method.add_argument("--chroma", choices=sorted(CHROMA_COLORS), help="Background color to key out")
    method.add_argument("--rembg", action="store_true", help="ML background removal for photos and detailed scenes")
    args = parser.parse_args()

    image = Image.open(args.input)
    result = remove_background_rembg(image) if args.rembg else remove_chroma_background(image, args.chroma)
    result.save(args.output, "PNG")

    alpha = np.array(result.getchannel("A"))
    clear = float((alpha == 0).mean()) * 100
    print(f"Saved {args.output} ({result.width}x{result.height}, {clear:.1f}% transparent)")
    if clear < 5:
        print("Warning: almost nothing was removed; the background may not match the chroma color.", file=sys.stderr)


if __name__ == "__main__":
    main()
