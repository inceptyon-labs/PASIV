# Upkeep (mode: tidy)

A maintenance pass over a project that already exists and already ships. Nothing here adds
features. Every step is "compare a claim to disk, then correct the claim or the disk". Prefer
archiving to deleting, corrections to rewrites, and reporting to acting when an action would
touch something running.

Shared steps (secret gate, gitleaks setup, gitignore, internal docs, Dockerfiles, TARS, logo placement) are in
SKILL.md; this file says when to run them. Under `--report`, every phase still runs its read-only
checks (the gate, zizmor, `pinact run --fix=false`, hadolint, the Scorecard, the dead-code
analyzers and baseline build, `gh api` GETs) and lists what it would change. It writes no file,
changes no setting, and where a phase says to invoke another skill it prints "would invoke
<skill>" and moves on.

## Upkeep rules

- **Never migrate a running deployment.** Phase 5 reports gaps and a plan; the migration is a
  separate, deliberate session.
- **Never delete a document you did not create** unless it is obvious junk (empty, `.DS_Store`,
  an exact duplicate). Everything else that is stale gets archived or corrected.
- **Delete source files only with proof** (Phase 10b): the analyzer and a repo-wide grep both
  say unused, and the project's build passes after removal. No passing baseline build means
  nothing is deleted. Assets and dependencies are report-only.
- **Never delete untracked files.** They aren't in git, so there's no undo. Gitignore junk
  patterns; ask about anything that looks like work.
- **Move docs, never code.** Phase 4b moves documentation only, and leaves anything that code,
  config, CI, a tool, or an external URL references by path.

## Run report

Start the ledger before Phase 1:

```bash
bash "$SKILL_DIR/scripts/runlog.sh" start repo-tidy inventory readme agents-md internal-docs stale-docs doc-layout deploy hadolint diagram github-settings zizmor pinact gitleaks-setup scorecard logo tars wiki memory hygiene dead-code unused-assets clutter de-vibe secret-gate live-check --tools gitleaks trufflehog zizmor pinact hadolint scorecard gh sqlite3
```

Checks by phase: 1 `inventory` · 2 `readme` · 3 `agents-md` · 3b `internal-docs` · 4
`stale-docs` · 4b `doc-layout` · 5 `deploy`, `hadolint` · 5b `diagram` · 5c `github-settings`, `zizmor`, `pinact`,
`gitleaks-setup`, `scorecard` · 6 `logo` · 7 `tars` · 8 `wiki` · 9 `memory` · 10 `hygiene` · 10b
`dead-code`, `unused-assets`, `clutter`, `de-vibe` · 11 `secret-gate`, `live-check`. Each
dead-code analyzer records as its own `ran dead-code` with the tool name as the detail.
Deliberate skips here: a `--skip-*` flag, not a GitHub repo, no Dockerfile, no workflows, gate
passed so no `live-check`.

## Phase 1: Inventory (facts only, no edits)

```bash
pwd && git rev-parse --is-inside-work-tree && git status --short && git log --oneline -5
# no shell globs: zsh aborts the whole line when one pattern matches nothing
git ls-files -co --exclude-standard | grep -iE '^(README|AGENTS|CLAUDE|NOTES|CHANGELOG|HANDOFF|TODO|PLAN)[^/]*$|^[^/]+\.md$|^(docs|specs|handoffs|notes|design|planning|adr|rfcs|documentation|wiki)/' | head -80
for f in docker-compose.yml compose.yml Dockerfile .deploy unraid-icon.png wrangler.toml fly.toml vercel.json; do [ -e "$f" ] && echo "$f"; done
ls scripts 2>/dev/null; find . -maxdepth 3 -name '*.plist' -not -path '*/node_modules/*' 2>/dev/null
find . -maxdepth 3 \( -iname 'logo.*' -o -iname 'icon.*' -o -iname 'favicon.*' \) -not -path '*/node_modules/*' -not -path '*/build/*' 2>/dev/null
```

If the tree is dirty, say so once. Continue; the final `/acp` sweeps everything, so ask only if
the dirty files look like work in progress the user may not want bundled.

Read `README.md` and `AGENTS.md` fully. Read the first 30 lines of every other document found.
Record: stack, entry commands, ports, paths, scripts, and every external resource the docs name.
This is the manifest the rest of the pass checks against.

Also read, if they exist:
- `~/memex/wiki/projects/<name>.md` (chat-derived context, may be stale in the other direction)
- the TARS row: `sqlite3 ~/.tars/tars.db "select data from project_metadata where project_id=(select id from projects where path='$PWD')"`

## Phase 2: README

The README is the source of truth for what the project is, so it has to be true.

For every path, script, command, port, URL, env var and file the README names, check it on disk
(`ls`, `grep -n`, `git ls-files`). Then:
- **Wrong**: fix in place. Renamed script, moved file, changed port, retired flag.
- **Missing**: add only what a reader needs to run or deploy the thing: the logo header if a logo
  exists, a deploy line if Phase 5 finds a standard deployment with no mention.
- **Describes future work as present**: rewrite that sentence to the shipped state.
- **Duplicates AGENTS.md operational detail**: leave the README the "what", move the "how" to
  AGENTS.md if it isn't already there.

Don't restructure. Don't add badges, tables of contents, or "Contributing" sections that weren't there.

## Phase 3: AGENTS.md / CLAUDE.md

Invoke the `agents-md` skill in audit mode and apply its findings. Its rules already cover the
one-line `CLAUDE.md` pointer, dead references, and derivable facts. Do not repeat that work
here. If the project has no AGENTS.md and is one the user works on with agents, scaffold it
through that skill.

## Phase 3b: Internal docs

Read `references/internal-docs.md` and follow it: sort every tracked doc by its reader, untrack
and gitignore the internal ones (specs, PRDs, plans, designs, decisions, handoffs, task files,
scans, reports, archives), unlink them from tracked docs, and report how much history still
holds them. Apply it directly; `git add -f` reverses an untrack. Record
`RUNLOG done internal-docs "<n untracked, n rules>"`, or `current` when nothing internal is
tracked.

## Phase 4: Stale documents

Candidates: the tracked docs Phase 3b kept (usage docs, references, ARCHITECTURE.md, runbooks
written for users) and `CHANGELOG.md`. Internal docs are local after Phase 3b; leave their
staleness alone.

A document is stale when any of these hold:
- it names files, commands, or flags that no longer exist
- it describes as planned something the README or git log shows shipped
- a newer document or the README fully supersedes it

Ladder, in order of preference:
1. **Correct** it if it is mostly right and still read (a runbook, a design still in force).
2. **Archive** it if it records history worth keeping. `docs/archive/` is gitignored (Phase
   3b), so the archive is local and the commit removes the doc from the tree:
   `git rm -q --cached <doc> && mkdir -p docs/archive && mv <doc> docs/archive/<YYYY-MM-DD>-<original-name>`
   where the date is the doc's last commit date (`git log -1 --format=%as -- <doc>`). Add one
   line at the top: `> Archived <today>: superseded by <what>.` Unlink it from tracked docs
   (`references/internal-docs.md` section 3, step 4).
3. **Delete** only obvious junk. Empty files, `.DS_Store`, exact duplicates, generated output
   that is gitignored everywhere else.

`CHANGELOG.md` is special: if it stopped at a version the git log has long passed, add one entry
summarizing "since <last version>" from the log rather than reconstructing every release. Never
invent dates.

## Phase 4b: Doc layout

Read `references/doc-layout.md` and follow it: gather root-level and scattered docs into `docs/`
(grouped into subfolders only when there are enough), `git mv` each one, rewrite links to and
inside every moved file, and run `scripts/md-links.py` until the moves leave no broken links.
Root files GitHub and tools expect, PASIV's fixed paths, docs-site trees, package READMEs, and
anything referenced outside Markdown stay put. Record
`RUNLOG done doc-layout "<n moved, n links updated>"`, or `current` when nothing needed moving.

## Phase 5: Deployment standard

Skip under `--skip-deploy`. Detect the target from the manifest, then check against the house
standard for that target. Report gaps as a numbered plan. Apply only the items marked safe.

**Uranus / Unraid** (a compose file, a Dockerfile, a deploy script, or docs mention the box): the
standard is the `uranus-deploy` skill. Invoke it for the checklist and verify:
- `docker-compose.yml` at the repo root with `container_name`, `restart: unless-stopped`, host
  port from `.env` with a default, `net.unraid.docker.webui` and `.icon` labels
- `.deploy` marker at the root (safe to add if the service is already on the pattern)
- `unraid-icon.png` at the root, square, 512px (safe to add if a logo exists)
- `.dockerignore` exists and excludes `.git`, `node_modules`, `data`, `.env`, build output
- `.gitignore` covers `.env`, `docker-compose.override.yml`, `compose.override.yml`, `data/` or
  whatever the compose file bind-mounts
- no rsync-style deploy script, no per-project `deploy-*.sh` that duplicates `deploy`
- runtime state that the app writes (config edited through a UI, caches, catalogs) lives in a
  mounted directory, not in the image
- every Dockerfile linted per SKILL.md § Dockerfiles (existing files: report only, since a change
  alters the next deploy)

If the service is deployed some other way (rsync, a hand-made container in the Unraid UI), that
is a **migration**: write the plan (compose file shape, what moves where, what per-host files
the box needs, what restarts) into the summary and stop. Do not run it.

**Cloudflare Workers** (`wrangler.toml`): `package.json` has a `deploy` script, the README names
it, the TARS row's `deploy_command` matches.

**App Store / Play / Homebrew tap**: verify the README and TARS row name the current distribution
channel; nothing to change on disk.

**No deployment**: say so and move on.

## Phase 5b: Architecture diagram

Skip under `--skip-diagram`. Read `references/architecture-diagram.md`. Use it to decide whether
to create the `docs/architecture.json` spec, refresh it, or leave it alone. If you create it,
also add the agent-file note it holds. Under `--report`, print the decision and its reason only.

## Phase 5c: Dependency and secret monitoring

GitHub remotes only: `gh repo view --json nameWithOwner,visibility`. Skip silently for anything else.

Read `references/github-security.md` and compare the repo against it:
- no `.github/dependabot.yml` and no Renovate config: write one
- a `dependabot.yml` missing an ecosystem the repo now uses, or `github-actions` when workflows
  exist: add the entry
- Dependabot alerts or security updates off: enable them
- public repo with secret scanning or push protection off: enable both
- public repo with private vulnerability reporting off, no `protect-default-branch` ruleset, or
  CodeQL default setup `not-configured`: enable each
- default `GITHUB_TOKEN` permission is `write`: set it to `read` only if every workflow has its
  own `permissions:` block; otherwise list the workflows that lack one as a follow-up

All of these are safe to apply. If a call is refused (no admin on the repo, plan doesn't include
it), list it as a follow-up. Under `--report`, print the gaps only.

Every GitHub repo with workflows gets the checks from `references/going-public.md` section 4:
zizmor, the pinact check and the greps. Report zizmor findings as follow-ups with severity; don't
rewrite workflow logic in this pass. Pinning is the one exception, because it does not change
what runs: `GITHUB_TOKEN="$(gh auth token)" pinact run` is safe to apply, and each pinned action
goes in the summary. An action on a branch ref (`@main`, `@beta`) cannot be pinned to a version:
list it as a follow-up. A missing tool is listed as SKIPPED. A public repo with no `LICENSE` or
no `SECURITY.md` is a follow-up too.

**Local secret scanning**, every git repo, GitHub or not: SKILL.md § Gitleaks setup, including
its upgrade checks for older configs, hooks, and workflows. Record `gitleaks-setup`.

Open Dependabot alerts and secret-scanning alerts go in the summary as follow-ups. Don't resolve
or fix them in this pass.

**Scorecard**, public GitHub repos only, after the settings above are applied:

```bash
bash "$SKILL_DIR/scripts/scorecard.sh" <owner>/<name>
```

It prints the OpenSSF Scorecard total and every check, lowest first (`?` means not applicable).
Exit 2 means no score: say SKIPPED (`brew install scorecard`). Put the total in the summary and
sort the checks that scored below 7 into three piles (a check at 7 or above needs no mention):

- **This pass already handles it**: Branch-Protection (ruleset), Dependency-Update-Tool
  (`dependabot.yml`), SAST (CodeQL default setup), Token-Permissions, Pinned-Dependencies
  (pinact), Vulnerabilities (Dependabot alerts), License. Settings count immediately; file
  changes count once the commit is pushed, so say the score will move after `/acp` and don't
  list these as follow-ups.
- **Follow-up**: Dangerous-Workflow (the zizmor findings above), Security-Policy (no
  `SECURITY.md`), Binary-Artifacts, Maintained.
- **Expected low for a solo project, mention once and move on**: Code-Review, Contributors,
  CII-Best-Practices, Fuzzing, Signed-Releases, Packaging, CI-Tests.

Under `--report`, print the score and the piles only.

## Phase 6: Logo and icon

If the project has a logo, place it per SKILL.md § Logo placement. If there is no logo, list
that as a follow-up. Do not generate one in this mode.

## Phase 7: TARS record

SKILL.md § TARS.

## Phase 8: Memex wiki page

If `~/memex/wiki/projects/<name>.md` exists, reconcile it with the manifest: fix facts that disk
contradicts, and add a dated line under its most recent section noting what this pass changed
(one or two sentences). Don't rewrite it; it is chat-derived context, not the README. If it
doesn't exist, don't create it.

## Phase 9: Claude memory

Skip under `--skip-memory`. Claude Code keeps per-project memory at
`~/.claude/projects/<slug>/memory/`, where `<slug>` is the absolute repo path with every `/`
replaced by `-` (`/Users/x/Development/foo` → `-Users-x-Development-foo`). `MEMORY.md` is the
index; each other file is one fact with a `type:` of user, feedback, project, or reference. Skip
silently if the directory is absent.

Before removing or rewriting anything, copy the directory:
`cp -R ~/.claude/projects/<slug>/memory ~/.claude/projects/<slug>/memory-backup-<YYYY-MM-DD>`.
Memory is not in git; the copy is the only undo. Name the backup path in the summary. Under
`--report`, list what would be deleted and change nothing.

For each memory file:
- **The repo now records it** (README, AGENTS.md, a runbook, a comment): delete it. Memory is
  for what the repo can't say; a duplicate drifts the moment the repo changes.
- **Disk contradicts it** (a file, flag, script, or path it names is gone or renamed): fix the
  fact if the intent still holds, delete it if the intent is gone.
- **It records a problem that is fixed**: delete it, or reduce it to the one-line lesson if the
  lesson isn't in AGENTS.md yet (and then put it in AGENTS.md instead).
- **`type: user` or `type: feedback`**: leave alone unless factually wrong. Those are about the
  person, not the project, and are not yours to prune on a tidy pass.

Then rewrite `MEMORY.md` so it lists exactly the files that remain, one line each, no content.
List every deletion in the summary under its own heading.

## Phase 10: Hygiene

- SKILL.md § Gitignore (apply the untracking directly in this mode)
- dead scripts: for each file in `scripts/`, `grep -rn <basename> --exclude-dir=node_modules .`
  and list the ones nothing references (README, AGENTS.md, crontab, compose, package.json, other
  scripts). Archive them like documents; don't delete.
- leftovers from retired mechanisms: launchd plists for jobs now on cron elsewhere, old deploy
  scripts, `*.bak`, `*.orig`

## Phase 10b: Dead files and clutter

Read `references/dead-code.md` and follow it:
1. **Dead source files:** run the baseline build, find candidates with the stack's analyzer
   (knip, Periphery, vulture, cargo-machete) or the import-grep method, cross-check each with a
   repo-wide grep, skip the never-delete list, then `git rm` the survivors and rebuild. A failing
   rebuild restores the batch and bisects. Record `dead-code`, or skip it under `--skip-dead-code`.
2. **Unused dependencies and assets:** list only. Record `unused-assets`.
3. **Untracked clutter:** gitignore junk patterns before the final `/acp` sweeps them in. Ask
   about large files and untracked source. Record `clutter`.

Then invoke the `de-vibe` skill; its own confirm gate applies.

## Phase 11: Summary and commit

Print the summary as Markdown, not inside a code block: an aligned code block breaks into wrapped
fragments once a line is wider than the terminal. One bullet per area; leave out an area with
nothing to report, and give each follow-up its own bullet:

```markdown
**Repo tidy: <name>**

- **Fixed:** README (3 paths, port), AGENTS.md (2 dead refs), docs/runbook.md
- **Untracked (internal, kept on disk):** docs/designs/ (4), NOTES.md; .gitignore +2 rules; in 17 commits of history
- **Archived:** docs/archive/2026-03-04-runbook-v1.md (local), scripts/archive/deploy-old.sh
- **Moved:** ARCHITECTURE.md → docs/architecture.md, guides/ → docs/guides/ (7 links updated)
- **Deleted:** .DS_Store (2)
- **Removed (dead code):** src/legacy/OldChart.tsx, src/utils/format-old.ts (build passed)
- **Ignored:** *.log, Screenshot*.png (untracked clutter)
- **Added:** .deploy, unraid-icon.png, favicon link
- **TARS:** deploy_target, production_url, icon_path
- **Wiki:** ~/memex/wiki/projects/<name>.md (dated note)
- **Memory:** deleted audit-2026-08-21-findings (fixed, in AGENTS.md); kept 1
- **Deployment:** on standard
- **Security:** dependabot.yml (npm, github-actions), secret scanning on, ruleset, 3 actions pinned, zizmor 1 High, gate clean
- **Scorecard:** 2.5/10 before this pass (rerun after the push)
- **Diagram:** refreshed, re-pinned to <sha>

**Follow-ups**

- No logo
- CHANGELOG stopped at 1.2
- Unused (review): 1 file (in project.pbxproj), 6 exports, 3 dependencies, 4 assets
```

Other values those areas take: Deployment `MIGRATION PLAN below, not run`; Security `current` or
`not GitHub`; Scorecard `skipped (private | not GitHub | no CLI)`; Diagram `created`, `current`
or `skipped (<why>)`.

Then run the secret gate (SKILL.md § Secret gate) over everything about to be committed and
everything already in history, strict for a public GitHub repo. Then print the run report
(SKILL.md § Run report), also when the gate stopped the pass. Never invoke `acp` while the gate
failed or the report lists anything under **Not run**.

Then, unless `--report` or `--no-commit`: invoke `acp`. It commits everything and, on `main` with
a `.deploy` marker, deploys. Say so in the line before you invoke it, so a deploy of a live
service is never a surprise.
