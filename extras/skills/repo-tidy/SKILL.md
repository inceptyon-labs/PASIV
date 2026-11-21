---
name: repo-tidy
description: Bring an existing project back in line - verify the README against disk, audit AGENTS.md, archive or fix stale docs, check the deployment against the house standard, check Dependabot and secret scanning on GitHub repos, create or refresh the Archify architecture diagram, put the logo everywhere, refresh the TARS project record, the memex wiki page and Claude's project memory, then commit. Use for "tidy repo", "repo tidy", "clean up this repo", "bring this project up to date", "housekeeping pass", "is this repo current".
model: sonnet
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

A maintenance pass over a project that already exists and already ships. Nothing here adds
features. Every step is "compare a claim to disk, then correct the claim or the disk".
Prefer archiving to deleting, corrections to rewrites, and reporting to acting when an action
would touch something running.

**Input:** $ARGUMENTS, optional flags:
- `--report` scan and print the plan, change nothing
- `--skip-deploy` skip Phase 5
- `--skip-diagram` skip Phase 5b
- `--skip-memory` skip Phase 9
- `--no-commit` stop before the final `/acp`

`SKILL_DIR` is this skill's own directory: the one that holds this SKILL.md, shown as the skill's base directory when it loads. Scripts and assets live there, not in the project, so always call them by absolute path (`"$SKILL_DIR/scripts/…"`). If you don't know it: `SKILL_DIR=$(ls -d ~/.claude/skills/repo-tidy 2>/dev/null || find ~/.claude/plugins -maxdepth 8 -type d -path '*skills/repo-tidy' 2>/dev/null | sort | tail -1)`.
`references/` paths are relative to it. The TARS builder, the GitHub security standard, the
secret gate and the gitleaks assets live in the sibling skill, under
`"$SKILL_DIR/../repo-ready/"`: every `../repo-ready/…` path below starts there.

## Hard rules

- **Never edit** secrets, `.env*`, signing keys, risk caps, trading or billing config, or
  anything a project's AGENTS.md says agents must not touch. Read AGENTS.md first.
- **Never migrate a running deployment.** Phase 5 reports gaps and a plan; the migration is a
  separate, deliberate session.
- **Never delete a document you did not create** unless it is obvious junk (empty, `.DS_Store`,
  an exact duplicate). Everything else that is stale gets archived or corrected.
- **Every change and every archive lands in the final summary.** Git makes repo changes
  reversible; the summary makes them reviewable. Claude memory and the TARS database are
  outside git, so nothing there is removed without a copy (Phase 9) or overwritten without
  being listed.
- **Never commit past a failed secret gate.** Phase 11 runs it before `/acp`.
- **Match the project's voice.** Terse README stays terse. Do not add sections the project
  never had for the sake of completeness.

## Phase 1: Inventory (facts only, no edits)

```bash
pwd && git rev-parse --is-inside-work-tree && git status --short && git log --oneline -5
ls README* AGENTS.md CLAUDE.md docs specs NOTES* CHANGELOG* HANDOFF* handoffs 2>/dev/null
ls docker-compose.yml compose.yml Dockerfile .deploy unraid-icon.png wrangler.toml fly.toml vercel.json 2>/dev/null
ls scripts 2>/dev/null; find . -maxdepth 3 -name '*.plist' -not -path '*/node_modules/*' 2>/dev/null
find . -maxdepth 3 \( -iname 'logo.*' -o -iname 'icon.*' -o -iname 'favicon.*' \) -not -path '*/node_modules/*' -not -path '*/build/*' 2>/dev/null
```

If the tree is dirty, say so once. Continue; the final `/acp` sweeps everything, so ask only
if the dirty files look like work in progress the user may not want bundled.

Read `README.md` and `AGENTS.md` fully. Read the first 30 lines of every other document
found. Record: stack, entry commands, ports, paths, scripts, and every external resource the
docs name. This is the manifest the rest of the pass checks against.

Also read, if they exist:
- `~/memex/wiki/projects/<name>.md` (chat-derived context, may be stale in the other direction)
- the TARS row: `sqlite3 ~/.tars/tars.db "select data from project_metadata where project_id=(select id from projects where path='$PWD')"`

## Phase 2: README

The README is the source of truth for what the project is, so it has to be true.

For every path, script, command, port, URL, env var and file the README names, check it on
disk (`ls`, `grep -n`, `git ls-files`). Then:
- **Wrong**: fix in place. Renamed script, moved file, changed port, retired flag.
- **Missing**: add only what a reader needs to run or deploy the thing: the logo header if a
  logo exists, a deploy line if Phase 5 finds a standard deployment with no mention.
- **Describes future work as present**: rewrite that sentence to the shipped state.
- **Duplicates AGENTS.md operational detail**: leave the README the "what", move the "how"
  to AGENTS.md if it isn't already there.

Don't restructure. Don't add badges, tables of contents, or "Contributing" sections that
weren't there.

## Phase 3: AGENTS.md / CLAUDE.md

Invoke the `agents-md` skill in audit mode and apply its findings. Its rules already cover the
one-line `CLAUDE.md` pointer, dead references, and derivable facts. Do not repeat that work
here. If the project has no AGENTS.md and is one the user works on with agents, scaffold it
through that skill.

## Phase 4: Stale documents

Candidates: everything under `docs/`, `specs/`, `handoffs/`, `NOTES.md`, `TODO.md`,
`PLAN*.md`, `CHANGELOG.md`, and any top-level `*.md` that isn't README, AGENTS, CLAUDE,
LICENSE, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT.

A document is stale when any of these hold:
- it names files, commands, or flags that no longer exist
- it describes as planned something the README or git log shows shipped
- a newer document or the README fully supersedes it
- it is a handoff or session note older than the last 10 commits it refers to

Ladder, in order of preference:
1. **Correct** it if it is mostly right and still read (a runbook, a design still in force).
2. **Archive** it if it records a decision, a spec, or history worth keeping:
   `git mv <doc> docs/archive/<YYYY-MM-DD>-<original-name>` where the date is the doc's last
   commit date (`git log -1 --format=%as -- <doc>`). Add one line at the top:
   `> Archived <today>: superseded by <what>.`
3. **Delete** only obvious junk. Empty files, `.DS_Store`, exact duplicates, generated output
   that is gitignored everywhere else.

`CHANGELOG.md` is special: if it stopped at a version the git log has long passed, add one
entry summarizing "since <last version>" from the log rather than reconstructing every release.
Never invent dates.

## Phase 5: Deployment standard

Detect the target from the manifest, then check against the house standard for that target.
Report gaps as a numbered plan. Apply only the items marked safe.

**Uranus / Unraid** (a compose file, a Dockerfile, a deploy script, or docs mention the
box): the standard is the `uranus-deploy` skill. Invoke it for the checklist and verify:
- `docker-compose.yml` at the repo root with `container_name`, `restart: unless-stopped`,
  host port from `.env` with a default, `net.unraid.docker.webui` and `.icon` labels
- `.deploy` marker at the root (safe to add if the service is already on the pattern)
- `unraid-icon.png` at the root, square, 512px (safe to add if a logo exists)
- `.dockerignore` exists and excludes `.git`, `node_modules`, `data`, `.env`, build output
- `.gitignore` covers `.env`, `docker-compose.override.yml`, `compose.override.yml`, `data/`
  or whatever the compose file bind-mounts
- no rsync-style deploy script, no per-project `deploy-*.sh` that duplicates `deploy`
- runtime state that the app writes (config edited through a UI, caches, catalogs) lives in
  a mounted directory, not in the image
- `hadolint --no-color Dockerfile` (every Dockerfile in the repo; `brew install hadolint`,
  not installed = SKIPPED): list each `error` and `warning` with its rule code as a gap.
  Changing a Dockerfile changes the next deploy, so these are report-only here

If the service is deployed some other way (rsync, a hand-made container in the Unraid UI),
that is a **migration**: write the plan (compose file shape, what moves where, what per-host
files the box needs, what restarts) into the summary and stop. Do not run it.

**Cloudflare Workers** (`wrangler.toml`): `package.json` has a `deploy` script, the README
names it, the TARS row's `deploy_command` matches.

**App Store / Play / Homebrew tap**: verify the README and TARS row name the current
distribution channel; nothing to change on disk.

**No deployment**: say so and move on.

## Phase 5b: Architecture diagram

Read `references/architecture-diagram.md`. Use it to decide whether to create the
`docs/architecture.json` spec, refresh it, or leave it alone. If you create it, also add
the agent-file note it holds. Under `--report`, print the decision and its reason only.

## Phase 5c: Dependency and secret monitoring

GitHub remotes only: `gh repo view --json nameWithOwner,visibility`. Skip silently for
anything else.

Read `../repo-ready/references/github-security.md` and compare the repo against it:
- no `.github/dependabot.yml` and no Renovate config: write one
- a `dependabot.yml` missing an ecosystem the repo now uses, or `github-actions` when
  workflows exist: add the entry
- Dependabot alerts or security updates off: enable them
- public repo with secret scanning or push protection off: enable both
- public repo with private vulnerability reporting off, no `protect-default-branch` ruleset,
  or CodeQL default setup `not-configured`: enable each
- default `GITHUB_TOKEN` permission is `write`: set it to `read` only if every workflow has
  its own `permissions:` block; otherwise list the workflows that lack one as a follow-up

All of these are safe to apply. If a call is refused (no admin on the repo, plan doesn't
include it), list it as a follow-up. Under `--report`, print the gaps only.

Every GitHub repo with workflows gets the checks from
`../repo-ready/references/going-public.md` section 4: zizmor, the pinact check and the
greps. Report zizmor findings as follow-ups with severity; don't rewrite workflow logic in
this pass. Pinning is the one exception, because it does not change what runs:
`GITHUB_TOKEN="$(gh auth token)" pinact run` is safe to apply, and each pinned action goes in
the summary. A missing tool is listed as SKIPPED. A public repo with no `LICENSE` or no
`SECURITY.md` is a follow-up too.

**Local secret scanning**, every git repo, GitHub or not:
- `.gitleaks.toml` missing: copy `../repo-ready/assets/gitleaks.toml`
- `.gitleaks.toml` allowlists `README.md`, `docs/` or another whole directory by path (the
  older template did): replace its allowlist section with the one in the asset, keeping any
  custom `[[rules]]`
- no pre-commit secret hook: install `../repo-ready/assets/pre-commit` as
  `.githooks/pre-commit` and run `git config core.hooksPath .githooks`, unless the repo uses
  husky, lefthook or pre-commit, in which case add the gitleaks line to that manager
- hook file present but `git config --get core.hooksPath` is empty in this clone: set it
- GitHub repo with workflows but no `.github/workflows/gitleaks.yml`, or one that still calls
  `gitleaks detect`, has no `permissions:` block, or downloads the binary with no checksum:
  replace it with `../repo-ready/assets/gitleaks-workflow.yml`

Open Dependabot alerts and secret-scanning alerts go in the summary as follow-ups. Don't
resolve or fix them in this pass.

## Phase 6: Logo and icon

If the project has a logo (`assets/logo.*`, `static/logo.*`, `public/logo.*`, or similar):
- README header: `<p align="center"><img src="<path>" alt="<name>" width="140"></p>` at the top
  if absent
- favicon: a `<link rel="icon">` in the web app's HTML shell if it is a web app and has none
- `unraid-icon.png` at the root for Uranus services (convert with `sips` or `rsvg-convert` if
  only an SVG exists; 512×512)
- TARS `icon_path` (Phase 7)

If there is no logo, list that as a follow-up. Do not generate one here.

## Phase 7: TARS record

Skip silently if `~/.tars/tars.db` does not exist.

If the project has no row, follow `../repo-ready/references/tars-registration.md` (it builds
the full schema the app requires). If it has one, read `references/tars-update.md` and update
in place: correct fields the manifest contradicts (deploy target and command, production URL,
start command, framework, database, icon path, description), refresh custom fields whose
values are stale, keep everything else. Never write `project_secrets`.

Warn if the desktop app is running (`pgrep -fl tars-app`); it rereads the row on restart or
on reopening the project.

## Phase 8: Memex wiki page

If `~/memex/wiki/projects/<name>.md` exists, reconcile it with the manifest: fix facts that
disk contradicts, and add a dated line under its most recent section noting what this pass
changed (one or two sentences). Don't rewrite it; it is chat-derived context, not the README.
If it doesn't exist, don't create it.

## Phase 9: Claude memory

Claude Code keeps per-project memory at `~/.claude/projects/<slug>/memory/`, where `<slug>`
is the absolute repo path with every `/` replaced by `-` (`/Users/x/Development/foo` →
`-Users-x-Development-foo`). `MEMORY.md` is the index; each other file is one fact with a
`type:` of user, feedback, project, or reference. Skip silently if the directory is absent.

Before removing or rewriting anything, copy the directory:
`cp -R ~/.claude/projects/<slug>/memory ~/.claude/projects/<slug>/memory-backup-<YYYY-MM-DD>`.
Memory is not in git; the copy is the only undo. Name the backup path in the summary. Under
`--report`, list what would be deleted and change nothing.

For each memory file:
- **The repo now records it** (README, AGENTS.md, a runbook, a comment): delete it. Memory
  is for what the repo can't say; a duplicate drifts the moment the repo changes.
- **Disk contradicts it** (a file, flag, script, or path it names is gone or renamed): fix
  the fact if the intent still holds, delete it if the intent is gone.
- **It records a problem that is fixed**: delete it, or reduce it to the one-line lesson if
  the lesson isn't in AGENTS.md yet (and then put it in AGENTS.md instead).
- **`type: user` or `type: feedback`**: leave alone unless factually wrong. Those are about
  the person, not the project, and are not yours to prune on a tidy pass.

Then rewrite `MEMORY.md` so it lists exactly the files that remain, one line each, no
content. List every deletion in the summary under its own heading.

## Phase 10: Hygiene

- `.gitignore`: add the usual misses if the stack uses them and they're absent
  (`node_modules/`, `.DS_Store`, `.env`, `.beans/`, `dist/`, `build/`, `.svelte-kit/`,
  `target/`, `data/*.db*`)
- tracked files that should be ignored: `git ls-files -ci --exclude-standard` lists every
  tracked file an ignore rule matches. `git rm --cached <file>` each one (the working copy
  stays). If one of them ever held a credential (`.env`, a key file), untracking is not
  enough: it is still in history, so list it as a follow-up to rotate and purge
- dead scripts: for each file in `scripts/`, `grep -rn <basename> --exclude-dir=node_modules .`
  and list the ones nothing references (README, AGENTS.md, crontab, compose, package.json,
  other scripts). Archive them like documents; don't delete.
- leftovers from retired mechanisms: launchd plists for jobs now on cron elsewhere, old
  deploy scripts, `*.bak`, `*.orig`
- then invoke the `de-vibe` skill; its own confirm gate applies

## Phase 11: Summary and commit

Print one block:

```
Fixed:      README (3 paths, port), AGENTS.md (2 dead refs), docs/runbook.md
Archived:   docs/archive/2026-03-04-spec-v1.md, scripts/archive/deploy-old.sh
Deleted:    .DS_Store (2)
Added:      .deploy, unraid-icon.png, favicon link
TARS:       deploy_target, production_url, icon_path
Wiki:       ~/memex/wiki/projects/<name>.md (dated note)
Memory:     deleted audit-2026-08-21-findings (fixed, in AGENTS.md); kept 1
Deployment: on standard  |  MIGRATION PLAN below, not run
Security:   dependabot.yml (npm, github-actions), secret scanning on, ruleset, 3 actions pinned, zizmor 1 High, gate clean  |  current  |  not GitHub
Diagram:    created  |  refreshed, re-pinned to <sha>  |  current  |  skipped (<why>)
Follow-ups: no logo; CHANGELOG stopped at 1.2
```

Then run the secret gate over everything about to be committed and everything already in
history:

```bash
bash "$SKILL_DIR/../repo-ready/scripts/secret-gate.sh" "$PWD"; echo "gate exit=$?"      # public GitHub repo: prefix SECRET_GATE_BUILTIN=1 (strict mode)
```

Exit 1 (secrets found): **stop, do not invoke `acp`**. Print the locations, then run
`bash "$SKILL_DIR/../repo-ready/scripts/live-check.sh" "$PWD"` (TruffleHog, verifies each
candidate with its provider) and say which are still live. For a GitHub repo that is public,
say the key is already exposed and has to be rotated. Exit 3: read each listed
file and resolve it (untrack, or confirm it is clean) before committing. Exit 2 (gitleaks
missing): say so, and continue only for a repo with no public remote.

Then, unless `--report` or `--no-commit`: invoke `acp`. It commits everything and, on
`main` with a `.deploy` marker, deploys. Say so in the line before you invoke it, so a deploy
of a live service is never a surprise.
