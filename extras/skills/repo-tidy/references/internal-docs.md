# Internal docs

Goal: git tracks only docs written for someone who uses, installs, configures or contributes to
the project as it ships. Docs about how it was planned, decided, built or audited stay on disk,
gitignored. Private repos follow the same rule: a private repo can go public later, and its
history goes with it.

## 1. Sort each doc by its reader

**Public (stays tracked):**
- Root community files: README, LICENSE, CHANGELOG, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT
- Usage docs: install, getting started, user guides, how-tos, FAQ, configuration, CLI or API
  reference for consumers, troubleshooting, upgrade guides, docs-site trees
- Pages something outside the repo links to: PRIVACY.md, TERMS.md, support pages
- Package READMEs in a monorepo
- Docs about the shipped system that a contributor needs: ARCHITECTURE.md, an API schema,
  `docs/architecture.json` (the Archify spec)
- Agent files (AGENTS.md, CLAUDE.md, GEMINI.md, WARP.md, `.cursorrules`): tracking them is the
  `de-vibe --gitignore` decision, not this check

**Internal (untrack and gitignore):**
- PASIV output: `docs/handoffs/`, `docs/tasks/`, `docs/designs/` (brainstorm), `docs/metrics/`,
  `docs/scans/` (repo-scan, fable-audit), `docs/app-store-ready/`, `docs/archive/`, `.beans/`
- Planning and decisions: specs, PRDs, plans (`docs/plans/`, `docs/superpowers/`), design
  notes, RFCs, ADRs (`adr/`, `docs/decisions/`), roadmaps, research, meeting notes
- Work in flight: TODO.md, NOTES.md, HANDOFF*.md, PLAN*.md, scratch files
- Audit, review and run reports: security scans, code-review output, perf runs, token metrics
- Product and design-tool inputs: DESIGN.md, PRODUCT.md, `docs/design-system*`. impeccable,
  design-pipeline and `/kick` read them from the working copy, so they keep working untracked
- Runbooks for the maintainer's own infrastructure (deploying to their own server, recovery
  steps that name hosts). A self-hosting guide written for users is public.

**Not a doc:** a file that code, config, CI, a build or a skill reads at runtime is an input,
whatever its extension, including files a tool reads by convention (`fastlane/metadata/`,
`.github/`). It stays tracked. So does a Markdown file that is the product (a skill, a slash
command, a prompt, a template). Mixed docs (a user guide with a planning section) stay tracked;
list the section as a follow-up instead of cutting it. When the reader test doesn't settle a
doc, leave it tracked and list it as `unsure: <path> (<why>)`.

## 2. Find candidates

```bash
git ls-files | grep -iE '(\.(md|mdx|markdown|txt|rst|adoc|pdf|docx?)|/\.gitkeep)$' | grep -vE '^(fastlane|\.github)/' \
  | grep -iE '(^|/)(docs/(handoffs|tasks|designs|metrics|scans|app-store-ready|archive|plans|superpowers|specs|decisions|adr|rfcs|prds?|research|notes|planning|brainstorms?)/|(specs|adr|rfcs|planning|notes|handoffs?|research)/|\.beans/)|(^|/)(TODO|NOTES|HANDOFF|PLAN|ROADMAP|PRD|SPEC|DESIGN|PRODUCT|BRAINSTORM|DECISIONS?|RESEARCH)[^/]*$'
```

A path match is a candidate, not a verdict: read its first 30 lines and apply section 1
(`docs/reference/design-system.md` can be a user reference). Then read the first 30 lines of
every other tracked doc the pattern missed and sort those too; the filename doesn't decide.

## 3. Untrack and ignore

1. For each internal doc, `git grep -n -F '<path>' -- ':!*.md' ':!*.mdx'`. A hit in code,
   config, CI or a skill makes it an input (section 1): keep it tracked and say why.
2. Append the rules to `.gitignore` under `# Internal docs (kept local by repo-tidy)`: the folder
   for a folder (`docs/designs/`), an anchored path for a single file (`/NOTES.md`). No broad
   patterns like `*.md`. When `.pasiv.yml` exists, also add every PASIV output folder from
   section 1 that isn't covered yet, existing or not, so `/acp` never sweeps a future handoff or
   scan into a commit.
3. `git rm -r --cached -q <path>` for each. The working copy stays.
4. Links: a tracked doc that links to a now-untracked one 404s on GitHub. `md-links.py` reports
   it as `links to untracked file`. Replace the link with plain text, or drop the sentence if it
   only pointed there. Never re-track the target to fix a link. A prose mention of a folder
   (README: "brainstorm writes to `docs/designs/`") is fine.

Already on disk but untracked and unignored (the next `/acp` would add them): add the ignore
rule, nothing else.

## 4. History

Untracking changes the next commit. Earlier commits keep the files:

```bash
git log --oneline --all -- <internal paths> | wc -l
```

- **Already public:** the docs are readable in history now. Say so and leave history alone. If
  one holds something the user would not publish (client names, private infrastructure,
  unreleased plans), offer the purge in `references/going-public.md` section 1. It rewrites
  history and needs a force push, so ask first.
- **Going public now** (first push to Public, or a visibility flip): the push publishes that
  history. Offer the squash from `references/going-public.md` section 1. Untrack first, so the
  orphan commit's index doesn't carry the docs.
- **Private:** report the count only.

## 5. Report

Summary line: `**Untracked (internal, kept on disk):** docs/designs/ (4), docs/archive/ (2),
NOTES.md; .gitignore +3 rules; 2 links unlinked; in 17 commits of history`. List each
`unsure:` doc and each input kept tracked under follow-ups.

Under `--report`: print what would be untracked and why, the rules that would be added, the
links that would change and the history count. Touch nothing.
