---
name: repo-ready
description: Prep a project for first GitHub push - README, LICENSE, CONTRIBUTING, SECURITY, CHANGELOG, .github templates, secret scan. Use for "repo ready", "prep for github", "first push".
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Skill
user-invocable: true
---

# Repo Ready

Prepare the current project for its first push to a public or private git host. Scan the codebase for signals, propose a complete set of repo artifacts, confirm only the non-inferrable choices, then write the files and print (do NOT execute) the final `gh repo create` command.

**Input:** $ARGUMENTS (optional — pass `--dry-run` to print the plan without writing files)

`assets/` and `references/` paths below are relative to this skill's directory.

## Phase 1: Preflight

```bash
pwd && git rev-parse --is-inside-work-tree 2>/dev/null && git remote -v
```

If not a git repo, stop and suggest `git init` first.

If `origin` already exists and points to a real remote, ask whether to continue — this skill is for *first* push prep. If they say yes, skip the final `gh repo create` step at the end.

## Phase 2: Scan for Signals

Gather everything inferrable before asking the user anything. Run these in parallel where possible.

**Project type & stack** (read only the files that exist): `package.json` (name, description, author, license, scripts, deps → detect framework: React/Next/Vue/Fastify/Express/etc.), `pyproject.toml`/`setup.py`/`requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `Gemfile` (Ruby), `composer.json` (PHP), `pubspec.yaml` (Dart/Flutter), `Dockerfile`/`docker-compose.yml` (deployment signals), `.github/workflows/` (existing CI).

**Existing docs** (so we don't overwrite):
```bash
ls README* LICENSE* CONTRIBUTING* SECURITY* CHANGELOG* CODE_OF_CONDUCT* .github 2>/dev/null
```

**Secret leakage scan** — **do this before writing anything**:
```bash
git ls-files | grep -E '^(\.env$|\.env\.|.*\.pem$|.*\.key$|credentials|secrets\.)' 2>/dev/null
```
Also scan `.env.example` and any committed config for values that look like real secrets (hex strings ≥32 chars, `sk_live_`, `AKIA`, `ghp_`, `xoxb-`, JWTs). If any real secrets are committed: **STOP the entire skill** and report to the user. Do not proceed until they rotate and remove.

**Repo origin hint:**
```bash
git config --get user.name && git config --get user.email && gh api user --jq .login 2>/dev/null
gh api user/orgs --jq '.[].login' 2>/dev/null
```

Capture both the personal login AND every org the user belongs to — these become the pick-list options in Question 6.

Store everything detected as a **repo-manifest** you'll reference through the rest of the skill.

## Phase 3: Propose & Confirm

Print a short summary of what was detected (3-5 bullets max) and the draft plan. Example:

```
Detected: Node 20 / Fastify + React / Postgres / Docker
Existing: README.md (basic), .gitignore, .env.example
Missing:  LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, .github/
Secrets:  clean ✓
```

Then ask **only** the questions that can't be inferred. Use `AskUserQuestion` with multiple-choice where possible.

**Question 1 — License:** MIT (most permissive, default for open source) | Apache-2.0 (permissive + patent grant) | AGPL-3.0 (copyleft, network use triggers) | Proprietary/None (no LICENSE file) | Other (user specifies)

**Question 2 — Destination:** Where does this repo live?
- **Public GitHub** — `gh repo create --public`
- **Private GitHub** — `gh repo create --private`
- **Personal (Unraid self-hosted)** — bare git over SSH on Jason's Unraid box (`root@192.168.2.222`, LAN-only), repos under `/mnt/user/backups/git/`. No GitHub involved.

Only offer the Unraid option when `git config user.email` is one of Jason's (`jnew00@gmail.com` / `dollarbone@gmail.com`); otherwise show just Public / Private.

The destination changes the rest of the flow. When **Unraid** is chosen, the repo has no GitHub Actions runner and no GitHub UI, so **skip** Question 6 (repo owner), Question 7 (CI starter), Question 8 (GitGuardian), and artifacts 4h (CI workflow) and 4l (gitleaks CI). Everything else — README, LICENSE, local gitleaks hook (4k), etc. — still applies. Phase 6 prints the bare-SSH setup instead of `gh repo create`.

**Question 3 — Accept contributions?** (gates CONTRIBUTING.md + templates): Yes (include CONTRIBUTING.md, issue templates, PR template) | No (skip contribution scaffolding)

**Question 4 — Repo description:** Draft a one-line description (≤350 chars, GitHub's limit) from the scan. Present it and offer: use as-is | edit it (user provides text) | generate 3 alternatives to choose from

**Question 5 — Logo / banner:** Already have one (provide path) | Generate with nano-banana | Skip

**Question 6 — Repo owner:** *(GitHub destinations only — skip for Unraid.)*
Build `AskUserQuestion` options from the origin-hint scan — the personal login plus each org, one option each. Always a pick-list, never free text: hand-typed org slugs are the #1 cause of `CreateRepository` errors, and the failure surfaces as an unrelated-looking GraphQL permissions denial.

If the user has zero orgs, skip the question and default silently to the personal login. If they have exactly one org AND it matches a signal in the repo (README mentions it, existing remotes, package.json author field), surface that org as the Recommended option; otherwise list personal first.

The repo name defaults to the directory basename — confirm or override as a separate (simpler) question.

**Question 7 — CI starter?** *(GitHub destinations only — skip for Unraid, which has no Actions runner.)* Only ask if no `.github/workflows/` exists AND the project has a detectable test command: Yes (basic CI workflow — test + build on PR) | No

**Question 8 — GitGuardian cloud scanning?** *(GitHub destinations only — skip for Unraid.)* Optional; gitleaks hook + CI are installed automatically either way: Yes (print enrollment instructions in Phase 6) | No (gitleaks alone is enough for solo/small projects)

## Phase 4: Generate Artifacts

Write files only for what's missing or was approved to replace. Never overwrite an existing file without explicit confirmation.

### 4a. LICENSE

Fetch the SPDX-standard text for the chosen license. For MIT/Apache-2.0/AGPL-3.0, use the canonical template with `{year}` and `{copyright holder}` filled from `git config user.name` (confirm with user if ambiguous).

### 4b. README.md

If a README exists, **enhance it** rather than replacing. Check for and add any missing sections: logo/banner at top (if generated or provided), badges row (license, CI status placeholder, version if in package.json), one-line description (from Phase 3), Quickstart/Install, Usage, Configuration/Environment Variables, API (if server project), Contributing (link to CONTRIBUTING.md), License.

If no README exists, generate from the repo-manifest with all standard sections.

**Section header icons:** default to none. If the existing README uses emoji headers OR the user asks for icons, read `references/readme-icons.md` and follow it.

### 4c. CONTRIBUTING.md (if accepting contributions)

Standard sections: Code of Conduct link, Development setup, Running tests, Commit style, PR process, Issue reporting.

In the "Development setup" section, include a one-time hook activation step so contributors pick up the gitleaks pre-commit hook installed in 4k:

```bash
# After cloning, activate versioned git hooks (runs gitleaks on every commit).
git config core.hooksPath .githooks
```

If no CONTRIBUTING.md is being written (contributions = No), add the same block to the README's "Development" or "Contributing" section instead — the hook is still installed either way.

### 4d. CODE_OF_CONDUCT.md (if accepting contributions)

**Do NOT vendor the full Contributor Covenant text** — its verbatim harassment-category enumerations trip the output content filter mid-generation and halt the skill. Adopt by reference instead (the React/Kubernetes/Rust convention): copy `assets/code-of-conduct.md` to `CODE_OF_CONDUCT.md`, substituting `{email}` (maintainer email from `git config user.email`, confirm if ambiguous) and `{covenant-url}` (`https://www.contributor-covenant.org/version/2/1/code_of_conduct/`).

If the user specifically requests the full vendored text, generate it with a warning that the request may fail and need a retry.

### 4e. SECURITY.md

Template with a vuln-reporting email or link. Ask for the reporting channel if not inferable.

### 4f. CHANGELOG.md

Seed with Keep-a-Changelog format:
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

`.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`, `.github/PULL_REQUEST_TEMPLATE.md`

### 4h. CI workflow (if approved)

Detect test runner from package.json / pyproject / etc. Write `.github/workflows/ci.yml` with lint + test + build on PR and main push. Keep it minimal — user can expand later.

### 4i. .gitignore sanity

Check the existing `.gitignore` for common omissions given the detected stack (e.g., `node_modules`, `dist`, `.env`, `__pycache__`, `target/`, `.DS_Store`). Append missing entries with a comment block header `# Added by repo-ready`.

### 4j. Logo (if requested)

**Use Skill tool:** `nano-banana` with args describing the project, `--transparent` flag. Save into the target repo at `./assets/logo.png` or `./.github/logo.png` (the project's directories, not this skill's `assets/`). Reference from README.

### 4k. Secret-scanning hook (always install)

Defense-in-depth. Phase 2's scan catches what's *already* committed; this hook prevents *future* leaks. Always install — no question needed. The CONTRIBUTING.md step (4c) tells contributors to activate it once per clone.

Copy `assets/pre-commit` to `.githooks/pre-commit` and `chmod +x` it. Copy `assets/gitleaks.toml` to `.gitleaks.toml` at the repo root. Both are generic — no substitutions needed; custom `[[rules]]` for new providers get appended later per the comments in the file.

**Do NOT run `git config core.hooksPath .githooks` on behalf of the user.** It's a per-clone setting stored in `.git/config`, not versioned. The CONTRIBUTING.md / README setup step handles this for contributors.

### 4l. Secret-scanning CI (backstop)

Whenever any `.github/workflows/` directory is being created, copy `assets/gitleaks-workflow.yml` to `.github/workflows/gitleaks.yml` (no substitutions). This catches contributors who bypassed the local hook (`--no-verify`) or never ran the `hooksPath` setup. It installs the MIT-licensed gitleaks CLI directly — do not swap in `gitleaks/gitleaks-action@v2`, which now requires a paid `GITLEAKS_LICENSE` for all org repos.

### 4m. Register with TARS (optional)

If `~/.tars/tars.db` exists, read `references/tars-registration.md` and follow it. If not, skip silently.

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

## Phase 6: Print Destination Setup Command

**Do NOT execute.** Print shared-state commands (`gh repo create`, `git init --bare`, `git push`, GitGuardian enrollment) for the user to review and run themselves — this skill only writes local files (plus the local-only TARS row in 4m) and never commits. If the user asks to commit + push after review, they do it themselves or invoke `/acp`.

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

If topics were inferred from the stack (e.g., `react`, `fastify`, `postgres`, `docker`), suggest a follow-up:

```bash
gh repo edit <owner>/<name> --add-topic <t1>,<t2>,<t3>
```

### Unraid destination (personal self-hosted)

Bare git over SSH on the Unraid box `192.168.2.222` (LAN-only), as **root**. Repos live under `/mnt/user/backups/git/` — the same convention as the existing `memex.git`. The remote repo doesn't exist yet, so the first command initializes it on the box, then wires the remote and pushes. Substitute `<name>`.

```bash
# 1. Create the bare repo on the box (idempotent — safe to re-run)
ssh root@192.168.2.222 'git init --bare /mnt/user/backups/git/<name>.git'

# 2. Wire origin and push
git remote add origin ssh://root@192.168.2.222/mnt/user/backups/git/<name>.git
git branch -M main
git push -u origin main
```

**If Question 8 was answered Yes (GitGuardian)** (GitHub destinations only), append:

```
GitGuardian enrollment (optional cloud scanning):
  1. Sign up at https://dashboard.gitguardian.com/auth/signup
  2. VCS Integrations → GitHub → connect your account (or org)
  3. Enable monitoring on <owner>/<name> after the repo is created
  4. (Optional) Install the GitGuardian GitHub App for PR-level inline comments

Free tier covers public repos and private repos with ≤25 developers.
Complements gitleaks — same detection philosophy, adds cloud history + alerts.
```

End with: "Review the artifacts, then run the commands above when you're ready."

## Principles

- **Inferred-first, ask-second.** Every question must be one the repo can't answer.
- **Match the project's voice.** If the existing README is terse, stay terse. If it has ASCII diagrams and personality, match that energy.
