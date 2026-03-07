#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "google-genai",
#     "pillow",
#     "numpy",
#     "scipy",
# ]
# ///
"""
Generate images using Google's Gemini image models with optional transparent background support.

Usage:
    uv run image.py --prompt "A colorful abstract pattern" --output "./hero.png"
    uv run image.py --prompt "App logo" --output "./logo.png" --transparent
    uv run image.py --prompt "Green leaf icon" --output "./leaf.png" --transparent --chroma magenta
    uv run image.py --prompt "Complex photo cutout" --output "./cut.png" --rembg
    uv run image.py --prompt "High quality art" --output "./art.png" --model pro --size 2K
"""

import argparse
import os
import sys

import numpy as np
from google import genai
from google.genai import types
from PIL import Image
from scipy.ndimage import binary_dilation, binary_erosion

MODEL_IDS = {
    "flash": "gemini-2.5-flash-image",
    "pro": "gemini-3-pro-image-preview",
}

CHROMA_COLORS = {
    "green": {
        "hex": "#00FF00",
        "rgb": "(0, 255, 0)",
        "hue_center": 120,
        "hue_range": 25,
        "sat_min": 0.55,
        "val_min": 0.55,
    },
    "magenta": {
        "hex": "#FF00FF",
        "rgb": "(255, 0, 255)",
        "hue_center": 300,
        "hue_range": 25,
        "sat_min": 0.55,
        "val_min": 0.55,
    },
}


def get_aspect_instruction(aspect: str) -> str:
    aspects = {
        "square": "Generate a square image (1:1 aspect ratio).",
        "landscape": "Generate a landscape/wide image (16:9 aspect ratio).",
        "portrait": "Generate a portrait/tall image (9:16 aspect ratio).",
    }
    return aspects.get(aspect, aspects["square"])


def build_chroma_prompt(prompt: str, chroma: str) -> str:
    color = CHROMA_COLORS[chroma]
    return (
        f"{prompt} "
        f"Place the subject on a solid, flat, uniform chromakey {chroma} background. "
        f"Use EXACTLY hex color {color['hex']} (RGB {color['rgb']}) for the background. "
        f"The subject must have a clean white outline/border (2-3 pixels wide) separating it from the background. "
        f"NO {chroma.upper()} ON THE SUBJECT. SHARP EDGES. Center the subject. "
        f"The background must be completely uniform {chroma} with zero gradients or shadows."
    )


def remove_chroma_background(image: Image.Image, chroma: str) -> Image.Image:
    """Remove chroma key background using HSV color masking."""
    color = CHROMA_COLORS[chroma]
    img_array = np.array(image.convert("RGB")).astype(np.float64)

    # Normalize to 0-1
    r, g, b = img_array[:, :, 0] / 255.0, img_array[:, :, 1] / 255.0, img_array[:, :, 2] / 255.0

    # Compute HSV
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    # Hue (0-360)
    hue = np.zeros_like(delta)
    mask_r = (cmax == r) & (delta > 0)
    mask_g = (cmax == g) & (delta > 0)
    mask_b = (cmax == b) & (delta > 0)
    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6)
    hue[mask_g] = 60.0 * (((b[mask_g] - r[mask_g]) / delta[mask_g]) + 2)
    hue[mask_b] = 60.0 * (((r[mask_b] - g[mask_b]) / delta[mask_b]) + 4)

    # Saturation (0-1)
    sat = np.where(cmax > 0, delta / cmax, 0)

    # Value (0-1)
    val = cmax

    # Build chroma mask
    hue_center = color["hue_center"]
    hue_range = color["hue_range"]
    hue_low = (hue_center - hue_range) % 360
    hue_high = (hue_center + hue_range) % 360

    if hue_low < hue_high:
        hue_mask = (hue >= hue_low) & (hue <= hue_high)
    else:
        hue_mask = (hue >= hue_low) | (hue <= hue_high)

    chroma_mask = hue_mask & (sat >= color["sat_min"]) & (val >= color["val_min"])

    # Create alpha channel (255 = opaque, 0 = transparent)
    alpha = np.where(chroma_mask, 0, 255).astype(np.uint8)

    # Morphological cleanup: dilate alpha (grow opaque area) then erode to clean edges
    opaque = alpha > 0
    opaque = binary_dilation(opaque, iterations=2)
    opaque = binary_erosion(opaque, iterations=2)
    alpha = np.where(opaque, 255, 0).astype(np.uint8)

    # Compose RGBA
    rgba = np.dstack([img_array.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def remove_background_rembg(image: Image.Image) -> Image.Image:
    """Remove background using rembg library (ML-based)."""
    try:
        from rembg import remove
    except ImportError:
        print(
            "Error: rembg not installed. Install with: pip install rembg[gpu] or pip install rembg",
            file=sys.stderr,
        )
        sys.exit(1)

    return remove(image)


def detect_green_in_prompt(prompt: str) -> bool:
    """Heuristic: check if the prompt likely describes a green subject."""
    green_words = [
        "green", "emerald", "lime", "forest", "jade", "mint", "olive",
        "leaf", "leaves", "tree", "plant", "grass", "nature", "frog",
        "shamrock", "clover", "cactus", "succulent", "avocado",
    ]
    prompt_lower = prompt.lower()
    return any(word in prompt_lower for word in green_words)


def generate_image(
    prompt: str,
    output_path: str,
    aspect: str = "square",
    references: list[str] | None = None,
    model: str = "flash",
    size: str = "1K",
    transparent: bool = False,
    chroma: str | None = None,
    use_rembg: bool = False,
) -> None:
    """Generate an image using Gemini and save to output_path."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    # Auto-select chroma color if transparent and no explicit choice
    if transparent and not chroma:
        chroma = "magenta" if detect_green_in_prompt(prompt) else "green"
        print(f"Auto-selected chroma key: {chroma}")

    aspect_instruction = get_aspect_instruction(aspect)
    full_prompt = f"{aspect_instruction} {prompt}"

    if transparent:
        full_prompt = build_chroma_prompt(full_prompt, chroma)

    # Build contents with optional reference images
    contents: list = []
    if references:
        for ref_path in references:
            if not os.path.exists(ref_path):
                print(f"Error: Reference image not found: {ref_path}", file=sys.stderr)
                sys.exit(1)
            contents.append(Image.open(ref_path))
        if len(references) == 1:
            full_prompt = f"{full_prompt} Use the provided image as a reference for style, composition, or content."
        else:
            full_prompt = f"{full_prompt} Use the provided {len(references)} images as references for style, composition, or content."
    contents.append(full_prompt)

    model_id = MODEL_IDS[model]

    if model == "pro":
        aspect_ratios = {"square": "1:1", "landscape": "16:9", "portrait": "9:16"}
        config = types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(
                aspect_ratio=aspect_ratios.get(aspect, "1:1"),
                image_size=size,
            ),
        )
        response = client.models.generate_content(
            model=model_id, contents=contents, config=config
        )
    else:
        response = client.models.generate_content(
            model=model_id, contents=contents
        )

    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Extract image from response
    for part in response.parts:
        if part.text is not None:
            print(f"Model response: {part.text}")
        elif part.inline_data is not None:
            image = part.as_image()

            if transparent:
                print(f"Removing {chroma} chroma key background...")
                image = remove_chroma_background(image, chroma)
                print("Background removed, saving as RGBA PNG.")
            elif use_rembg:
                print("Removing background with rembg (ML-based)...")
                image = remove_background_rembg(image)
                print("Background removed, saving as RGBA PNG.")

            image.save(output_path)
            print(f"Image saved to: {output_path}")
            return

    print("Error: No image data in response", file=sys.stderr)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Generate images using Gemini (Flash or Pro) with optional transparency"
    )
    parser.add_argument(
        "--prompt", required=True, help="Description of the image to generate"
    )
    parser.add_argument(
        "--output", required=True, help="Output file path (PNG format)"
    )
    parser.add_argument(
        "--aspect",
        choices=["square", "landscape", "portrait"],
        default="square",
        help="Aspect ratio (default: square)",
    )
    parser.add_argument(
        "--reference",
        action="append",
        dest="references",
        help="Path to a reference image (can be specified multiple times)",
    )
    parser.add_argument(
        "--model",
        choices=["flash", "pro"],
        default="flash",
        help="Model: flash (fast, 1024px) or pro (high-quality, up to 4K) (default: flash)",
    )
    parser.add_argument(
        "--size",
        choices=["1K", "2K", "4K"],
        default="1K",
        help="Image resolution for pro model (default: 1K, ignored for flash)",
    )
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Generate with chroma key background then remove it for transparency",
    )
    parser.add_argument(
        "--chroma",
        choices=["green", "magenta"],
        default=None,
        help="Chroma key color (default: auto-detect, green unless subject is green)",
    )
    parser.add_argument(
        "--rembg",
        action="store_true",
        dest="use_rembg",
        help="Use ML-based background removal (rembg) instead of chroma key",
    )

    args = parser.parse_args()
    generate_image(
        args.prompt,
        args.output,
        args.aspect,
        args.references,
        args.model,
        args.size,
        args.transparent,
        args.chroma,
        args.use_rembg,
    )


if __name__ == "__main__":
    main()
