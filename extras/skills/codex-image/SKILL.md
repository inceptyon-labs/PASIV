---
name: codex-image
description: Image generation through the Codex CLI's built-in image tool. Use for "generate/create/make an image", icons, logos, graphics, illustrations, textures. Supports transparent PNG output (icons, overlays, cutouts) by generating on a chroma-key background and removing it locally.
model: sonnet
---

# Image generation with Codex

Codex CLI renders the image with its native image generation tool; this skill writes the prompt,
runs `codex exec`, and optionally removes the background with `${SKILL_DIR}/scripts/cutout.py`.
`${SKILL_DIR}` is the directory containing this SKILL.md.

## Prerequisites

- `codex` on PATH and signed in. Check `codex features list | grep image_generation` shows
  `true`. If not, stop and tell the user.
- `uv` on PATH for transparent output (`brew install uv`).

Call the CLI directly. Do not use a Codex MCP wrapper: those return text only and time out on
long prompts.

## Generate

```bash
codex exec --skip-git-repo-check --ephemeral -C "<output-dir>" \
  "Use your image generation tool to create one image and save it to <absolute-output-path> — <prompt>. Do nothing else."
```

- Use an absolute output path inside `<output-dir>` so the write stays in Codex's workspace.
- Put the aspect in the prompt: "Square image", "Landscape image" or "Portrait image".
- Reference images: add `-i /path/to/ref.png` (repeatable) and say in the prompt how to use them
  ("match the style of the attached image").
- Each call takes about 30 seconds. For several images, run one call per image as parallel
  background commands.
- Codex keeps every render in `~/.codex/generated_images/<session>/`. If it reports it could not
  write the output file, copy the newest PNG from there.
- Confirm the file exists, then Read it to check the result before reporting.

## Transparent output

Use this for icons, logos on varied backgrounds, overlays, stickers and badges, or whenever the
request mentions alpha, transparent, no background, cutout or overlay.

1. Pick the chroma color: `green` by default, `magenta` when the subject is green (leaf, plant,
   grass, frog, emerald, lime, mint, olive, cactus and similar).
2. Generate to a temporary `raw.png` with this appended to the prompt (shown for green; swap in
   magenta and `#FF00FF` / RGB 255, 0, 255):

   > Place the subject on a solid, flat, uniform chromakey green background. Use EXACTLY hex
   > color #00FF00 (RGB 0, 255, 0) for the background. NO outline, border, or glow around the
   > subject. NO GREEN ON THE SUBJECT. SHARP EDGES directly against the background. Center the
   > subject. The background must be completely uniform green with zero gradients or shadows.

3. Key it out:

   ```bash
   uv run "${SKILL_DIR}/scripts/cutout.py" --input raw.png --output icon.png --chroma green
   ```

   For photographs or detailed scenes where a chroma key leaves fringes, use ML removal instead
   (downloads a model on first use):

   ```bash
   uv run --with rembg "${SKILL_DIR}/scripts/cutout.py" --input raw.png --output cut.png --rembg
   ```

4. The script prints the transparent percentage and warns when almost nothing was removed, which
   means the background did not match. Regenerate with a stricter prompt rather than loosening
   the key. Delete `raw.png` afterwards.

## Writing the prompt

Include the subject, style (minimalist, flat, illustrated, photorealistic), specific colors from
the project's design system, mood, and where the image will be used (hero, icon, texture, logo).

For clean transparency: "flat design" or "minimalist", specific subject colors, "centered",
"sharp edges", "clean lines", and no gradients or glows that blend into the background.

## Output location

Save into the project's assets directory: `./assets/` for plain HTML, `./src/assets/` or
`./public/` for React/Vue. Use descriptive filenames such as `hero-abstract-gradient.png`,
`icon-settings.png`, `logo-main.png`.
