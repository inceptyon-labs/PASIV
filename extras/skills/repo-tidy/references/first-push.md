# First push (mode: ready)

Prepare the project for its first push to a public or private git host. Scan the codebase for
signals, propose a complete set of repo artifacts, confirm only the non-inferrable choices, then
write the files, print the final `gh repo create` command, and offer (via `AskUserQuestion`) to
run it. This mode never commits; the user does that (`/acp`).

Shared steps (secret gate, gitleaks setup, gitignore, Dockerfiles, TARS, logo placement) are in
SKILL.md; this file says when to run them. Under `--report` / `--dry-run`, print the plan and
write nothing.

## First-push rules

- **Never overwrite an existing file** without explicit confirmation; enhance it instead.
- **Never run shared-state commands unprompted** (`gh repo create`, a visibility flip, a push to
  a new remote). Print them, then ask.
- **Never commit.** The setup commands push only what is already committed.

## Run report

Start the ledger before Phase 1:

```bash
bash "$SKILL_DIR/scripts/runlog.sh" start repo-tidy/first-push preflight secret-gate live-check going-public osv-scanner zizmor pinact gitignore gitleaks-hook hadolint tars secret-gate-final github-settings --tools gitleaks trufflehog zizmor pinact osv-scanner hadolint gh
```

Where each is recorded: `preflight` Phase 1 · `secret-gate`, `live-check` Phase 2 (or
`references/going-public.md` section 1 for Public) · `going-public`, `osv-scanner` going-public
sections 2–3 · `zizmor`, `pinact` going-public section 4 or 4h · `gitignore` 4i ·
`gitleaks-hook` 4k · `hadolint` 4n · `tars` 4m · `secret-gate-final`, `github-settings` Phase 6.
Deliberate skips here: private destination so no going-public, gate clean so no `live-check`,
no workflows, Question 9 = No, no TARS db, the user runs Phase 6 themselves.

## Phase 1: Preflight

```bash
pwd && git rev-parse --is-inside-work-tree 2>/dev/null && git remote -v
```

If not a git repo, stop and suggest `git init` first. No output from `git remote -v` means there
is no remote yet, which is the normal case here.

If `origin` already exists and points to a real remote, ask whether to continue (this mode is for
*first* push prep), or switch to upkeep mode. If they continue, skip the final `gh repo create` step.

If that existing remote is a **private GitHub repo** (`gh repo view --json visibility`) and the
user wants it public, that is a visibility flip: read `references/going-public.md` and run all
of it, including section 5, before Phase 6 prints the flip command.

## Phase 2: Scan for Signals

Gather everything inferrable before asking the user anything. Run these in parallel where possible.

**Project type & stack** (read only the files that exist): `package.json` (name, description,
author, license, scripts, deps → detect framework: React/Next/Vue/Fastify/Express/etc.),
`pyproject.toml`/`setup.py`/`requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go),
`Gemfile` (Ruby), `composer.json` (PHP), `pubspec.yaml` (Dart/Flutter),
`Dockerfile`/`docker-compose.yml` (deployment signals), `.github/workflows/` (existing CI).

**Existing docs** (so we don't overwrite). Not `ls` with globs: zsh aborts the whole line when
one pattern matches nothing.
```bash
git ls-files -co --exclude-standard | grep -iE '^(README|LICENSE|LICENCE|COPYING|CONTRIBUTING|SECURITY|CHANGELOG|CODE_OF_CONDUCT)[^/]*$|^\.github/|^\.(husky|githooks)/|^(lefthook\.ya?ml|\.pre-commit-config\.yaml)$'
```

**Secret gate, before writing anything:** run it per SKILL.md § Secret gate. Exit 1 stops the
whole run until the gate passes.

**Repo origin hint:**
```bash
git config --get user.name && git config --get user.email && gh api user --jq .login 2>/dev/null
gh api user/orgs --jq '.[].login' 2>/dev/null
```

Capture both the personal login AND every org the user belongs to. These become the pick-list
options in Question 6.

Store everything detected as a **repo-manifest** you'll reference through the rest of the run.

## Phase 3: Propose & Confirm

Print a short summary of what was detected (3-5 bullets max) and the draft plan. Example:

```
Detected: Node 20 / Fastify + React / Postgres / Docker
Existing: README.md (basic), .gitignore, .env.example
Missing:  LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, .github/
Secrets:  clean ✓
```

Then ask **only** the questions that can't be inferred. Use `AskUserQuestion` with
multiple-choice where possible.

**Question 1 — License:** MIT (most permissive, default for open source) | Apache-2.0
(permissive + patent grant) | AGPL-3.0 (copyleft, network use triggers) | Proprietary/None (no
LICENSE file) | Other (user specifies)

**Question 2 — Destination:** Where does this repo live?
- **Public GitHub** — `gh repo create --public`
- **Private GitHub** — `gh repo create --private`
- **Personal (Unraid self-hosted)** — bare git over SSH on the user's own Unraid box, LAN-only.
  No GitHub involved.

Only offer the Unraid option when the `uranus-deploy` skill is installed
(`~/.claude/skills/uranus-deploy/SKILL.md` exists); otherwise show just Public / Private. That
skill's gitignored `.env` is the source for the box's SSH target (`URANUS_SSH`) and bare-repo
root (`URANUS_GIT_ROOT`). Never write the address into this skill or into generated public files.

When **Public** is chosen (or a private repo is being flipped), read
`references/going-public.md` now, before any other question: run its section 1 (the gate in
strict mode, then the live check) and sections 2–4. Report every hit and get a decision on each
before Phase 4 writes anything. From here on, every gate run for this repo is strict.

The destination changes the rest of the flow. When **Unraid** is chosen, the repo has no GitHub
Actions runner and no GitHub UI, so **skip** Question 6 (repo owner), Question 7 (CI starter),
Question 8 (GitGuardian), and artifacts 4h (CI workflow), 4l (gitleaks CI) and 4o (Dependabot
config). Everything else (README, LICENSE, local gitleaks hook, etc.) still applies. Phase 6
prints the bare-SSH setup instead of `gh repo create`.

**Question 3 — Accept contributions?** (gates CONTRIBUTING.md + templates): Yes (include
CONTRIBUTING.md, issue templates, PR template) | No (skip contribution scaffolding)

**Question 4 — Repo description:** Draft a one-line description (≤350 chars, GitHub's limit)
from the scan. Present it and offer: use as-is | edit it (user provides text) | generate 3
alternatives to choose from

**Question 5 — Logo / banner:** Already have one (provide path) | Generate with Codex | Skip

**Question 6 — Repo owner:** *(GitHub destinations only — skip for Unraid.)*
Build `AskUserQuestion` options from the origin-hint scan: the personal login plus each org, one
option each. Always a pick-list, never free text. Hand-typed org slugs are the #1 cause of
`CreateRepository` errors, and the failure surfaces as an unrelated-looking GraphQL permissions
denial.

If the user has zero orgs, skip the question and default silently to the personal login. If
they have exactly one org AND it matches a signal in the repo (README mentions it, existing
remotes, package.json author field), surface that org as the Recommended option; otherwise list
personal first.

The repo name defaults to the directory basename; confirm or override as a separate (simpler) question.

**Question 7 — CI starter?** *(GitHub destinations only.)* Only ask if no `.github/workflows/`
exists AND the project has a detectable test command: Yes (basic CI workflow — test + build on
PR) | No

**Question 8 — GitGuardian cloud scanning?** *(GitHub destinations only.)* Optional; gitleaks
hook + CI are installed automatically either way: Yes (print enrollment instructions in Phase 6)
| No (gitleaks alone is enough for solo/small projects)

**Question 9 — Deploy to Uranus?** *(Only when the `uranus-deploy` skill is installed.)* Ask
when Phase 2 found a deployable service: a `Dockerfile`, a `docker-compose.yml`, or a server
framework (Fastify/Express/Hono-on-Node/FastAPI/Flask/Go net/http/SvelteKit-node). Skip for
libraries, CLIs, mobile apps, Cloudflare Workers, and static sites. Options: **Yes, self-host on
Uranus** (generate 4n and hand off to the `uranus-deploy` skill in Phase 6) | **No** (deploys
elsewhere or not at all). Independent of Question 2: a repo can live on GitHub and run on Uranus.

## Phase 4: Generate Artifacts

Write files only for what's missing or was approved to replace. Never overwrite an existing
file without explicit confirmation.

### 4a. LICENSE

Fetch the SPDX-standard text for the chosen license. For MIT/Apache-2.0/AGPL-3.0, use the
canonical template with `{year}` and `{copyright holder}` filled from `git config user.name`
(`gh api licenses/mit --jq .body` returns the exact text, with `[year]` and `[fullname]` as the
placeholders). The holder is a person or company name, not a GitHub login; ask only if
`user.name` is empty or the manifest's `author` names someone else.

### 4b. README.md

If a README exists, **enhance it** rather than replacing. Check for and add any missing
sections: logo/banner at top (if generated or provided), badges row (license, CI status
placeholder, version if in package.json), one-line description (from Phase 3),
Quickstart/Install, Usage, Configuration/Environment Variables, API (if server project),
Contributing (link to CONTRIBUTING.md), License.

If no README exists, generate from the repo-manifest with all standard sections.

**Section header icons:** default to none. If the existing README uses emoji headers OR the user
asks for icons, read `references/readme-icons.md` and follow it.

### 4c. CONTRIBUTING.md (if accepting contributions)

Standard sections: Code of Conduct link, Development setup, Running tests, Commit style, PR
process, Issue reporting.

In the "Development setup" section, include a one-time hook activation step so contributors pick
up the gitleaks pre-commit hook installed in 4k:

```bash
# After cloning, activate versioned git hooks (runs gitleaks on every commit).
git config core.hooksPath .githooks
```

If no CONTRIBUTING.md is being written (contributions = No), add the same block to the README's
"Development" or "Contributing" section instead; the hook is still installed either way.

If 4k found a hook manager (husky, lefthook, pre-commit), document that manager's own install
step here (husky: `npm install` runs its `prepare` script) and leave `core.hooksPath` out.

### 4d. CODE_OF_CONDUCT.md (if accepting contributions)

**Do NOT vendor the full Contributor Covenant text.** Its verbatim harassment-category
enumerations trip the output content filter mid-generation and halt the skill. Adopt by
reference instead (the React/Kubernetes/Rust convention): copy `assets/code-of-conduct.md` to
`CODE_OF_CONDUCT.md`, substituting `{contact}` and `{covenant-url}`
(`https://www.contributor-covenant.org/version/2/1/code_of_conduct/`). `{contact}` is an address
the maintainer is willing to publish. For a Private or Unraid repo, default to
`git config user.email`. For a **Public** repo, ask for it: never publish `user.email` unasked,
and a `.local` or `noreply` address cannot receive mail, so neither is an answer.

If the user specifically requests the full vendored text, generate it with a warning that the
request may fail and need a retry.

### 4e. SECURITY.md

A short policy (supported versions, how to report, what to expect) with a vuln-reporting
channel. For a **Public GitHub** repo, default to GitHub's private vulnerability reporting form,
`https://github.com/<owner>/<name>/security/advisories/new` (Phase 6 enables it), so no personal
email is published. Use an email only if the user asks for one or the destination is not public GitHub.

### 4f. CHANGELOG.md

Seed with Keep-a-Changelog format. Use the manifest's version if it has one (`package.json`,
`Cargo.toml`, `pyproject.toml`), else `0.1.0`, and today's date:
```markdown
# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - YYYY-MM-DD
### Added
- Initial release.
```

### 4g. .github/ templates (if accepting contributions)

`.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`,
`.github/PULL_REQUEST_TEMPLATE.md`

### 4h. CI workflow (if approved)

Detect test runner from package.json / pyproject / etc. Write `.github/workflows/ci.yml` with
lint + test + build on PR and main push. Keep it minimal; the user can expand later. Give it a
top-level `permissions: contents: read`, trigger on `pull_request` (never `pull_request_target`),
set `persist-credentials: false` on `actions/checkout`, and pin each action to a full commit SHA
with the version in a trailing comment: write `uses: owner/action@vN`, then run
`GITHUB_TOKEN="$(gh auth token)" pinact run .github/workflows/ci.yml` (no pinact:
`gh api repos/<owner>/<action>/git/ref/tags/<tag> --jq .object.sha` per action). The Dependabot
`github-actions` entry keeps the pins current. If zizmor is installed,
`zizmor --offline .github/workflows/ci.yml` must come back clean before moving on.

Workflows that already exist are the project's own: don't rewrite them. If
`references/going-public.md` section 4 flags one (no `permissions:` block, unpinned action,
`pull_request_target`), show the finding and the edit, and make it only when the user agrees.

### 4i. .gitignore

SKILL.md § Gitignore. Mark appended entries with a `# Added by repo-tidy` comment header, and
offer `git rm --cached` for each tracked-but-ignored file rather than doing it unasked.

### 4j. Logo (if requested)

Generate it with the Codex CLI's built-in image generation (`codex features list` shows
`image_generation`). The Codex MCP tool runs read-only and cannot save a file, so run the CLI
from the repo root:

```bash
codex exec -s workspace-write "Generate a logo image for this project using your built-in image generation tool (not SVG, not drawn with code). <what the project is; the mark; the wordmark; colors>. Transparent background, no gradients, no glow, no drop shadow, no extra text. Save the final PNG to .github/logo.png and print its pixel dimensions. Do not modify any other file."
```

Point the brief at the project's own design files (`DESIGN.md`, an app icon, a palette) instead
of describing colors from memory; Codex reads them itself. A run takes a few minutes, so allow a
long timeout. Open the PNG and check it before using it.

Save into the target repo at `./assets/logo.png` or `./.github/logo.png` (the project's
directories, not this skill's `assets/`), then place it per SKILL.md § Logo placement.

### 4k / 4l. Secret scanning hook and CI (always)

SKILL.md § Gitleaks setup. No question needed. The CI workflow applies to GitHub destinations only.

### 4o. Dependabot config (GitHub destinations, always)

No question needed. Read `references/github-security.md` and write `.github/dependabot.yml` per
its section 1, using the manifests the Phase 2 scan found. Skip for Unraid. The repository
settings in its section 2 need the repo to exist, so they run in Phase 6.

### 4n. Uranus deploy scaffolding (only if Question 9 = Yes)

Follow the conventions in the `uranus-deploy` skill (`~/.claude/skills/uranus-deploy/SKILL.md`,
"Onboard a new service"). Write only what is missing:

- `docker-compose.yml` with `build: .`, `container_name: <name>`, `restart: unless-stopped`, host
  port `"${NAME_PORT:-<port>}:<port>"`, secrets as `${VAR:?set VAR in .env}`, Unraid labels
  `net.unraid.docker.webui` and `net.unraid.docker.icon`, bind mounts (never anonymous volumes),
  optional dependencies behind `profiles:`. If a `Dockerfile` is missing, write one appropriate
  to the stack and lint it per SKILL.md § Dockerfiles.
- `.env.example` listing every `${VAR}` the compose file reads.
- `.deploy` containing `<name>` so `/acp` deploys after each push to `main`. Use the name the box
  already knows (`/mnt/user/appdata/<name>-src`, the compose `container_name`) when the service is
  already deployed; it is not always the repo directory basename.
- `unraid-icon.png` (square, 512px) from the project logo if one exists (Question 5), else skip
  and say so.
- `.gitignore` entries: `.env`, `docker-compose.override.yml`, `compose.override.yml`, `data/`.

**Icon label URL — pick by destination.** `deploy.sh` seeds Unraid's icon cache from the
repo-root `unraid-icon.png` on every deploy, so that file is the primary source either way; the
label is the fallback Unraid uses when the cache misses. Point it somewhere that actually resolves:

| Question 2 destination | `net.unraid.docker.icon` value |
|---|---|
| Public GitHub | `https://raw.githubusercontent.com/<owner>/<name>/main/unraid-icon.png` |
| Private GitHub | app-served path (raw.githubusercontent 404s on private repos) |
| Unraid (bare git) | app-served path — **never** a `raw.githubusercontent.com` URL, there is no GitHub repo |

The app-served path is `http://[IP]:[PORT:<container-port>]/icon.png`, matching
`~/Development/beacon/docker-compose.yml`. `[PORT:…]` takes the **container** port, not the
published host port; Unraid resolves it. Copy the icon into whatever directory the framework
serves at the web root (`static/` for SvelteKit, `public/` for Vite/Next/CRA) so the path exists,
and confirm it lands in the build output the Dockerfile copies.

Do not create anything on the box here; Phase 6 covers that.

### 4m. Register with TARS

SKILL.md § TARS.

## Phase 5: Final Review

Show a summary of everything written/modified:

```
Wrote:
  LICENSE (MIT)
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  CHANGELOG.md
  .github/ISSUE_TEMPLATE/bug_report.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/workflows/ci.yml
  .github/workflows/gitleaks.yml
  .github/dependabot.yml (npm, github-actions)
  .githooks/pre-commit (+x)
  .gitleaks.toml
Modified:
  README.md (added badges, logo, license section)
  .gitignore (added .env, .DS_Store)
  CONTRIBUTING.md (added hooksPath activation step)
Registered:
  TARS project <uuid> (skipped if ~/.tars/tars.db not found)
Skipped:
  (none)
```

Run a final check:
```bash
git status --short
```

Then add one line suggesting `/repo-tidy` (upkeep) once the project's architecture has settled.
Upkeep creates the Archify diagram (`docs/architecture.json`) and its agent-file note. Don't
create the diagram here. A first-push project usually changes shape too fast for it to stay accurate.

## Phase 6: Destination Setup Command

**Print first, then ask.** Print the shared-state commands (`gh repo create`, the GitHub security
settings, `git init --bare`, `git push`, GitGuardian enrollment) so the user can review exactly
what would run, then ask via `AskUserQuestion` whether to run them (see "Offer to run" below).
Never run them unprompted. This mode still never commits: the setup commands push only what is
already committed. If the working tree is dirty, say so before asking; committing stays with the
user (`/acp`).

**Re-run the gate immediately before any push or visibility change** (SKILL.md § Secret gate,
recorded as `secret-gate-final`), strict for a Public destination. Files were written and the
user may have committed since Phase 2. Exit 1 blocks every destination; exit 2 blocks Public.
For **Public**, every `references/going-public.md` finding also has to be fixed or explicitly
accepted by the user first. If the squash route was chosen, the printed block starts with those
commands, and the gate run that follows them adds `SECRET_GATE_REFS=main`, because the old
history is still on the local `private-history` branch.

Which command block you print depends on the Question 2 destination.

### GitHub destination (Public / Private)

Build from the manifest:

```bash
gh repo create <owner>/<name> \
  --<public|private> \
  --description "<description>" \
  --source=. \
  --remote=origin \
  --push
```

If topics were inferred from the stack (e.g., `react`, `fastify`, `postgres`, `docker`), suggest
a follow-up:

```bash
gh repo edit <owner>/<name> --add-topic <t1>,<t2>,<t3>
```

If the local branch is not `main`, put `git branch -M main` ahead of the create command. After a
Public push, `git ls-remote --heads origin` should list only the branch that was meant to go out.

Then print the security settings from `references/github-security.md` section 2, starting with
the line `R=<owner>/<name>` that the commands use: Dependabot alerts, security updates and the
read-only default token for every repo; secret scanning, push protection, private vulnerability
reporting, the default-branch ruleset and CodeQL default setup for **Public** only. If Phase 1
found an existing `origin` and `gh repo create` is skipped, still print them for that repo. For a
visibility flip, print the flip command from `references/going-public.md` section 5 first.

### Unraid destination (personal self-hosted)

Bare git over SSH on the Unraid box (LAN-only). Take `<ssh-target>` (user@host) and `<git-root>`
(the directory the box's existing bare repos live in) from the `uranus-deploy` skill's `.env`
(`URANUS_SSH`, `URANUS_GIT_ROOT`). The remote repo doesn't exist yet, so the first command
initializes it on the box, then wires the remote and pushes. Substitute `<name>`.

```bash
# 1. Create the bare repo on the box (idempotent — safe to re-run)
ssh <ssh-target> 'git init --bare <git-root>/<name>.git'

# 2. Wire origin and push
git remote add origin ssh://<ssh-target><git-root>/<name>.git
git branch -M main
git push -u origin main
```

### GitGuardian (GitHub destinations, optional)

**If Question 8 was answered Yes**, append:

```
GitGuardian enrollment (optional cloud scanning):
  1. Sign up at https://dashboard.gitguardian.com/auth/signup
  2. VCS Integrations → GitHub → connect your account (or org)
  3. Enable monitoring on <owner>/<name> after the repo is created
  4. (Optional) Install the GitGuardian GitHub App for PR-level inline comments

Free tier covers public repos and private repos with ≤25 developers.
Complements gitleaks — same detection philosophy, adds cloud history + alerts.
```

### Uranus deploy hand-off (only if Question 9 = Yes)

After the destination block, print the two remaining steps and offer to run them: create
`/mnt/user/appdata/<name>-src/.env` on the box (values via heredoc over SSH, never echoed into
chat; generate secrets with `openssl rand -hex 32`), then `deploy <name>` from the repo root once
the scaffolding is committed. Both are described in the `uranus-deploy` skill; invoke it rather
than re-deriving the steps.

### Offer to run

After printing the command block, ask with `AskUserQuestion`:

**Question — Run setup commands?** "Run the commands above now?"
- **Run them now** — execute the destination block (`gh repo create …` / the visibility flip /
  the Unraid SSH block), then the topic edit if one was suggested, then the GitHub security
  settings. Report each command's output. GitGuardian enrollment is browser-based and always
  stays manual.
- **I'll run them myself** — end with: "Review the artifacts, then run the commands above when
  you're ready."

If the user picks "Run them now" and the working tree is dirty, remind them afterward that the
push only included committed work and the new artifacts still need a commit (`/acp`).

## Phase 7: Run report

The last step of every run, including one the gate stopped early: print it per SKILL.md § Run report.
