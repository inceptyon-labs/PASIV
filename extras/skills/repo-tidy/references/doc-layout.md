# Doc layout (Phase 4b)

Goal: project docs live together under `docs/`, grouped when there are enough of them, with
every link still working. This moves tracked docs only: internal docs were untracked in Phase 3b
(`references/internal-docs.md`) and stay where they are on disk. It never moves code, and it
doesn't rename files except to resolve a collision.

## 1. What stays where it is

**Root files that GitHub, package registries or tools look for at the root:** `README*`,
`LICENSE*`, `CHANGELOG*`, `CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*`, agent files
(`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `WARP.md`, `.cursorrules`, `.windsurfrules`), `DESIGN.md`
and `PRODUCT.md` (impeccable and design-pipeline read them from the root), `llms.txt`. A
duplicated agent file is Phase 3's job (`agents-md`), not a move. A symlink to AGENTS.md is a
pointer, not a duplicate.

**Tool-owned paths:** PASIV reads and writes these at fixed paths, so never move them or
anything inside them: `docs/handoffs/`, `docs/tasks/`, `docs/designs/`, `docs/metrics/`,
`docs/scans/` (repo-scan reports), `docs/app-store-ready/` (its reports),
`docs/design-system*`, `docs/archive/`, `docs/architecture.json`, `.beans/`, `.pasiv.yml`. Most
of these are internal and gitignored by Phase 3b; they still never move. Also
leave `.github/`, `fastlane/`, `.claude/`, and any `node_modules/`, `Pods/`, `vendor/` or build
output.

**Docs-site trees:** if `mkdocs.yml`, `docusaurus.config.*`, `.vitepress/`, `astro.config.*`
with Starlight, or a Jekyll `_config.yml` exists, its content folder is a site with its own
structure. Leave that tree alone and only consider stray docs outside it.

**Package READMEs in a monorepo:** `packages/*/README.md`, `apps/*/README.md` and similar
stay with their package. npm publishes them, and they describe that package.

**Docs referenced by anything other than Markdown:** a doc whose path appears in code,
config, CI, scripts, `package.json` `files`, a skill file, a Dockerfile, or a URL
(`github.com/<owner>/<repo>/blob/<branch>/<path>`, App Store metadata, a website) stays put.
Note it in the summary as "kept in place: referenced by <file>". GitHub doesn't redirect moved
files, so an external URL would break.

## 2. Candidates

Tracked docs only. Specs, plans, notes, roadmaps, ADRs and handoffs are internal and were
untracked in Phase 3b, so they aren't candidates.

- Root-level `*.md` not in the keep list: `ARCHITECTURE.md`, `DEPLOY.md`, `SETUP.md`,
  `USAGE.md`, `API.md`, `TESTING.md`, `RUNBOOK.md`, `FAQ.md`
- Doc folders outside `docs/`: `documentation/`, `guides/`, `wiki/`
- Prose docs dropped inside source trees: a usage or setup doc under `src/`, `lib/`,
  `Sources/`. A short `README.md` explaining that folder's code stays next to the code
- Images and diagrams used only by docs (not by the app or the README header) that sit at the
  root or in a random folder: move to `docs/images/`

Phase 4 runs first, so stale docs are already archived or fixed. Don't move a doc and then
archive it.

## 3. Where they go

- Default: `docs/<lowercase-name>.md` (`ARCHITECTURE.md` → `docs/architecture.md`). Lowercasing
  is the one allowed rename. Skip it if the project's existing `docs/` files use uppercase.
- A whole folder moves as a folder: `guides/` → `docs/guides/`.
- **Group only when it helps.** If `docs/` would have more than about 8 loose files after the
  moves, group them by kind, reusing any subfolders the project already has. Common groups:
  `docs/guides/`, `docs/runbooks/` (deploy, ops, recovery), `docs/reference/` (APIs, schemas,
  configs). Don't invent a taxonomy for three files, and don't split
  a group that has one member.
- Name collision (`docs/notes.md` already exists): keep both by moving the incoming one as
  `docs/notes-<old-folder-or-root>.md` and mention it, or merge only if they're the same doc.

## 4. Moving

1. Build the move list first and check each source against section 1 with
   `git grep -n -F '<path>'` and `git grep -n -F '<basename>'` (without the `.md`). Drop
   anything referenced outside Markdown.
2. `git mv <src> <dst>` for each, so history follows the file.
3. Fix links in both directions:
   - **Links to the moved file** from every other Markdown file (`git grep -n -F '<old path>'`
     and the old relative forms like `../NOTES.md`). Rewrite each to the new relative path.
   - **Links inside the moved file:** its relative links now resolve from a new folder.
     Rewrite every relative link and image path in it.
   - Prose mentions in README and AGENTS.md ("see NOTES.md") get the new path too.
4. Run the link checker on every Markdown file you touched or moved, then on the whole repo:

   ```bash
   python3 "$SKILL_DIR/scripts/md-links.py" <moved and edited files>; python3 "$SKILL_DIR/scripts/md-links.py"
   ```

   Exit 1 lists `file:line: broken link -> target`. Fix every link your moves broke. Links that
   were already broken before the pass go in the summary as follow-ups. Don't guess targets.
5. If the README has a docs section or index, add the moved docs to it. Don't create a new
   index the project never had.

Under `--report`: print the move list (src → dst), what stays and why, and the links that
would change, and touch nothing.

## Summary line

`**Moved:** ARCHITECTURE.md → docs/architecture.md, guides/ → docs/guides/ (7 links updated)`,
plus `kept in place: PRIVACY.md (linked from App Store metadata)` when something was held back.
