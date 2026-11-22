---
name: repo-tidy
description: Get a repo ready for its first push, or bring an existing one back in line. First push - README, LICENSE, CONTRIBUTING, SECURITY, CHANGELOG, .github templates, Dependabot, secret gate, gh repo create, going public. Both modes untrack and gitignore internal docs (specs, PRDs, plans, designs, decisions, handoffs, scans). Upkeep - verify the README against disk, audit AGENTS.md, archive stale docs, gather docs into docs/, remove proven-dead files, flag unused assets and clutter, check the deployment standard, GitHub security settings and Scorecard, refresh the Archify diagram, logo, TARS record, memex wiki and Claude memory, then commit. Use for "repo ready", "prep for github", "first push", "make this repo public", "tidy repo", "repo tidy", "clean up this repo", "bring this project up to date", "housekeeping pass", "is this repo current".
model: opus
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# Repo Tidy

One skill for a repo's whole life on your machine, in two modes:

- **First push** (`ready`): prepare an unpublished project, write the community and security
  files, and print (then offer to run) the `gh repo create` or bare-SSH setup. Never commits.
  Flow: `references/first-push.md`.
- **Upkeep** (`tidy`): a maintenance pass over a project that already ships. Compare every claim
  to disk and fix the claim or the disk, then commit with `/acp`. Flow: `references/upkeep.md`.

Security vetting of someone else's code is a different skill (`repo-scan`): it never runs the
target's code, and this one builds and installs.

**Input:** $ARGUMENTS — an optional mode word and flags:
- `ready` / `first push` → first push. `public` / `make public` → first push, including the
  visibility flip of an existing private GitHub repo. `tidy` / `upkeep` → upkeep.
- `--report` (alias `--dry-run`): scan and print the plan, change nothing. Read-only checks still run.
- Upkeep only: `--skip-deploy`, `--skip-diagram`, `--skip-memory`, `--skip-dead-code` (the
  analyzer and build part; the clutter check still runs), `--no-commit` (stop before `/acp`).

## Pick the mode

1. A mode word in the arguments wins. The `repo-ready` alias passes `ready`.
2. Otherwise check the repo:
   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null && git remote -v && git ls-remote --heads origin 2>/dev/null | head -1
   ```
   - Not a git repo: stop and suggest `git init`.
   - No remote, or a remote with no branches yet: ask once with `AskUserQuestion` — **First-push
     prep (Recommended)** | **Upkeep only** (a local-only project that won't be published).
   - A remote with pushed history: upkeep.
3. Read the mode's flow file and follow it from Phase 1. Read the other flow file only if the
   user switches modes partway (first push found an existing remote and they chose upkeep).

`SKILL_DIR` is this skill's own directory: the one that holds this SKILL.md, shown as the skill's base directory when it loads. Scripts and assets live there, not in the project, so always call them by absolute path (`"$SKILL_DIR/scripts/…"`). If you don't know it: `SKILL_DIR=$(ls -d ~/.claude/skills/repo-tidy 2>/dev/null || find ~/.claude/plugins -maxdepth 8 -type d -path '*skills/repo-tidy' 2>/dev/null | sort | tail -1)`.
Every `assets/`, `references/` and `scripts/` path in this skill is relative to it.

## Run report

Every check goes in a ledger, and the run ends by printing it, so the user sees what ran, what
was skipped and why, and what never ran. `RUNLOG` is shorthand for
`bash "$SKILL_DIR/scripts/runlog.sh"`: expand it in every command (shell variables don't carry
between calls) and run it from the project root, which keys the ledger. It lives outside the
repo, so it runs under `--report` too. Each flow file has its own `start` line and check list.
Record each check when it finishes:

- **A tool ran**: take the exit code straight after the tool, before any `echo … exit=$?`, and
  record it on the same command line: `<tool command>; rc=$?; echo "exit=$rc"; RUNLOG ran <check> $rc`.
  The ledger reads the code as ok, findings or couldn't run. Several targets (Dockerfiles,
  analyzers): one `ran` per target, with the target as the detail. A strict-mode gate gets the
  detail `strict`
- **A step with no tool finished** (a phase, an invoked skill): `RUNLOG done <check> "<what changed, or current>"`
- **Deliberately not run**: `RUNLOG skip <check> "<reason>"`

At the end, also when the gate stopped the run: `bash "$SKILL_DIR/scripts/runlog.sh" report`.
Exit 1 means a listed check has no record: run it, or record a skip with the reason, and print
the report again. The report is Markdown: paste it into your final message as-is, not inside a
code block, so the terminal renders the headings and wraps long lines. Tool output doesn't reach
the user on its own.

Tools: `gitleaks` (required for the gate), and `trufflehog`, `zizmor`, `pinact`, `osv-scanner`,
`hadolint`, `scorecard` for the checks that name them
(`brew install gitleaks trufflehog zizmor pinact osv-scanner hadolint scorecard`). A missing one
shows as MISSING on the report's Tools line and as couldn't run on its check; a check that did
not run is never reported as a pass.

## Hard rules

- **Never edit** secrets, `.env*`, signing keys, risk caps, trading or billing config, or
  anything a project's AGENTS.md says agents must not touch. Read AGENTS.md first.
- Each flow file adds its own mode-specific rules at the top.
- **Every change and every archive lands in the final summary.** Git makes repo changes
  reversible; the summary makes them reviewable. Claude memory and the TARS database are outside
  git, so nothing there is removed without a copy or overwritten without being listed.
- **Never commit or push past a failed secret gate.**
- **Match the project's voice.** Terse README stays terse. Don't add sections the project never
  had for the sake of completeness. Every question asked must be one the repo can't answer.

## Shared steps

### Secret gate

```bash
bash "$SKILL_DIR/scripts/secret-gate.sh" "$PWD"; rc=$?; echo "gate exit=$rc"
```

Prefix `SECRET_GATE_BUILTIN=1` (strict mode: the shipped config, and the repo's own
`.gitleaksignore` and `gitleaks:allow` suppressions are not honored) for a public GitHub repo or
a Public destination. It runs gitleaks over every commit on every ref and over everything
uncommitted, lists sensitive filenames (in the tree or deleted but still in history) and tracked
files that are gitignored, and prints locations only, never values. Act on the exit code:

- **0** — clean.
- **1** — secrets found. **Stop**: first push writes nothing more, upkeep doesn't commit. Report
  the locations, then run `bash "$SKILL_DIR/scripts/live-check.sh" "$PWD"` (TruffleHog, own repos
  only) and say which are still live; those get rotated first. Deleting the file is not a fix:
  the key is in history and has to be rotated, then squashed or purged per
  `references/going-public.md` section 1. For a repo that is already public, say the key is
  already exposed. Resume only when the gate passes.
- **2** — could not scan (gitleaks missing, not a repo, shallow clone). Say why. Hard stop for a
  public repo or Public destination. Otherwise first push asks whether to continue unscanned, and
  upkeep continues and says the run is unscanned.
- **3** — no secrets, but files to review. Read each listed file, confirm it holds no live
  credential, and `git rm --cached` the ones that should not be tracked. A file that existed only
  in history still ships with a push. A file you cleared and kept (an `.npmrc` with no token) is
  listed again on every later run; exit 3 with only cleared files counts as a pass.

Don't replace the gate with your own grep, and don't eyeball values in its place.

### Gitleaks setup

Defense in depth: the gate catches what's already committed; the hook prevents future leaks; CI
catches anyone who skipped the hook. Install or upgrade every time, no question needed:

- **Config:** `.gitleaks.toml` missing → copy `assets/gitleaks.toml` (no substitutions). One that
  allowlists `README.md`, `docs/` or another whole directory by path (the older template did) →
  replace its allowlist section with the asset's, keeping any custom `[[rules]]`.
- **Hook:** check for a hook manager first (`git config --get core.hooksPath`, `.husky/`,
  `lefthook.yml`, `.pre-commit-config.yaml`); setting `core.hooksPath` to `.githooks` would turn
  all of those off.
  - A manager is present: leave `core.hooksPath` alone. Copy `assets/pre-commit` to
    `.githooks/gitleaks-staged`, `chmod +x`, and add the line `.githooks/gitleaks-staged` to that
    manager's pre-commit step (husky: `.husky/pre-commit`). A bare `gitleaks` call would miss the
    files gitleaks skips by default.
  - No manager: copy `assets/pre-commit` to `.githooks/pre-commit`, `chmod +x`, and run
    `git config core.hooksPath .githooks`. The setting is per clone, so CONTRIBUTING.md or the
    README documents it for every other clone.
  - A hook from an older template (no `SKIPPED=` line, so a token in a lockfile or an `.svg`
    passes it) → replace it with the asset. Hook present but `core.hooksPath` empty in this
    clone → set it.
- **CI, GitHub only** (first push: every GitHub destination; upkeep: repos that already have
  workflows, so a repo with no Actions doesn't start using minutes): no
  `.github/workflows/gitleaks.yml`, or one that still calls
  `gitleaks detect`, has no `permissions:` block, downloads the binary with no checksum, or lacks
  the "Scan files gitleaks skips by default" step → copy `assets/gitleaks-workflow.yml` over it.
  It installs the MIT-licensed CLI directly; don't swap in `gitleaks/gitleaks-action@v2`, which
  needs a paid license for org repos.
- `command -v gitleaks` missing → say so and suggest `brew install gitleaks`.

### Gitignore

Add the usual misses for the detected stack when absent (`node_modules/`, `dist/`, `build/`,
`.env`, `.DS_Store`, `__pycache__/`, `target/`, `.svelte-kit/`, `.beans/`, `data/*.db*`). An ignore
rule does nothing for a file that is already tracked: `git ls-files -ci --exclude-standard` lists
them, and `git rm --cached <file>` untracks each (the working copy stays). If one ever held a
credential, untracking is not enough: it's still in history, so list it to rotate and purge
(`references/going-public.md` section 1).

### Internal docs

Git tracks only docs for people who use, install, configure or contribute to the shipped
project. Specs, PRDs, plans, designs, decisions, handoffs, task files, scans, audit reports and
archives stay on disk, gitignored, in private repos too. Sort, untrack, fix links and check
history per `references/internal-docs.md`.

### Dockerfiles

`hadolint --no-color <Dockerfile>` for each (`brew install hadolint`; not installed = SKIPPED).
A Dockerfile written in this run: fix every `error` and `warning`. One the project already had:
list each finding with its rule code and leave the file alone, since a change alters the next deploy.

### TARS

Skip silently if `~/.tars/tars.db` doesn't exist. No row for this path → follow
`references/tars-registration.md` (it builds the full schema the app requires). A row exists →
`references/tars-update.md`: correct the fields the manifest contradicts (deploy target and
command, production URL, start command, framework, database, icon path, description), refresh
stale custom fields, keep everything else. Never write `project_secrets`. Warn if the desktop app
is running (`pgrep -fl tars-app || true`); it rereads the row on restart or on reopening the project.

### Logo placement

When the project has a logo (`assets/logo.*`, `.github/logo.*`, `static/logo.*`, `public/logo.*`):
- README header: `<p align="center"><img src="<path>" alt="<name>" width="140"></p>` at the top if absent
- favicon: a `<link rel="icon">` in the web app's HTML shell if it's a web app and has none
- `unraid-icon.png` at the root for Uranus services (512×512; convert with `sips` or
  `rsvg-convert` if only an SVG exists)
- the TARS `icon_path`
