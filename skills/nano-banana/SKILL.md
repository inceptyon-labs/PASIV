---
name: nano-banana
description: Nano Banana image generation skill. Also known as "nano banana", "nano-banana", "nano banana pro", "nano-banana-pro", "banana". Use this skill when the user asks to "generate an image", "create an image", "make an image", "generate images", "nano banana", "use nano banana", or requests icons/logos/graphics with transparency. Generates images using Google's Gemini models (Nano Banana = Gemini 2.5 Flash, Nano Banana 2 = Gemini 3.1 Flash, Nano Banana Pro = Gemini 3 Pro). Invoke for ANY image generation request. When the image needs transparency (icons, logos, overlays, alpha channel, transparent background, background removal), use the --transparent flag.
---

# Image Generation with Transparency Support

Generate custom images using Google's Gemini models with optional chroma key background removal for transparent PNGs.

## Prerequisites

Set the `GEMINI_API_KEY` environment variable with your Google AI API key.

## Available Models

| Model | Flag | ID | Best For | Max Resolution |
|-------|------|----|----------|----------------|
| **Nano Banana** | `--model banana` | `gemini-2.5-flash-image` | Speed, high-volume, low-latency tasks | 1024px |
| **Nano Banana 2** | `--model banana2` | `gemini-3.1-flash-image-preview` | High-efficiency, balanced quality/speed | 1024px |
| **Nano Banana Pro** | `--model pro` | `gemini-3-pro-image-preview` | Professional assets, complex instructions, high-fidelity text rendering (uses Thinking) | Up to 4K |

### Model Selection Guide

- **banana** (default): Fastest. Use for quick iterations, bulk generation, backgrounds, textures.
- **banana2**: Better quality than banana at similar speed. Use for polished icons, UI assets, illustrations.
- **pro**: Highest quality. Use for final production assets, hero images, logos with text, complex scenes. Supports `--size 2K/4K`.

## Image Generation Workflow

### Step 1: Generate the Image

Use `scripts/image.py` with uv. The script is located at `skills/generate/scripts/image.py`:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Your image description" \
  --output "/path/to/output.png"
```

Where `${SKILL_DIR}` is the directory containing this SKILL.md file.

### Core Options

- `--prompt` (required): Detailed description of the image to generate
- `--output` (required): Output file path (PNG format)
- `--aspect` (optional): Aspect ratio - "square", "landscape", "portrait" (default: square)
- `--reference` (optional, repeatable): Path to reference image(s) for style guidance
- `--model` (optional): "banana" (fast), "banana2" (efficient), or "pro" (high-quality) (default: banana)
- `--size` (optional): Resolution for pro model - "1K", "2K", "4K" (default: 1K, only applies to pro)

### Transparency Options

- `--transparent`: Generate with chroma key background, then remove it for a true RGBA PNG
- `--chroma` (optional): Force chroma color - "green" or "magenta" (default: auto-detect based on prompt)
- `--rembg`: Use ML-based background removal (rembg library) instead of chroma key

## When to Use Transparency

Use `--transparent` whenever the image needs:
- **Icons** for web/app UI (nav icons, feature icons, social icons)
- **Logos** that sit on varied backgrounds
- **Overlays** composited on top of other content
- **Stickers/badges** with no background
- Any image where the caller mentions: alpha channel, transparent, no background, PNG with transparency, overlay, cutout

### Transparent Icon Example

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A minimalist settings gear icon, flat design, single color dark gray" \
  --output "/path/to/icon-settings.png" \
  --transparent
```

### Transparent Logo Example

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Modern tech startup logo, letter P with circuit board patterns, blue and white" \
  --output "/path/to/logo.png" \
  --transparent \
  --model pro
```

### Green Subject (Auto-detects Magenta Chroma)

When the subject contains green, the script auto-selects magenta chroma key to avoid color conflicts:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A green leaf sustainability icon" \
  --output "/path/to/leaf-icon.png" \
  --transparent
```

You can also force the chroma color explicitly:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Nature-themed logo with trees" \
  --output "/path/to/nature-logo.png" \
  --transparent --chroma magenta
```

### ML-Based Background Removal (rembg)

For complex images where chroma key may not be ideal (photographs, detailed scenes), use `--rembg`:

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Professional headshot illustration" \
  --output "/path/to/headshot.png" \
  --rembg
```

Note: `--rembg` requires the rembg package installed separately (`pip install rembg`). It downloads the BiRefNet model on first use.

## How Chroma Key Transparency Works

1. **Prompt augmentation**: The script adds instructions for a solid uniform chroma key background (#00FF00 green or #FF00FF magenta) with a white outline around the subject
2. **Color detection**: After generation, HSV color masking identifies and removes the chroma background pixels
3. **Edge cleanup**: Morphological operations (dilation + erosion) clean up anti-aliased edges
4. **RGBA output**: The final image is saved as a proper RGBA PNG with alpha transparency

## Using Different Models

**Nano Banana (default)** - Fastest, bulk work:
```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A minimalist logo design" \
  --output "/path/to/logo.png"
```

**Nano Banana 2** - Better quality, still fast:
```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Polished app icon with subtle gradients" \
  --output "/path/to/icon.png" \
  --model banana2
```

**Nano Banana Pro** - Highest quality for final assets:
```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "A detailed hero illustration for a tech landing page" \
  --output "/path/to/hero.png" \
  --model pro --size 2K
```

## Using Reference Images

```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Create a similar abstract pattern with warmer colors" \
  --output "/path/to/output.png" \
  --reference "/path/to/reference.png"
```

Multiple references:
```bash
uv run "${SKILL_DIR}/scripts/image.py" \
  --prompt "Combine the color palette of the first image with the composition of the second" \
  --output "/path/to/output.png" \
  --reference "/path/to/style-ref.png" \
  --reference "/path/to/composition-ref.png"
```

## Integration with Frontend Code

**Transparent icons/logos (RGBA PNG):**
```html
<img src="./icon-settings.png" alt="Settings" class="icon" />
```

**Hero images (opaque):**
```css
.hero-section {
  background-image: url('./generated-hero.png');
  background-size: cover;
}
```

## Crafting Effective Prompts

### Prompt Elements

1. **Subject**: What the image depicts
2. **Style**: Artistic style (minimalist, abstract, photorealistic, illustrated, flat)
3. **Colors**: Specific palette matching the design system
4. **Mood**: Atmosphere (professional, playful, elegant, bold)
5. **Context**: How it will be used (hero image, icon, texture, logo)

### Icon/Logo Prompt Tips

For best transparency results, include in your prompt:
- "flat design" or "minimalist" for clean edges
- Specific colors for the subject (avoid mentioning background)
- "centered" composition
- "sharp edges" and "clean lines"
- Avoid gradients or glows that blend into the background

## Output Location

Save generated images to the project's assets directory:
- `./assets/` for simple HTML projects
- `./src/assets/` or `./public/` for React/Vue projects
- Use descriptive filenames: `hero-abstract-gradient.png`, `icon-settings.png`, `logo-main.png`
