# README Section Header Icons

Avoid emoji in section headers; use Lucide SVGs served via the [Iconify](https://iconify.design/) CDN. Why:

- **Theme-neutral.** A fixed hex color renders the same on GitHub's light and dark themes. Emoji rendering varies by OS (Apple/Win/Linux) and looks inconsistent across the user base.
- **Professional voice.** Major OSS projects (React, Tauri, Tailwind) don't use emoji in section headers — icons read as "indie shop with taste," emoji reads as "personal weekend project."
- **Consistent with the in-app icon set.** Most projects that have a UI already use Lucide (or could). The README icons then match the app's visual vocabulary.
- **One-line per icon, no SVG files in the repo.** No `.github/icons/*.svg` to maintain.

**Pattern:**

```markdown
## <img src="https://api.iconify.design/lucide/sparkles.svg?color=%238B5CF6&height=22" align="absmiddle" /> Section Title
```

- **Service**: `api.iconify.design/{prefix}/{name}.svg` — supports Lucide, Heroicons, Phosphor, Material, Tabler, ~150 sets. Stick to one set per README; default Lucide.
- **`color`**: URL-encode the `#`. Pick one accent color matching the project's brand (button color, logo accent). Default `%238B5CF6` (violet-500) reads well on both themes.
- **`height`**: 22 for `##` headers, 24 for top-level visual sections. Width auto-scales.
- **`align="absmiddle"`**: vertically centers the icon with the header text on GitHub.
- **Do NOT use `currentColor`** — `lucide-static` SVGs default to stroke="currentColor" which renders dark-on-dark in GitHub's dark mode (invisible). Iconify's `?color=` param resolves this.

**Icon-to-section cheat sheet** (use as starting point; pick what fits the actual content):

| Section | Lucide icon name |
|---|---|
| Features / Overview | `sparkles` |
| Quick Start / Install | `rocket` |
| Tech Stack | `boxes` |
| Project Structure | `folder-tree` |
| Usage | `compass` or `book-open` |
| Configuration | `settings-2` |
| API | `terminal` |
| Devices / Platforms | `smartphone` |
| Backgrounds / Design | `palette` |
| Typography | `type` |
| Images / Media | `image-plus` |
| Layout | `layout-grid` |
| Storage / Data | `database` |
| Export / Download | `download` |
| AI / Generation | `sparkles` or `wand-sparkles` |
| Providers / Plugins | `blocks` |
| Brand / Context | `folder-heart` |
| Editor / Interaction | `mouse-pointer-2` |
| Contributing | `users` or `heart-handshake` |
| License | `scale` |
| Acknowledgments | `heart` |
| Contact | `mail` |
| Security | `shield` |

Verify a chosen icon exists by hitting `https://api.iconify.design/lucide/<name>.svg` once before writing it in. (Iconify returns 404 for unknown names, so a broken icon shows as a broken `<img>` tag in the rendered README.)
