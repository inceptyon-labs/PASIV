---
name: nano-banana
description: Image generation via Google Gemini (Nano Banana / Banana 2 / Banana Pro). Use for "generate/create/make an image", "nano banana", icons, logos, graphics. Add `--transparent` for alpha-channel output (icons, overlays, bg removal).
model: sonnet
---

# Image Generation with Transparency Support

Generate images with Google's Gemini models via `${SKILL_DIR}/scripts/image.py` (run with `uv run`). `${SKILL_DIR}` is the directory containing this SKILL.md. Optional chroma key background removal produces true RGBA PNGs.

## Prerequisites

- `GEMINI_API_KEY` must be set. If unset, stop and tell the user to export it (get a key at https://aistudio.google.com/apikey). Do not attempt generation without it.
- `uv` must be on PATH. If missing, report it and suggest `brew install uv`.

## Available Models

| Model | Flag | ID | Best For | Max Resolution |
|-------|------|----|----------|----------------|
| **Nano Banana** | `--model banana` | `gemini-2.5-flash-image` | Speed, high-volume, low-latency tasks | 1024px |
| **Nano Banana 2** | `--model banana2` | `gemini-3.1-flash-image-preview` | High-efficiency, balanced quality/speed | 1024px |
| **Nano Banana Pro** | `--model pro` | `gemini-3-pro-image-preview` | Professional assets, complex instructions, high-fidelity text rendering (uses Thinking) | Up to 4K |

- **banana** (default): Fastest. Quick iterations, bulk generation, backgrounds, textures.
- **banana2**: Better quality at similar speed. Polished icons, UI assets, illustrations.
- **pro**: Highest quality. Final production assets, hero images, logos with text, complex scenes. Supports `--size 2K/4K`.

## Options

### Core

- `--prompt` (required): Detailed description of the image to generate
- `--output` (required): Output file path (PNG format)
- `--aspect` (optional): Aspect ratio - "square", "landscape", "portrait" (default: square)
- `--reference` (optional, repeatable): Path to reference image(s) for style guidance
- `--model` (optional): "banana" (fast), "banana2" (efficient), or "pro" (high-quality) (default: banana)
- `--size` (optional): Resolution for pro model - "1K", "2K", "4K" (default: 1K, only applies to pro)

### Transparency

- `--transparent`: Generate with chroma key background, then remove it for a true RGBA PNG
- `--chroma` (optional): Force chroma color - "green" or "magenta" (default: auto-detect based on prompt; green subjects auto-select magenta)
- `--rembg`: Use ML-based background removal (rembg library) instead of chroma key. Better for photographs/detailed scenes. Requires `pip install rembg`; downloads the BiRefNet model on first use.

## When to Use Transparency

Use `--transparent` for icons, logos on varied backgrounds, overlays, stickers/badges — or whenever the caller mentions: alpha channel, transparent, no background, PNG with transparency, overlay, cutout.

## Examples

Basic text-to-image:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A minimalist logo design" \
  --output "/path/to/logo.png"
```

Transparent icon:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A minimalist settings gear icon, flat design, single color dark gray" \
  --output "/path/to/icon-settings.png" \
  --transparent
```

High-quality generation from a reference image:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Create a similar abstract pattern with warmer colors" \
  --output "/path/to/output.png" \
  --model pro --size 2K \
  --reference "/path/to/reference.png"
```

## Crafting Effective Prompts

Include: subject, style (minimalist, abstract, photorealistic, illustrated, flat), specific colors matching the design system, mood (professional, playful, elegant, bold), and usage context (hero image, icon, texture, logo).

For best transparency results:
- "flat design" or "minimalist" for clean edges
- Specific colors for the subject (avoid mentioning background)
- "centered" composition
- "sharp edges" and "clean lines"
- Avoid gradients or glows that blend into the background

## Output Location

Save to the project's assets directory:
- `./assets/` for simple HTML projects
- `./src/assets/` or `./public/` for React/Vue projects
- Descriptive filenames: `hero-abstract-gradient.png`, `icon-settings.png`, `logo-main.png`
